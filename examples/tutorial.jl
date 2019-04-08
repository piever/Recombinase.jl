using Statistics, StatsBase, StatsPlots, JuliaDB
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_error, discrete, density, hazard, cumulative, prediction

data = loadtable(joinpath(datafolder, "school.csv"))

args, kwargs = series2D(
    data,
    Group(:Sx),
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(:Sx),
    across = :School,
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(:Sx),
    across = :School,
    select = (:MAch, :SSS),
    summarize = median
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(color = :Sx, markershape = :Sector),
    across = :School,
    select = (:MAch, :SSS),
    summarize = median
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(:Sx),
    across = :School,
    select = (:MAch, :SSS),
    summarize = median,
    color = [:red, :blue]
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(:Sx),
    across = :School,
    select = (:MAch, :SSS),
    summarize = median,
    )
scatter(args...; legend = :topleft, markersize = 10, kwargs...)

args, kwargs = series2D(
    cumulative,
    data,
    Group(:Sx),
    across = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :topleft)

args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    across = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :bottom)

args, kwargs = series2D(
    discrete(prediction),
    data,
    Group(color = :Minrty),
    select = (:Sx, :MAch),
    summarize = (mean, sem),
)
groupedbar(args...; kwargs...)

##

using Interact, StatsPlots, Blink

using Recombinase
ui = Recombinase.gui(data, [plot, scatter, groupedbar]);
w = Window()
body!(w, ui)
