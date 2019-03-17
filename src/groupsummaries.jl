struct Group{NT}
    kwargs::NT
    function Group(; kwargs...)
        nt = values(kwargs)
        NT = typeof(nt)
        return new{NT}(nt)
    end
end

Group(s) = Group((; color = s))

function series2D(s::StructVector{<:Pair}; ribbon = false)
    cols = fieldarrays(s.second)
    kwargs = Dict{Symbol, Any}()
    if length(cols) == 1
        x = s.first
        ycols = fieldarrays(cols[1])
        y = ycols[1]
        yerr = ifelse(ribbon, :ribbon, :yerr)
        length(ycols) == 2 && (kwargs[yerr] = ycols[2])
    else
        xcols, ycols = map(fieldarrays, cols)
        x, y = xcols[1], ycols[1]
        length(xcols) == 2 && (kwargs[:xerr] = xcols[2])
        length(ycols) == 2 && (kwargs[:yerr] = ycols[2])
    end
    return (x, y), kwargs
end

series2D(t::IndexedTable, g = Group(); kwargs...) = series2D(nothing, t, g; kwargs...)

function series2D(f, t::IndexedTable, g = Group(); across, select, ribbon = false, filter = isfinite, summarize = (mean, sem), kwargs...)
    group = g.kwargs
    isempty(group) && return series2D(compute_error(f, t; across=across, select=select, filter=filter, summarize=summarize), ribbon = ribbon)

    by = Tuple(unique(group))
    perm = sortpermby(t, by)
    itr = finduniquesorted(rows(t, by), perm)
    data = collect_columns_flattened(key => compute_error(f, t[idxs]; across=across, select=select,  filter=filter, summarize=summarize) for (key, idxs) in itr)
    plot_args, plot_kwargs = series2D(data.second; ribbon = ribbon)
    plot_kwargs[:group] = data.first
    grpd = collect_columns(key for (key, _) in itr)
    style_kwargs = Dict(kwargs)
    for (key, val) in pairs(group)
        col = getproperty(grpd, val)
        s = unique(sort(col))
        d = Dict(zip(s, 1:length(s)))
        style = get(style_kwargs, key) do
            style_dict[key]
        end
        plot_kwargs[key] = permutedims(vec(style)[getindex.(Ref(d), col)])
    end
    plot_args, plot_kwargs
end
