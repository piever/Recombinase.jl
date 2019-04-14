const Tup = Union{Tuple, NamedTuple}

_default_confidence(nobs, mean, var) = sqrt(var / nobs)
_mean_trend(confidence, res) = _mean_trend(confidence, nobs(res), value(res)...)
_mean_trend(confidence, nobs, arg) = (arg,)
_mean_trend(confidence, nobs, arg, args...) = (arg, confidence(nobs, arg, args...))

apply(f, val) = f(val)
apply(::Nothing, val) = val
apply(f::Type, val) = value(fit!(f(), val))
apply(f::Tup, val) = map(t -> apply(t, val), f)
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
    _compute_summary!(axis, summaries, analysis, keys, perm, data)
    summary = collect_columns(s[] for s in summaries)
    mask = findall(t -> nobs(t) >= min_nobs, summaries)
    return StructArray(axis[mask] => StructArray((summary[mask],)))
end

function _compute_summary!(axis, summaries, analysis, keys, perm, data)
    for (_, idxs) in finduniquesorted(keys, perm)
        fititer!(axis, summaries, analysis(tupleofarrays(view(data, idxs))...))
    end
end

compute_summary(::Nothing, args...; kwargs...) = compute_summary(args...; kwargs...)

function compute_summary(t::IndexedTable, ::Nothing; select, kwargs...)
    StructArray(Base.OneTo(length(t)) => rows(t, select))
end

function compute_summary(t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(keys, columntuple(t, select); perm=perm, kwargs...)
end

# function compute_summary(f::FunctionOrAnalysis, t::IndexedTable, ::Nothing; select, min_nobs = 2, kwargs...)
#     cols = columntuple(t, select)
#     analysis = compute_axis(f, cols...)
#     axis = get_axis(analysis)
#     summaries = [Summary(; kwargs...) for _ in axis]
#     new_analysis = analysis(summaries = summaries)
#     final_analysis = has_estimator(new_analysis) ? new_analysis(estimator = nothing) : new_analysis
#     final_analysis(cols...)
#     if has_estimator(new_analysis)
#         summary = collect_columns(s[] for s in summaries)
#         mask = findall(t -> nobs(t) >= min_nobs, summaries)
#         return StructArray(axis[mask] => StructArray((summary[mask],)))
#     else
#         summary = collect(s[][1] for s in summaries)
#         return StructArray(axis => StructArray((summary,)))
#     end
# end

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
