const Tup = Union{Tuple, NamedTuple}

_postprocess(nobs, mean, var, args...) = (mean, sqrt(var / nobs))
_postprocess(nobs, mean) = (mean,)

apply(f, val) = f(val)
apply(::Nothing, val) = val
apply(f::Type, val) = value(fit!(f(), val))
apply(f::Tup, val) = map(t -> apply(t, val), f)
apply(f::Analysis, cols::Tup) = compute_axis(f, cols...)(cols)
apply(f::Analysis, t::IndexedTable; select = cols) = apply(f, columntuple(t, cols))

struct Automatic; end
const automatic = Automatic()
Base.string(::Automatic) = "automatic"

struct Summary{S<:FTSeries, C}
    ftseries::S
    postprocess::C
end

function Summary(; transform = identity, filter = isfinitevalue,
    postprocess = _postprocess, estimator = (Mean, Variance))
    return Summary(FTSeries((stat() for stat in to_tuple(estimator))...;
        filter = filter, transform = transform), postprocess)
end

fit!(s::Summary, vec) = (fit!(s.ftseries, vec); s)
nobs(s::Summary) = nobs(s.ftseries)
Base.getindex(s::Summary) = s.postprocess(nobs(s.ftseries), value(s.ftseries)...)

compute_summary(keys::AbstractVector, cols::AbstractVector; kwargs...) = compute_summary(keys, (cols,); kwargs...)
function compute_summary(keys::AbstractVector, cols::Tup; perm = sortperm(keys), min_nobs = 2, kwargs...)
    iter = (map(col -> fit!(Summary(; kwargs...), view(col, idxs)), cols) for (_, idxs) in finduniquesorted(keys, perm))
    collect_columns(map(getindex, vals) for vals in iter if all(t -> nobs(t) >= min_nobs, vals))
end

compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::AbstractVector; kwargs...) =
    compute_summary(f, keys, (cols,); kwargs...)

function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup;
    min_nobs = 2, perm = sortperm(keys), kwargs...)

    analysis = compute_axis(f, cols...)
    axis = get_axis(analysis)
    summaries = [Summary(; kwargs...) for _ in axis]
    data = StructVector(cols)
    _compute_summary!(axis, summaries, analysis, keys, perm, data)
    summary = collect_columns(s[] for s in summaries)
    mask = findall(t -> nobs(t) >= min_nobs, summaries)
    return StructArray((axis[mask], summary[mask]))
end

function _compute_summary!(axis, summaries, analysis, keys, perm, data)
    for (_, idxs) in finduniquesorted(keys, perm)
        fititer!(axis, summaries, analysis(tupleofarrays(view(data, idxs))...))
    end
end

compute_summary(::Nothing, args...; kwargs...) = compute_summary(args...; kwargs...)

function compute_summary(t::IndexedTable, ::Automatic; select, kwargs...)
    rows(t, select)
end

function compute_summary(t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(keys, columntuple(t, select); perm=perm, kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(f, keys, columntuple(t, select); perm=perm, kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, t::IndexedTable, ::Automatic; select, kwargs...)
    args = columntuple(t, select)
    has_error(f, args...) && (f = f(; kwargs...))
    collect_columns(f(args...))
end

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v) = (v,)
columntuple(t, cols) = to_tuple(columns(t, cols))
columntuple(t) = to_tuple(columns(t))
