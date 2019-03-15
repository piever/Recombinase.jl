function splitapply(f, data, across::AbstractVector, args...; perm)
    itr = finduniquesorted(across, perm)
    return collect_columns_flattened(key => f(data[idxs], args...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tuple, val) = map(t -> t(val), f)

function getfunc(funcs::NTuple{N, Any}, i) where {N}
    N ==0 && return mean
    N < i && return last(funcs)
    return funcs[i]
end

function summaries(data, across, funcs...; perm = sortperm(across))
    itr = finduniquesorted(across, perm)
    cols = tupleofarrays(data)
    n = length(cols)
    nf = length(funcs)
    collect_columns(key => ntuple(i -> apply(getfunc(funcs, i), cols[i][idxs]), n) for (key, idxs) in itr)
end

function summaries(f::Function, data, across, funcs...; perm = sortperm(across), axis = :continuous)
    xaxis = compute_axis(tupleofarrays(data)[1], axis)
    res = splitapply(f, data, across, xaxis; perm = perm)
    summary = res.second
    summarydata = tupleofarrays(summary)[2:end]
    summaryacross = tupleofarrays(summary)[1]
    summaries(summarydata, summaryacross, funcs...)
end

function compute_axis(x, axis::Symbol)
    if axis == :auto
        axis = ifelse(eltype(x) <: Union{Missing, Number}, :continuous, :discrete)
    end
    axis == :continuous && return range(extrema(x)...; length = 100)
    axis == :discrete && return unique(x)
    error("Only :auto, :continuous and :discrete axis supported")
end

compute_axis(x, axis::AbstractVector) = axis

tupleofarrays(s::Union{Tuple, NamedTuple}) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))
