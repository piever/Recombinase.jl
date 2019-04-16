using OffsetArrays: OffsetArray

_padded_tuple(default, v::AbstractArray{T, N}, n::NTuple{N, Any}) where {T, N} = n
_padded_tuple(default, v::AbstractArray{T, N}, n::Any) where {T, N} = _padded_tuple(default, v, (n,))
_padded_tuple(default, v::AbstractArray{T, N}, n::Tuple) where {T, N} = Tuple(i <= length(n) ? n[i] : default(v, i) for i in 1:N)

to_indexarray(t::Tuple{AbstractArray}) = t[1]
to_indexarray(t::Tuple{AbstractArray, Vararg{AbstractArray}}) = CartesianIndices(t)

function offsetrange(v, offset, range = axes(v))
    padded_offset = _padded_tuple((args...) -> 0, v, offset)
    padded_range = _padded_tuple(axes, v, range)
    rel_offset = map(axes(v), padded_offset, padded_range) do ax, off, r
        - off + first(r) - first(ax)
    end
    OffsetArray(to_indexarray(padded_range), rel_offset)
end

aroundindex(v, args...) = view(v, offsetrange(v, args...))

function initstats(stat, ranges)
    ranges = to_tuple(ranges)
    itr = Iterators.product(ranges...)
    vec = [copy(stat) for _ in itr]
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

function fitvec(stat::OnlineStat, iter, ranges=(); kwargs...)
    start = iterate(iter)
    start === nothing && error("Nothing to fit!")
    val, state = start
    init = initstats(stat, _padded_tuple(axes, val, ranges))
    fitvecmany!(init, Iterators.rest(iter, state))
    StructArray(((nobs = nobs(el), value = value(el)) for el in init);
        unwrap = t -> t <: Union{Tuple, NamedTuple})
end
