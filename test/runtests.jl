using Statistics, StatsBase
using StructArrays
using Recombinase
using Recombinase: compute_summary, fitvec, aroundindex, discrete,
    prediction, density
using Test
using IndexedTables
using OnlineStatsBase

@testset "discrete" begin
    x = [1, 2, 3, 1, 2, 3]
    y = [0.3, 0.1, 0.3, 0.4, 0.2, 0.1]
    across = [1, 1, 1, 2, 2, 2]
    res = compute_summary(
        discrete(prediction),
        across,
        (x, y),
        estimator = Mean
    )
    @test res.first == [1, 2, 3]
    @test columns(res.second, 1) ≈ [0.35, 0.15, 0.2]
    res = compute_summary(
        discrete(density),
        across,
        (x,),
        estimator = Mean
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
    s = fitvec(stats, (aroundindex(trace, t) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3] isa NamedTuple{(:nobs, :mean, :variance)}
    s = fitvec(stats, (aroundindex(trace, t, -3:3) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3] isa NamedTuple{(:nobs, :mean, :variance)}
    @test s[-4].nobs == 0

    stats = Mean
    s = fitvec(stats, (aroundindex(trace, t) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3].Mean isa Float64
end
