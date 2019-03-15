using Statistics
using GroupSummaries
using GroupSummaries: summaries, locreg
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
summaries(locreg, data, across)
