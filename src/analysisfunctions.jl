struct Analysis{F, NT<:NamedTuple}
    f::F
    kwargs::NT
end

Analysis(f; kwargs...) = Analysis(f, values(kwargs))
Analysis(a::Analysis; kwargs...) = Analysis(a.f, merge(a.kwargs, values(kwargs)))
(a::Analysis)(; kwargs...) = Analysis(a; kwargs...)
(a::Analysis)(args...) = a.f(args...; a.kwargs...)

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

function compute_axis(f::Analysis, args...)
    x = args[1]
    set(f, :axis) do
        npoints = get(f, :npoints, 100)
        range(extrema(x)...; length = npoints)
    end
end

function _expectedvalue(x, y; axis, estimator = mean)
    itr = finduniquesorted(x)
    collect_columns((key, estimator(y[idxs])) for (key, idxs) in itr)
end

const expectedvalue = Analysis(_expectedvalue)
compute_axis(f::Analysis{typeof(_expectedvalue)}, x::AbstractVector) = set(() -> unique(x), f, :axis)

function _localregression(x, y; axis, kwargs...)
    within = filter(t -> minimum(x)<= t <= maximum(x), axis)
    if length(within) > 0
        model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
        prediction = predict(model, within)
    else
        prediction = Float64[]
    end
    StructVector((within, prediction))
end

const localregression = Analysis(_localregression)

function _density(x; axis, kwargs...)
    data = pdf(kde(x; kwargs...), axis)
    StructVector((axis, data))
end

const density = Analysis(_density)
function compute_axis(f::Analysis{typeof(_density)}, x::AbstractVector)
    set(f, :axis) do
        start, stop = extrema(kde(x).x)
        npoints = get(f, :npoints, 100)
        range(start, stop, length = npoints)
    end
end

function _frequency(x; axis)
    c = countmap(x)
    s = sum(values(c))
    StructVector((axis, [get(c, x, 0)/s for x in axis]))
end

const frequency = Analysis(_frequency)
compute_axis(f::Analysis{typeof(_frequency)}, x::AbstractVector) = set(() -> unique(x), f, :axis)

function _cumulative(x; axis, kwargs...)
    data = ecdf(x)(axis)
    StructVector((axis, data))
end

const cumulative = Analysis(_cumulative)

function _hazard(t; axis, kwargs...)
    pdf = density(; axis = axis, kwargs...)(t)
    cdf = cumulative(; axis = axis)(t)
    pdfs = tupleofarrays(pdf)[2]
    cdfs = tupleofarrays(cdf)[2]
    bs = step(axis)
    haz = @. pdfs/(1 + bs * pdfs - cdfs)
    StructVector((axis, haz))
end

const hazard = Analysis(_hazard)
