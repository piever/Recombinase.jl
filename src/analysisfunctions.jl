struct Analysis{S, F, NT<:NamedTuple}
    f::F
    kwargs::NT
    Analysis{S}(f::F, kwargs::NT) where {S, F, NT<:NamedTuple} =
        new{S, F, NT}(f, kwargs)
end

Analysis{S}(f; kwargs...) where {S} = Analysis{S}(f, values(kwargs))
Analysis{S}(a::Analysis; kwargs...) where {S} = Analysis{S}(a.f, merge(a.kwargs, values(kwargs)))
Analysis(args...; kwargs...) = Analysis{:automatic}(args...; kwargs...)

getfunction(funcs, S) = funcs
getfunction(funcs::NamedTuple, S::Symbol) = getfield(funcs, S)
getfunction(a::Analysis{S}) where {S} = getfunction(a.f, S)

(a::Analysis{S})(; kwargs...) where {S} = Analysis{S}(a; kwargs...)
(a::Analysis{S})(args...) where {S} = getfunction(a)(args...; a.kwargs...)
(a::Analysis{:automatic})(args...) = (infer_axis(args...)(a))(args...)

discrete(a::Analysis) = Analysis{:discrete}(a.f, a.kwargs)
continuous(a::Analysis) = Analysis{:continuous}(a.f, a.kwargs)
vectorial(a::Analysis) = Analysis{:vectorial}(a.f, a.kwargs)
discrete(::Nothing) = nothing
continuous(::Nothing) = nothing
vectorial(::Nothing) = nothing

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
    a_inf = infer_axis(args...)(a)
    compute_axis(a_inf, args...)
end

continuous_axis(x, args...; npoints = 100) = range(extrema(x)...; length = npoints)

function compute_axis(a::Analysis{:continuous}, args...)
    set(a, :axis) do
        npoints = get(a, :npoints, 100)
        continuous_axis(args..., npoints = npoints)
    end
end

discrete_axis(x, args...) = unique(sort(x))

function compute_axis(a::Analysis{:discrete}, args...)
    set(a, :axis) do
        discrete_axis(args...)
    end
end

vectorial_axis(x, args...) = axes(x, 1)

function compute_axis(a::Analysis{:vectorial}, args...)
    set(a, :axis) do
        vectorial_axis(args...)
    end
end

_first(t) = t
_first(t::Union{Tuple, NamedTuple}) = first(t)

function fititer!(axis, summaries, iter)
    lo, hi = extrema(axes(axis, 1))
    for (key, val) in iter
        ind = searchsortedfirst(axis, key, lo, hi, Base.Order.Forward)
        lo = ind + 1
        ind > hi && break
        fit!(summaries[ind], _first(val))
    end
end

has_error(a::Analysis) = has_error(getfunction(a))
has_error(f) = false

function _expectedvalue(x, y; axis = nothing, min_nobs = 2, kwargs...)
    itr = finduniquesorted(x)
    key_stat = ((key, fit!(Summary(; kwargs...), view(y, idxs))) for (key, idxs) in itr)
    return ((key, stat[]) for (key, stat) in key_stat if nobs(stat) >= min_nobs)
end

has_error(::typeof(_expectedvalue)) = true

function _localregression(x, y; npoints = 100, axis = continuous_axis(x, y; npoints = npoints), kwargs...)
    min, max = extrema(x)
    model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
    return ((val, predict(model, val)) for (ind, val) in enumerate(axis) if min < val < max)
end

function _alignedsummary(xs, ys; axis = vectorial_axis(xs, ys), min_nobs = 2, kwargs...)
    iter = (view(y, x) for (x, y) in zip(xs, ys))
    stats = OffsetArray([Summary(; kwargs...) for _ in axis], axis)
    fitvecmany!(stats, iter)
    ((val, stat[]) for (val, stat) in zip(axis, stats) if nobs(val) >= min_nobs)
end

has_error(::typeof(_alignedsummary)) = true

const prediction = Analysis((continuous = _localregression, discrete = _expectedvalue, vectorial = _alignedsummary))

function _density(x; npoints = 100, axis = continuous_axis(x, npoints = npoints), kwargs...)
    d = InterpKDE(kde(x; kwargs...))
    return ((val, pdf(d, val)) for val in axis)
end

function _frequency(x; axis = discrete_axis(x), npoints = 100)
    c = countmap(x)
    s = sum(values(c))
    return ((val, get(c, val, 0)/s) for val in axis)
end

const density = Analysis((continuous = _density, discrete = _frequency))

function _cumulative(x; npoints = 100, axis = continuous_axis(x, npoints = npoints), kwargs...)
    func = ecdf(x)
    return ((val, func(val)) for val in axis)
end

function _cumulative_frequency(x; axis = discrete_axis(x, npoints = npoints), kwargs...)
    func = ecdf(x)
    return ((val, func(val)) for val in axis)
end

const cumulative = Analysis((continuous = _cumulative, discrete = _cumulative_frequency))

function _hazard(t; npoints = 100, axis = continuous_axis(x, npoints = npoints), kwargs...)
    pdf_iter = _density(t; axis = axis, kwargs...)
    cdf_func = ecdf(t)
    ((val, pdf / (1 + step(axis) * pdf - cdf_func(val))) for (val, pdf) in pdf_iter)
end

function _hazard_frequency(t; axis = discrete_axis(x), kwargs...)
    pdf_iter = _frequency(t; axis = axis, kwargs...)
    cdf_func = ecdf(t)
    ((val, pdf / (1 + pdf - cdf_func(val))) for (val, pdf) in pdf_iter)
end

const hazard = Analysis((continuous = _hazard, discrete = _hazard_frequency))
