using Statistics
using StatsBase
using GroupSummaries
using GroupSummaries: summaries
using Test
using RDatasets
using IndexedTables

school = table(RDatasets.dataset("mlmRev","Hsb82"))
t = setcol(school, :x => rand(1:100, length(school)))

data = rows(t, (:MAch, :SSS))
across = rows(t, :School)
summaries(data, across, mean)

data = rows(t, (:MAch, :SSS))
across = rows(t, :School)
summaries(GroupSummaries.density, data, across, (mean, sem))

data = rows(t, (:x,))
across = rows(t, :School)
summaries(GroupSummaries.frequency, data, across, (mean, sem))

data = rows(t, (:MAch, :SSS))
across = rows(t, :School)
summaries(GroupSummaries.hazard, data, across, (mean, sem))

data = rows(t, (:MAch, :SSS))
across = rows(t, :School)
summaries(GroupSummaries.localregression, data, across)
