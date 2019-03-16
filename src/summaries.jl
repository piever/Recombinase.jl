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

function summaries(data, across, funcs...; perm = sortperm(across), filter = isfinite)
    itr = finduniquesorted(across, perm)
    cols = tupleofarrays(data)
    n = length(cols)
    nf = length(funcs)
    collect_columns(key => ntuple(i -> apply(getfunc(funcs, i), Base.filter(filter, view(cols[i], idxs))), n) for (key, idxs) in itr)
end

function summaries(f::FunctionOrAnalysis, data, across, funcs...; perm = sortperm(across))
    a = compute_axis(f, tupleofarrays(data)[1])
    res = splitapply(a, data, across; perm = perm)
    summary = res.second
    summarydata = tupleofarrays(summary)[2:end]
    summaryacross = tupleofarrays(summary)[1]
    summaries(summarydata, summaryacross, funcs...)
end

tupleofarrays(s::Union{Tuple, NamedTuple}) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))
tupleofarrays(s::Vector) = (s,)
