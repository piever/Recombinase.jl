using Statistics, StatsBase
using StructArrays
using GroupSummaries
using GroupSummaries: compute_error
using Test
using IndexedTables
using ShiftedArrays, OnlineStatsBase

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
    @test columns(res.second, 1) ≈ [1, 1, 1]./3
end

@testset "timeseries" begin
    v1 = rand(1000) # day 1
    v2 = rand(50) # day 2
    traces = [v1, v1, v1, v2, v2, v2]
    ts = [10, 501, 733, 1, 20, 30]
    stats = (mean = Mean, variance = Variance)
    s = GroupSummaries.fitvec(stats, (lead(trace, t) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3].value isa NamedTuple{(:mean, :variance)}
end
