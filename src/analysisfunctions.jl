struct Analysis{S, F, NT<:NamedTuple}
    f::F
    kwargs::NT
    Analysis{S}(f::F, kwargs::NT) where {S, F, NT<:NamedTuple} =
        new{S, F, NT}(f, kwargs)
end

Analysis{S}(f; kwargs...) where {S} = Analysis{S}(f, values(kwargs))
Analysis{S}(a::Analysis; kwargs...) where {S} = Analysis{S}(a.f, merge(a.kwargs, values(kwargs)))
Analysis(args...; kwargs...) = Analysis{:auto}(args...; kwargs...)

getfunction(funcs, S) = funcs
getfunction(funcs::NamedTuple, S::Symbol) = getfield(funcs, S)
getfunction(a::Analysis{S}) where {S} = getfunction(a.f, S)

(a::Analysis{S})(; kwargs...) where {S} = Analysis{S}(a; kwargs...)
(a::Analysis{S})(args...) where {S} = getfunction(a)(args...; a.kwargs...)

discrete(a::Analysis) = Analysis{:discrete}(a.f, a.kwargs)
continuous(a::Analysis) = Analysis{:continuous}(a.f, a.kwargs)
discrete(::Nothing) = nothing
continuous(::Nothing) = nothing

Base.get(a::Analysis, s::Symbol, def) = get(a.kwargs, s, def)
Base.get(f::Function, a::Analysis, s::Symbol) = get(f, a.kwargs, s)
function set(f::Function, a::Analysis, s::Symbol)
    val = get(f, a, s)
    nt = NamedTuple{(s,)}((val,))
    a(; nt...)
end

const FunctionOrAnalysis = Union{Function, Analysis}

# TODO compute axis if called standalone!
compute_axis(f::Function, args...) = compute_axis(Analysis(f), args...)

infer_axis(x::AbstractVector{T}, args...) where {T<:Union{Missing, Number}} = Analysis{:continuous}
infer_axis(x::AbstractVector{T}, args...) where {T<:Union{Missing, AbstractArray}} = Analysis{:vectorial}
infer_axis(x::AbstractVector{Missing}, args...) = error("All data is missing")
infer_axis(x, args...) = Analysis{:discrete}

get_axis(s::Analysis) = s.kwargs.axis

function compute_axis(a::Analysis, args...)
    a_inf = infer_axis(args...)(a.f, a.kwargs)
    compute_axis(a_inf, args...)
end

function compute_axis(a::Analysis{:continuous}, args...)
    x = args[1]
    set(a, :axis) do
        npoints = get(a, :npoints, 100)
        range(extrema(x)...; length = npoints)
    end
end

function compute_axis(a::Analysis{:discrete}, args...)
    x = args[1]
    set(a, :axis) do
        unique(sort(x))
    end
end

function compute_axis(a::Analysis{:vectorial}, args...)
    x = args[1]
    set(a, :axis) do
        axes(x, 1)
    end
end

function fititer!(axis, summaries, iter)
    lo, hi = extrema(axes(axis, 1))
    for (key, val) in iter
        ind = searchsortedfirst(axis, key, lo, hi, Base.Order.Forward)
        lo = ind + 1
        ind > hi && break
        fit!(summaries[ind], val)
    end
end

has_error(a::Analysis) = has_error(getfunction(a))
has_error(f) = false

function _expectedvalue(x, y; axis, estimator = Mean)
    itr = finduniquesorted(x)
    return ((key, apply(estimator, view(y, idxs))) for (key, idxs) in itr)
end

has_error(::typeof(_expectedvalue)) = true

function _localregression(x, y; axis, kwargs...)
    min, max = extrema(x)
    model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
    return ((val, predict(model, val)) for (ind, val) in enumerate(axis) if min < val < max)
end

function _alignedsummary(xs, ys; axis, estimator = Mean, min_nobs = 1, kwargs...)
    iter = (view(y, x) for (x, y) in zip(xs, ys))
    stats = isnothing(estimator) ? OffsetArray(summaries, axis) : initstats(estimator, axis)
    fitvecmany!(stats, iter)
    if !isnothing(estimator)
        for (stat, summary) in zip(stats, summaries)
            nobs(stat) >= min_nobs && fit!(summary, value(stat)[1])
        end
    end
end

has_error(::typeof(_alignedsummary)) = true

const prediction = Analysis((continuous = _localregression, discrete = _expectedvalue, vectorial = _alignedsummary))

function _density(x; axis, kwargs...)
    d = InterpKDE(kde(x; kwargs...))
    return ((val, pdf(d, val)) for val in axis)
end

function _frequency(x; axis)
    c = countmap(x)
    s = sum(values(c))
    return ((val, get(c, val, 0)/s) for val in axis)
end

const density = Analysis((continuous = _density, discrete = _frequency))

function _cumulative(x; axis, kwargs...)
    func = ecdf(x)
    return ((val, func(val)) for val in axis)
end

const cumulative = Analysis(_cumulative)

const hazardfunctions = map(density.f) do pdf_func
    function (t; axis, kwargs...)
        pdf_iter = pdf_func(t; axis = axis, kwargs...)
        cdf_func = ecdf(t)
        return ((val, pdf / (1 + step(axis) * pdf - cdf_func(val))) for (val, pdf) in pdf_iter)
    end
end

const hazard = Analysis(hazardfunctions)
