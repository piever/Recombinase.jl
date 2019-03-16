using Statistics, StatsBase
using GroupSummaries: compute_error, density, frequency, hazard, localregression
using RDatasets

t = RDatasets.dataset("mlmRev","Hsb82")

compute_error(t.School, t.MAch, t.SSS)

compute_error(density, t.School, t.MAch)

compute_error(frequency, t.School, rand(1:100, length(t.School)))

compute_error(hazard, t.School, t.MAch)

compute_error(localregression, t.School, t.MAch, t.SSS)
