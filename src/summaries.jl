splitapply(f, across::AbstractVector, cols::AbstractVector...; kwargs...) = splitapply(f, across, cols; kwargs...)

function splitapply(f, across::AbstractVector, cols::Tuple; perm = sortperm(across))
    itr = finduniquesorted(across, perm)
    data = StructVector(cols)
    return collect_columns_flattened(key => f(tupleofarrays(data[idxs])...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tuple, val) = map(t -> t(val), f)

summaries(across::AbstractVector, cols::AbstractVector...; kwargs...) = summaries(across, cols; kwargs...)

function summaries(across::AbstractVector, cols::Tuple; perm = sortperm(across), filter = isfinite, summarize = mean)
    itr = finduniquesorted(across, perm)
    collect_columns(key => map(col -> apply(summarize, Base.filter(filter, view(col, idxs))), cols) for (key, idxs) in itr)
end

summaries(f::FunctionOrAnalysis, across::AbstractVector, cols::AbstractVector...; kwargs...) = summaries(f, across, cols; kwargs...)

function summaries(f::FunctionOrAnalysis, across::AbstractVector, cols::Tuple; perm = sortperm(across), kwargs...)
    a = compute_axis(f, cols...)
    res = splitapply(a, across, cols; perm = perm)
    summary = res.second
    summaries(tupleofarrays(summary)...; kwargs...)
end

tupleofarrays(s::Union{Tuple, NamedTuple}) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))
