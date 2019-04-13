const Tup = Union{Tuple, NamedTuple}

_default_confidence(nobs, mean, var) = sqrt(var / nobs)
_mean_trend(confidence, res) = _mean_trend(confidence, nobs(res), value(res)...)
_mean_trend(confidence, nobs, arg) = (arg,)
_mean_trend(confidence, nobs, arg, args...) = (arg, confidence(nobs, arg, args...))

apply(f, val) = f(val)
apply(f::Tup, val) = map(t -> t(val), f)
apply(f::Analysis, cols::Tup) = compute_axis(f, cols...)(cols)
apply(f::Analysis, t::IndexedTable; select = cols) = apply(f, columntuple(t, cols))

struct Summary{S, C}
    series::S
    confidence::C
end

function Summary(; transform = identity, filter = isfinitevalue,
    confidence = _default_confidence, estimator = (Mean, Variance))
    return Summary(FTSeries((stat() for stat in to_tuple(estimator))...;
        filter = filter, transform = transform), confidence)
end

fit!(s::Summary, vec) = (fit!(s.series, vec); s)
nobs(s::Summary) = nobs(s.series)
Base.getindex(s::Summary) = _mean_trend(s.confidence, s.series)

compute_summary(keys::AbstractVector, cols::AbstractVector; kwargs...) = compute_summary(keys, (cols,); kwargs...)
function compute_summary(keys::AbstractVector, cols::Tup; perm = sortperm(keys), min_nobs = 2, kwargs...)
    iter = (key => map(col -> fit!(Summary(; kwargs...), view(col, idxs)), cols) for (key, idxs) in finduniquesorted(keys, perm))
    collect_columns(key => map(getindex, vals) for (key, vals) in iter if all(t -> nobs(t) >= min_nobs, vals))
end

compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::AbstractVector; kwargs...) =
    compute_summary(f, keys, (cols,); kwargs...)

function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup; min_nobs = 2, perm = sortperm(keys),
    kwargs...)

    analysis = compute_axis(f, cols...)
    axis = get_axis(analysis)
    summaries = [Summary(; kwargs...) for _ in axis]
    data = StructVector(cols)
    _compute_summary!(analysis, keys, perm, data, summaries)
    summary = collect_columns(s[] for s in summaries)
    mask = findall(t -> nobs(t) >= min_nobs, summaries)
    return StructArray(axis[mask] => StructArray((summary[mask],)))
end

function _compute_summary!(analysis, keys, perm, data, summaries)
    for (_, idxs) in finduniquesorted(keys, perm)
        res = analysis(tupleofarrays(data[idxs])...)
        foreach(fit!, summaries, res)
    end
end

compute_summary(::Nothing, args...; kwargs...) = compute_summary(args...; kwargs...)

function compute_summary(t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(keys, columntuple(t, select); perm=perm, kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(f, keys, columntuple(t, select); perm=perm, kwargs...)
end

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v) = (v,)
columntuple(t, cols) = to_tuple(columns(t, cols))
columntuple(t) = to_tuple(columns(t))
