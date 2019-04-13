const Tup = Union{Tuple, NamedTuple}

_default_confidence(nobs, mean, var) = sqrt(var / nobs)
_mean_trend(confidence, res::OnlineStat) = _mean_trend(confidence, nobs(res), value(res)...) =
_mean_trend(confidence, nobs, arg) = arg
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
    return Summary(FTSeries(estimator...; filter = filter, transform = transform), confidence)
end

fit!(s::Summary, vec) = (fit!(s.series, vec); s)
Base.getindex(s::Summary) = _mean_trend(s.confidence, s.series)

function compute_summary(keys::AbstractVector, cols::Tup; perm = sortperm(keys), kwargs...)

    itr = finduniquesorted(keys, perm)
    s = Summary(; kwargs...)
    collect_columns(key => map(col -> fit!(s, view(col, idxs))[], cols) for (key, idxs) in itr)
end

compute_summary(cols::Tup; kwargs...) = StructArray(Base.OneTo(length(cols[1])) => Tuple(cols))


# compute_summary(t::IndexedTable, args...; kwargs...) = compute_summary(nothing, t, args...; kwargs...)
# compute_summary(::Nothing, t::AbstractVector, args...; kwargs...) = compute_summary(t, args...; kwargs...)


function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup; perm = sortperm(keys),
    kwargs...)

    s = Summary(; kwargs...)
    a = compute_axis(f, cols...)
    axis = get_axis(a)
    data = StructVector(cols)
    iter = (f(tupleofarrays(data[idxs])...) for (_, idxs) in finduniquesorted(keys, perm))

    summary = res.second
    tup = tupleofarrays(summary)
    compute_summary(first(tup), Base.tail(tup); kwargs...)
end

# function compute_summary(f::Union{FunctionOrAnalysis, Nothing}, t::IndexedTable, keys; select, kwargs...)
#     perm, keys = sortpermby(t, keys, return_keys=true)
#     compute_summary(f, keys, columntuple(t, select); perm=perm, kwargs...)
# end

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v) = (v,)
columntuple(t, cols = All()) = to_tuple(columns(t, cols))
