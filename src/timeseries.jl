using OnlineStatsBase: fit!, FTSeries, nobs, value
using OffsetArrays: OffsetArray

isfinitevalue(::Missing) = false
isfinitevalue(x::Number) = isfinite(x)

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

trimmedoffset(v, shift) = OffsetArray(v, _padded_tuple((args...) -> 0, v, shift))
function trimmedoffset(v, shift, range)
    TrimmedView(trimmedoffset(v, shift), range)
end

for (offset, view) in zip([:offsetview, :offsetslice], [:view, :getindex])
    @eval function $offset(v, shift, range = axes(v))
        shifts = _padded_tuple((args...) -> 0, v, shift)
        shiftedaxes = ntuple(i -> axes(v, i) .- shifts[i], length(shifts))
        ranges = _padded_tuple((v, i) -> shiftedaxes[i], v, range)
        trimmedranges = map(intersect, shiftedaxes, ranges)
        sub = $view(v, (a .+ b for (a, b) in zip(shifts, trimmedranges))...)
        OffsetArray(sub, shifts)
    end
end

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
