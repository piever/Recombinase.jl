function locreg(t, xaxis; estimator = mean)
    cols = fieldarrays(t)
    itr = finduniquesorted(cols[1])
    collect_columns((key, estimator(cols[2][idxs])) for (key, idxs) in itr)
end

function locreg(t, xaxis::AbstractRange; kwargs...)
    x, y = fieldarrays(t)
    within = filter(t -> minimum(x)<= t <= maximum(x), xaxis)
    if length(within) > 0
        model = loess(convert(Vector{Float64}, x), convert(Vector{Float64}, y); kwargs...)
        prediction = predict(model, within)
    else
        prediction = Float64[]
    end
    StructVector((within, prediction))
end
