using Statistics, StatsBase
using StructArrays
using GroupSummaries
using GroupSummaries: summaries
using Test
using IndexedTables
using RDatasets

school = table(RDatasets.dataset("mlmRev","Hsb82"))

t = setcol(school, :x => rand(1:100, length(school)))

x, y = columns(t, (:MAch, :SSS))
across = column(t, :School)
summaries(across, x, y) 

data = column(t, :MAch)
across = column(t, :School)
summaries(GroupSummaries.density, across, data, summarize = (mean, sem))

data = column(t, :x)
across = column(t, :School)
summaries(GroupSummaries.frequency, across, data, summarize = (mean, sem))

data = column(t, :MAch)
across = column(t, :School)
summaries(GroupSummaries.hazard, across, data, summarize = (mean, sem))

x, y = columns(t, (:MAch, :SSS))
across = column(t, :School)
summaries(GroupSummaries.localregression, across, x, y)
