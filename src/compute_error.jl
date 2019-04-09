const Tup = Union{Tuple, NamedTuple}

splitapply(f, keys::AbstractVector, cols::AbstractVector...; kwargs...) = splitapply(f, keys, cols; kwargs...)

function splitapply(f, keys::AbstractVector, cols::Tup; perm = sortperm(keys))
    itr = finduniquesorted(keys, perm)
    data = StructVector(cols)
    return collect_columns_flattened(key => f(tupleofarrays(data[idxs])...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tup, val) = map(t -> t(val), f)

compute_error(keys::AbstractVector, cols::AbstractVector...; kwargs...) = compute_error(keys, cols; kwargs...)

function compute_error(keys::AbstractVector, cols::Tup; perm = sortperm(keys), filter = isfinite, summarize = (mean, sem))
    itr = finduniquesorted(keys, perm)
    collect_columns(key => map(col -> apply(summarize, Base.filter(filter, view(col, idxs))), cols) for (key, idxs) in itr)
end

compute_error(t::IndexedTable, args...; kwargs...) = compute_error(nothing, t, args...; kwargs...)
compute_error(::Nothing, t::AbstractVector, args...; kwargs...) = compute_error(t, args...; kwargs...)

compute_error(f::FunctionOrAnalysis, keys::AbstractVector, cols::AbstractVector...; kwargs...) = compute_error(f, keys, cols; kwargs...)

function compute_error(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup; perm = sortperm(keys), kwargs...)
    a = compute_axis(f, cols...)
    res = splitapply(a, keys, cols; perm = perm)
    summary = res.second
    compute_error(tupleofarrays(summary)...; kwargs...)
end

function compute_error(f::Union{FunctionOrAnalysis, Nothing}, t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_error(f, keys, columntuple(t, select); perm=perm, kwargs...)
end

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v) = (v,)
columntuple(args...) = to_tuple(columns(args...))
