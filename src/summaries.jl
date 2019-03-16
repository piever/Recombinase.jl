function splitapply(f, across::AbstractVector, cols::AbstractVector...; perm = sortperm(across))
    itr = finduniquesorted(across, perm)
    data = StructVector(cols)
    return collect_columns_flattened(key => f(tupleofarrays(data[idxs])...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tuple, val) = map(t -> t(val), f)

function summaries(across, cols...;
                   perm = sortperm(across), filter = isfinite, summarize = mean)
    itr = finduniquesorted(across, perm)
    collect_columns(key => map(col -> apply(summarize, Base.filter(filter, view(col, idxs))), cols) for (key, idxs) in itr)
end

function summaries(f::FunctionOrAnalysis, across, cols...;
                   perm = sortperm(across), kwargs...)
    a = compute_axis(f, cols...)
    res = splitapply(a, across, cols...; perm = perm)
    summary = res.second
    summaries(tupleofarrays(summary)...; kwargs...)
end

tupleofarrays(s::Union{Tuple, NamedTuple}) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))
