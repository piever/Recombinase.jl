const Tup = Union{Tuple, NamedTuple}

apply(f, val) = f(val)
apply(::Nothing, val) = val
apply(f::Type, val) = value(fit!(f(), val))
apply(f::Tup, val) = map(t -> apply(t, val), f)
apply(f::Analysis, cols::Tup) = compute_axis(f, cols...)(cols)
apply(f::Analysis, t::IndexedTable; select = cols) = apply(f, columntuple(t, cols))

struct Automatic; end
const automatic = Automatic()
Base.string(::Automatic) = "automatic"

struct MappedStat{C, S}
    f::C
    stat::S
end

fit!(s::MappedStat, vec) = (fit!(s.stat, vec); s)
nobs(s::MappedStat) = nobs(s.stat)
value(s::MappedStat) = s.f(nobs(s), value(s.stat))
Base.copy(s::MappedStat) = MappedStat(s.f, copy(s.stat))

isfinitevalue(::Missing) = false
isfinitevalue(x::Number) = isfinite(x)

const summary = MappedStat(FTSeries(Mean(), Variance(), filter = isfinitevalue)) do nobs, (mean, var)
    (mean, sqrt(var / nobs))
end

compute_summary(keys::AbstractVector, cols::AbstractVector; kwargs...) = compute_summary(keys, (cols,); kwargs...)
function compute_summary(keys::AbstractVector, cols::Tup; perm = sortperm(keys), min_nobs = 2, stat = summary)
    iter = (map(col -> fit!(copy(stat), view(col, idxs)), cols) for (_, idxs) in finduniquesorted(keys, perm))
    collect_columns(map(value, vals) for vals in iter if all(t -> nobs(t) >= min_nobs, vals))
end

compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::AbstractVector; kwargs...) =
    compute_summary(f, keys, (cols,); kwargs...)

function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup;
    min_nobs = 2, perm = sortperm(keys), stat = summary)

    analysis = compute_axis(f, cols...)
    axis = get_axis(analysis)
    summaries = [copy(stat) for _ in axis]
    data = StructVector(cols)
    _compute_summary!(axis, summaries, analysis, keys, perm, data)
    return collect_columns((ax, value(s)) for (ax, s) in zip(axis, summaries) if nobs(s) >= min_nobs)
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
