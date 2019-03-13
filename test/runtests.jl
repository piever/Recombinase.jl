using GroupSummaries
using GroupSummaries: sac, _locreg
using Test
using RDatasets
using IndexedTables
school = table(RDatasets.dataset("mlmRev","Hsb82"))
t = setcol(school, :x => rand(1:100, length(school)))

@testset "GroupSummaries.jl" begin
    data = rows(t, (:x, :SSS))
    across = rows(t, :School)
    sac(_locreg, data, across, sortperm(across), mean)    
end
