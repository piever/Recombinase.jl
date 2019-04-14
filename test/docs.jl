using Statistics, StatsBase, StatsPlots, JuliaDB
using OnlineStats
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_summary, discrete, density, hazard, cumulative, prediction

data = loadtable(joinpath(datafolder, "school.csv"))

##

args, kwargs = series2D(
    data,
    Group(:Sx),
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

##

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

##

args, kwargs = series2D(
    data,
    Group(color = :Sx, markershape = :Sector),
    error = :School,
    select = (:MAch, :SSS),
    estimator = Mean
    )
scatter(args...; kwargs...)

##

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    estimator = Mean,
    color = [:red, :blue]
    )
scatter(args...; kwargs...)

##

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    estimator = Mean
    )
scatter(args...; legend = :topleft, markersize = 10, kwargs...)

##

args, kwargs = series2D(
    cumulative,
    data,
    Group(:Sx),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :topleft)

##

args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :bottom)

##

args, kwargs = series2D(
    prediction,
    data,
    Group(color = :Minrty),
    select = (:Sx, :MAch),
)
groupedbar(args...; kwargs...)

##

using Recombinase, Interact, StatsPlots, Blink
# here we give the functions we want to use for plotting
ui = Recombinase.gui(data, [plot, scatter, groupedbar]);
w = Window()
body!(w, ui)
