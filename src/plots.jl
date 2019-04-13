struct Group{NT}
    kwargs::NT
    function Group(; kwargs...)
        nt = values(kwargs)
        NT = typeof(nt)
        return new{NT}(nt)
    end
end

Group(s) = Group(color = s)

to_string(t::Tuple) = join(t, ", ")
to_string(t::Any) = string(t)
to_string(nt::NamedTuple) = join(("$a = $b" for (a, b) in pairs(nt)), ", ")

struct Observations; end
const observations = Observations()
Base.string(::Observations) = "observations"
function sortpermby(t::IndexedTable, ::Observations; return_keys = false)
    perm = Base.OneTo(length(t))
    return return_keys ? (perm, perm) : perm
end

function series2D(s::StructVector{<:Pair}; ribbon = false)
    cols = fieldarrays(s.second)
    kwargs = Dict{Symbol, Any}()
    if length(cols) == 1
        x = s.first
        ycols = columntuple(cols[1])
        y = ycols[1]
        yerr = ifelse(ribbon, :ribbon, :yerr)
        length(ycols) == 2 && (kwargs[yerr] = ycols[2])
    else
        xcols, ycols = map(columntuple, cols)
        x, y = xcols[1], ycols[1]
        length(xcols) == 2 && (kwargs[:xerr] = xcols[2])
        length(ycols) == 2 && (kwargs[:yerr] = ycols[2])
    end
    return (x, y), kwargs
end

series2D(t::IndexedTable, g = Group(); kwargs...) = series2D(nothing, t, g; kwargs...)

_confidence(var, nobs) = sqrt(var / nobs)

function series2D(f, t′::IndexedTable, g = Group();
    select, error = false, ribbon = false, filter = isfinite,
    estimator = (Mean, Var), confidence = _confidence, min_nobs = 2, kwargs...)

    if isnothing(f)
        (error isa Bool) && (error = error ? () : observations)
    else

    error == () && (error = fill(0, length(t′)))
    if error isa AbstractVector
        counter = 0
        sym =:error
        while sym in colnames(t′)
            counter += 1
            sym = Symbol("$error_$counter")
        end
        t = pushcol(t′, sym => error)
        error = sym
    else
        t = t′
    end
    group = g.kwargs
    if isempty(group)
        args, kwargs = series2D(compute_error(f, t, error, select=select, filter=filter, summarize=summarize), ribbon = ribbon)
        kwargs[:group] = fill("", length(args[1]))
        return args, kwargs
    end
    by = _flatten(group)
    perm = sortpermby(t, by)
    itr = finduniquesorted(rows(t, by), perm)
    data = collect_columns_flattened(key => compute_error(f, t[idxs], error, select=select,  filter=filter, summarize=summarize) for (key, idxs) in itr)
    plot_args, plot_kwargs = series2D(data.second; ribbon = ribbon)
    plot_kwargs[:group] = columns(data.first)
    grpd = collect_columns(key for (key, _) in itr)
    style_kwargs = Dict(kwargs)
    for (key, val) in pairs(group)
        col = rows(grpd, val)
        s = unique(sort(col))
        d = Dict(zip(s, 1:length(s)))
        style = get(style_kwargs, key) do
            style_dict[key]
        end
        plot_kwargs[key] = permutedims(access_style(style, getindex.(Ref(d), col)))
    end
    get!(plot_kwargs, :color, "black")
    plot_args, plot_kwargs
end

function access_style(st, n::AbstractArray)
    [access_style(st, i) for i in n]
end

function access_style(st, n::Integer)
    v = vec(st)
    m = ((n-1) % length(v))+1
    v[m]
end

_flatten(t) = IterTools.imap(to_tuple, t) |>
    Iterators.flatten |>
    IterTools.distinct |>
    Tuple
