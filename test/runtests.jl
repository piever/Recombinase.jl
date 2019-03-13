using GroupSummaries
using GroupSummaries: sac, _locreg
using Test
using RDatasets
using IndexedTables
school = setcol(table(RDatasets.dataset("mlmRev","Hsb82")), :x => rand(1:100, length(school)))

@testset "GroupSummaries.jl" begin
    data = rows(school, (:x, :SSS))
    across = rows(school, :School)
    sac(_locreg, data, across, sortperm(across), mean)    
end
