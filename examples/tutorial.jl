using Statistics, StatsBase
using GroupSummaries: Group, series2D, datafolder
using GroupSummaries: compute_error, density, frequency, hazard, localregression, cumulative, expectedvalue
using JuliaDB, StatsPlots

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
    summarize = mean
    )
scatter(args...; kwargs...)

args, kwargs = series2D(
    cumulative,
    data,
    Group((:Sx, :Sector)),
    across = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :bottomright)
    
args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    across = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs...)
    
args, kwargs = series2D(
    expectedvalue,
    data,
    Group(color = :Minrty),
    select = (:Sx, :MAch),
    summarize = (mean, sem),
    across = 1:length(data)
)
groupedbar(args...; kwargs...)

##
