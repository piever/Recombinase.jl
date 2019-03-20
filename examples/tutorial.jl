using Statistics, StatsBase
using GroupSummaries: Group, series2D, datafolder
using GroupSummaries: compute_error, density, frequency, hazard, localregression
using JuliaDB, Plots

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
