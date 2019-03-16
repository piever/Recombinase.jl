using Statistics, StatsBase
using StructArrays
using GroupSummaries
using GroupSummaries: compute_error
using Test
using IndexedTables

@testset "discrete" begin
    x = [1, 2, 3, 1, 2, 3]
    y = [0.3, 0.1, 0.3, 0.4, 0.2, 0.1]
    across = [1, 1, 1, 2, 2, 2]
    res = compute_error(
        GroupSummaries.expectedvalue,
        across,
        x, y,
        summarize = mean
    )
    @test res.first == [1, 2, 3]
    @test columns(res.second, 1) ≈ [0.35, 0.15, 0.2]
    res = compute_error(
        GroupSummaries.frequency,
        across,
        x,
        summarize = mean
    )
    @test res.first == [1, 2, 3]
    @test columns(res.second, 1) ≈ [1, 1, 1]
end

