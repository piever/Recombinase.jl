using Statistics, StatsBase
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_error, discrete, distribution, hazard, prediction
using JuliaDB

data = loadtable(joinpath(datafolder, "school.csv"))
t = columns(data)

res = compute_error(t.School, t.SSS, t.CSES, summarize=(median, std))

compute_error(distribution, t.School, t.MAch)

compute_error(discrete(distribution), t.School, rand(1:100, length(t.School)))

compute_error(hazard, t.School, t.MAch)

compute_error(prediction, t.School, t.MAch, t.SSS)

using Plots

args, kwargs = series2D(
    prediction,
    data,
    Group((:Sx, :Sector)),
    across = :School,
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
    across = :School,
    ribbon = true
)
plot(args...; kwargs...)

args, kwargs = series2D(
    data,
    Group(color = :Sx, color = :Sx),
    across = :School,
    select = (:MAch, :SSS),
)
scatter(args...; kwargs...)
