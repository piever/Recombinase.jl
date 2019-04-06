using OnlineStatsBase: fit!, FTSeries, nobs, value
using OffsetArrays: OffsetArray

isfinitevalue(::Missing) = false
isfinitevalue(x::Number) = isfinite(x)

function initstats(series, ranges; filter = isfinitevalue, transform = identity)
    series = to_tuple(series)
    ranges = to_tuple(ranges)
    itr = Iterators.product(ranges...)
    vec = [FTSeries((stat() for stat in series)...;
            filter = filter, transform = identity) for _ in itr]
    return OffsetArray(vec, ranges)
end

function fitvec!(m, val)
    for i in eachindex(m)
        if checkbounds(Bool, val, i)
            @inbounds fit!(m[i], val[i])
        end
    end
    return m
end

function fitvecmany!(m, iter)
    for el in iter
        fitvec!(m, el)
    end
    return m
end

addname(series, v) = v
addname(series::NamedTuple{T}, v) where {T} = NamedTuple{T}(v)

function fitvec(series, iter, ranges=nothing; kwargs...)
    start = iterate(iter)
    start === nothing && error("Nothing to fit!")
    val, state = start
    init = initstats(series, something(ranges, axes(val)); kwargs...)
    fitvecmany!(init, Iterators.rest(iter, state))
    StructArray(((nobs = nobs(el), value = addname(series, value(el))) for el in init);
        unwrap = t -> t <: Union{Tuple, NamedTuple})
end
