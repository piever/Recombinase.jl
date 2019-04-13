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

has_estimator(a::Analysis) = has_estimator(getfunction(a))
has_estimator(f) = false

function _expectedvalue(x, y; axis, summaries, estimator = Mean)
    itr = finduniquesorted(x)
    lo, hi = extrema(axes(axis, 1))
    for (key, idxs) in itr
        result = apply(estimator, view(y, idxs))
        ind = searchsortedfirst(axis, key, lo, hi, Base.Order.Forward)
        lo = ind + 1
        ind > hi && break
        fit!(summaries[ind], result)
    end
    return
end

has_estimator(::typeof(_expectedvalue)) = true

function _localregression(x, y; axis, summaries, kwargs...)
    min, max = extrema(x)
    model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
    for (ind, val) in enumerate(axis)
        (min < val < max) && fit!(summaries[ind], predict(model, val))
    end
    return
end

function _alignedsummary(xs, ys; axis, summaries, estimator = Mean, kwargs...)
    iter = (view(y, x) for (x, y) in zip(xs, ys))
    sa = fitvec(estimator, iter, axis)
    full_data = last(fieldarrays(sa))
    mask = findall(t -> t >= min_nobs, first(fieldarrays(sa)))
    full_data[mask] = NaN
    return full_data
end

const prediction = Analysis((continuous = _localregression, discrete = _expectedvalue, vectorial = _alignedsummary))

function _density_function(x; kwargs...)
    d = InterpKDE(kde(x; kwargs...))
    t -> pdf(d, t)
end
function _density(x; axis, summaries, kwargs...)
    func = _density_function(x; kwargs...)
    foreach(summaries, axis) do stat, val
        fit!(stat, func(val))
    end
end

function _frequency_function(x)
    c = countmap(x)
    s = sum(values(c))
    val -> get(c, val, 0)/s
end

function _frequency(x; axis, summaries)
    func = _frequency_function(x)
    foreach(summaries, axis) do stat, val
        fit!(stat, func(val))
    end
end

const density = Analysis((continuous = _density, discrete = _frequency))

function _cumulative(x; axis, summaries, kwargs...)
    func = ecdf(x)
    foreach(summaries, axis) do stat, val
        fit!(stat, func(val))
    end
end

const cumulative = Analysis(_cumulative)

const hazardfunctions = map((continuous = _density_function, discrete = _frequency_function)) do _func
    function (t; axis, summaries, kwargs...)
        pdf_func = _func(t; kwargs...)
        cdf_func = ecdf(t)
        foreach(summaries, axis) do stat, val
            pdf = pdf_func(val)
            cdf = cdf_func(val)
            haz = pdf / (1 + step(axis) * pdf - cdf)
            fit!(stat, haz)
        end
    end
end

const hazard = Analysis(hazardfunctions)
