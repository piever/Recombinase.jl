const default_style_dict = Dict{Symbol, Any}(
    :color => ColorBrewer.palette("Set1", 8),
    :markershape => [:diamond, :circle, :triangle, :star5],
    :linestyle => [:solid, :dash, :dot, :dashdot],
    :linewidth => [1,4,2,3],
    :markersize => [3,9,5,7]
)

const style_dict = copy(default_style_dict)

function set_theme!(; kwargs...)
    empty!(style_dict)
    for (key, val) in default_style_dict
        style_dict[key] = val
    end
    for (key, val) in kwargs
        style_dict[key] = val
    end
end
