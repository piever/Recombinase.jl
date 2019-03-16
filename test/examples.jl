using Statistics, StatsBase
using GroupSummaries: summaries, density, frequency, hazard, localregression
using RDatasets

t = RDatasets.dataset("mlmRev","Hsb82")

summaries(t.School, t.MAch, t.SSS)

summaries(density, t.School, t.MAch, summarize = (mean, sem))

summaries(frequency, t.School, rand(1:100, length(t.School)), summarize = (mean, sem))

summaries(hazard, t.School, t.MAch, summarize = (mean, sem))

summaries(localregression, t.School, t.MAch, t.SSS)
