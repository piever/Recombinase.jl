function plot2D(s::StructVector{<:Pair}; ribbon = false)
    cols = fieldarrays(s.second)
    kwargs = Dict{Symbol, Any}()
    if length(cols) == 1
        x = s.first
        ycols = fieldarrays(cols[1])
        y = ycols[1]
        yerr = ifelse(ribbon, :ribbon, :yerr)
        length(ycols) == 2 && (kwargs[yerr] = ycols[2])
    else
        xcols, ycols = map(fieldarrays, cols)
        x, y = xcols[1], ycols[1]
        length(xcols) == 2 && (kwargs[:xerr] = xcols[2])
        length(ycols) == 2 && (kwargs[:yerr] = ycols[2])
    end
    return (x, y), kwargs
end

plot2D(args...; ribbon = false, kwargs...) =
    plot2D(compute_error(args...; kwargs...); ribbon = ribbon)
