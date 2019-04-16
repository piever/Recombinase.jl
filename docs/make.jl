using Documenter, Literate
using Statistics, StatsBase, StatsPlots, JuliaDB
using OnlineStats
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_summary, discrete, density, hazard, cumulative, prediction

@info "makedocs"

Literate.markdown(
    joinpath(@__DIR__, "src", "tutorial.jl"),
    joinpath(@__DIR__, "src", "generated")
)

makedocs(
   format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
   sitename = "Recombinase.jl",
   pages = [
        "index.md",
        "generated/tutorial.md",
   ]
)

@info "deploydocs"
deploydocs(
    repo = "github.com/piever/Recombinase.jl.git",
)
