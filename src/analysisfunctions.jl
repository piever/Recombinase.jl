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

(a::Analysis{S})(; kwargs...) where {S} = Analysis{S}(a; kwargs...)
(a::Analysis{S})(args...) where {S} = getfunction(a.f, S)(args...; a.kwargs...)

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

function _expectedvalue(x, y; axis, estimator = mean)
    itr = finduniquesorted(x)
    results = fill(NaN, length(axis))
    lo, hi = extrema(axis)
    for (key, idxs) in itr
        result = estimator(view(y, idxs))
        ind = searchsortedfirst(axis, key, lo, hi, Base.Order.Forward)
        lo = ind + 1
        ind > hi && break
        @inbounds results[ind] = result
    end
    return results
end

function _localregression(x, y; axis, kwargs...)
    mask = findall(t -> minimum(x)<= t <= maximum(x), axis)
    within = axis[mask]
    prediction = fill(NaN, length(axis))
    if length(within) > 0
        model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
        prediction[mask] = predict(model, within)
    end
    prediction
end

function _alignedsummary(xs, ys; axis, min_nobs = 2, estimator = Mean, kwargs...)
    iter = (view(y, x) for (x, y) in zip(xs, ys))
    sa = fitvec(estimator, iter, axis)
    full_data = last(fieldarrays(sa))
    mask = findall(t -> t >= min_nobs, first(fieldarrays(sa)))
    full_data[mask] = NaN
    return full_data
end

const prediction = Analysis((continuous = _localregression, discrete = _expectedvalue, vectorial = _alignedsummary))

function _density(x; axis, kwargs...)
    return pdf(kde(x; kwargs...), axis)
end

function _frequency(x; axis)
    c = countmap(x)
    s = sum(values(c))
    [get(c, x, 0)/s for x in axis]
end

const density = Analysis((continuous = _density, discrete = _frequency))

function _cumulative(x; axis, kwargs...)
    ecdf(x)(axis)
end

const cumulative = Analysis(_cumulative)

const hazardfunctions = map(density.f) do _density
    function (t; axis, kwargs...)
        pdf = _density(t; axis = axis, kwargs...)
        cdf = _cumulative(t; axis = axis)
        bs = step(axis)
        return @. pdf/(1 + bs * pdf - cdf)
    end
end

const hazard = Analysis(hazardfunctions)
