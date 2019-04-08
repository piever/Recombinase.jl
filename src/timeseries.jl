using OnlineStatsBase: fit!, FTSeries, nobs, value
using OffsetArrays: OffsetArray

_padded_tuple(default, v::AbstractArray{T, N}, n::NTuple{N, Any}) where {T, N} = n
_padded_tuple(default, v::AbstractArray{T, N}, n::Any) where {T, N} = _padded_tuple(default, v, (n,))
_padded_tuple(default, v::AbstractArray{T, N}, n::Tuple) where {T, N} = Tuple(i <= length(n) ? n[i] : default(v, i) for i in 1:N)

struct TrimmedView{T, N, I, V<:AbstractArray}<:AbstractArray{T, N}
    parent::V
    trim::I
    function TrimmedView(v::AbstractArray{T, N}, trim::NTuple{N, AbstractUnitRange}) where {T, N}
        trimmed = map(intersect, axes(v), trim)
        new{T, N, typeof(trimmed), typeof(v)}(v, trimmed)
    end
end
function TrimmedView(v::AbstractArray{T, N}, trim) where {T, N}
    padded_trim::NTuple{N, AbstractUnitRange} = _padded_tuple(axes, v, trim)
    TrimmedView(v, padded_trim)
end

Base.parent(t::TrimmedView) = t.parent
Base.axes(t::TrimmedView) = t.trim
Base.size(t::TrimmedView) = map(length, axes(t))

@inline Base.@propagate_inbounds function Base.getindex(A::TrimmedView, I...)
    Base.@boundscheck checkbounds(A, I...)
    @inbounds ret = parent(A)[I...]
    ret
end

function aroundindex(v, shift)
    padded_shift = _padded_tuple((args...) -> 0, v, shift)
    OffsetArray(v, map(-, padded_shift))
end

aroundindex(v, shift, range) = TrimmedView(aroundindex(v, shift), range)

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

function fitvec!(m, val, shared_indices = eachindex(m, val))
    for cart in shared_indices
        @inbounds fit!(m[cart], val[cart])
    end
    return m
end

function fitvecmany!(m, iter)
    for el in iter
        am, ael = axes(m), axes(el)
        shared = (am == ael) ? eachindex(m, el) : CartesianIndices(map(intersect, am, ael))
        fitvec!(m, el, shared)
    end
    return m
end

addname(series::Tuple, v) = v
addname(series::NamedTuple{T}, v) where {T} = NamedTuple{T}(v)
addname(series::Any, v) = first(v)

function fitvec(series, iter, ranges=(); kwargs...)
    start = iterate(iter)
    start === nothing && error("Nothing to fit!")
    val, state = start
    init = initstats(series, _padded_tuple(axes, val, ranges); kwargs...)
    fitvecmany!(init, Iterators.rest(iter, state))
    StructArray(((nobs = nobs(el), value = addname(series, value(el))) for el in init);
        unwrap = t -> t <: Union{Tuple, NamedTuple})
end
