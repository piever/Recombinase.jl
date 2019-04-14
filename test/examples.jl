using Statistics, StatsBase
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_summary, discrete, density, hazard, prediction
using JuliaDB

data = loadtable(joinpath(datafolder, "school.csv"))
t = columns(data)

res = compute_summary(t.School, (t.SSS, t.CSES))
using Juno

args, kwargs = series2D(collect_columns(density(t.MAch)), ribbon = true)
plot(args...; kwargs...)
using IndexedTables
prediction(t.Sx, t.SSS) |> first
compute_summary(discrete(density), t.School, rand(1:100, length(t.School)))

compute_summary(hazard, t.School, t.MAch)

compute_summary(prediction, t.School, (t.MAch, t.SSS))

using Plots

args, kwargs = series2D(
    prediction,
    data,
    Group((:Sx, :Sector)),
    error = :School,
    select = (:MAch, :SSS),
    ribbon = true
)
plot(args...; kwargs...)

args, kwargs = series2D(
    prediction,
    data,
    Group(color = :Sx, linestyle = :Sector),
    color = [:red, :black],
    select = (:MAch, :SSS),
    error = :School,
    ribbon = true
)
plot(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    min_nobs = 2
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs...)

using StatsPlots
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
