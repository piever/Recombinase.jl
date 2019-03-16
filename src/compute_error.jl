const Tup = Union{Tuple, NamedTuple}

splitapply(f, across::AbstractVector, cols::AbstractVector...; kwargs...) = splitapply(f, across, cols; kwargs...)

function splitapply(f, across::AbstractVector, cols::Tup; perm = sortperm(across))
    itr = finduniquesorted(across, perm)
    data = StructVector(cols)
    return collect_columns_flattened(key => f(tupleofarrays(data[idxs])...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tup, val) = map(t -> t(val), f)

compute_error(across::AbstractVector, cols::AbstractVector...; kwargs...) = compute_error(across, cols; kwargs...)

function compute_error(across::AbstractVector, cols::Tup; perm = sortperm(across), filter = isfinite, summarize = (mean, sem))
    itr = finduniquesorted(across, perm)
    collect_columns(key => map(col -> apply(summarize, Base.filter(filter, view(col, idxs))), cols) for (key, idxs) in itr)
end

compute_error(::Nothing, t::IndexedTable; kwargs...) = compute_error(t; kwargs...)
compute_error(t::IndexedTable; across, select, kwargs...) =
    compute_error(rows(t, across), columntuple(t, select); perm=sortpermby(t, across), kwargs...)

compute_error(f::FunctionOrAnalysis, across::AbstractVector, cols::AbstractVector...; kwargs...) = compute_error(f, across, cols; kwargs...)

function compute_error(f::FunctionOrAnalysis, across::AbstractVector, cols::Tup; perm = sortperm(across), kwargs...)
    a = compute_axis(f, cols...)
    res = splitapply(a, across, cols; perm = perm)
    summary = res.second
    compute_error(tupleofarrays(summary)...; kwargs...)
end

compute_error(f::FunctionOrAnalysis, t::IndexedTable; across, select, kwargs...) =
    compute_error(f, rows(t, across), columntuple(t, select); perm=sortpermby(t, across), kwargs...)

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v::AbstractVector) = (v,)
columntuple(args...) = to_tuple(columns(args...))
