using Statistics, StatsBase
using StructArrays
using GroupSummaries
using GroupSummaries: summaries
using Test
using IndexedTables
using RDatasets

t = RDatasets.dataset("mlmRev","Hsb82")

summaries(t.School, t.MAch, t.SSS)

summaries(GroupSummaries.density, t.School, t.MAch, summarize = (mean, sem))

summaries(GroupSummaries.frequency, t.School, rand(1:100, length(t.School)), summarize = (mean, sem))

summaries(GroupSummaries.hazard, t.School, t.MAch, summarize = (mean, sem))

summaries(GroupSummaries.localregression, t.School, t.MAch, t.SSS)
