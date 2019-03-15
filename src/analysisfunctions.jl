function locreg(t, xaxis; estimator = mean)
    x, y = tupleofarrays(t)
    itr = finduniquesorted(x)
    collect_columns((key, estimator(y[idxs])) for (key, idxs) in itr)
end

function locreg(t, xaxis::AbstractRange; kwargs...)
    x, y = tupleofarrays(t)
    within = filter(t -> minimum(x)<= t <= maximum(x), xaxis)
    if length(within) > 0
        model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
        prediction = predict(model, within)
    else
        prediction = Float64[]
    end
    StructVector((within, prediction))
end

function density(t, xaxis::AbstractRange; kwargs...)
    x = tupleofarrays(t)[1]
    data = pdf(kde(x; kwargs...), xaxis)
    StructVector((xaxis, data))
end

function density(t, xaxis)
    x = tupleofarrays(s)[1]
    c = countmap(x) 
    StructVector((xaxis, [get(c, x, 0) for x in xaxis]))
end

function compute_axis(::typeof(density), x::AbstractVector{<:Union{Real, Missing}}; npoints = 100)
    start, stop = extrema(kde(x).x)
    range(start, stop, length = npoints)
end
compute_axis(::typeof(density), x::PooledVector; kwargs...) = compute_axis(x; kwargs...)

function cumulative(t, xaxis; kwargs...)
    x = tupleofarrays(t)[1]
    data = ecdf(x)(xaxis)
    StructVector((xaxis, data))
end

hazard(t, xaxis) = hazard(t, xaxis, 1)
hazard(t, xaxis::AbstractRange; kwargs...) = hazard(t, xaxis, step(xaxis); kwargs...)

function hazard(t, xaxis, step; kwargs...)
    pdf = density(t, xaxis; kwargs...)
    cdf = cumulative(t, xaxis)
    pdfs = tupleofarrays(pdf)[2]
    cdfs = tupleofarrays(cdf)[2]
    haz = @. pdfs/(1 + step * pdfs - cdfs)
    StructVector((xaxis, haz))
end
