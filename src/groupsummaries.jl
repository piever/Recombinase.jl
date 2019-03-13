function splitapply(f, data, across::AbstractVector, p::AbstractVector{<:Integer}, args...)
    itr = finduniquesorted(across, p)
    return collect_columns_flattened(key => f(data[idxs], args...) for (key, idxs) in itr)
end

apply(f, val) = f(val)
apply(f::Tuple, val) = map(t -> t(val), f)

function summaries(s::StructVector, funcs...)
    cols = fieldarrays(s)
    itr = finduniquesorted(cols[1])
    n = length(funcs)
    collect_columns(key => ntuple(i -> apply(funcs[i], cols[i+1][idxs]), n) for (key, idxs) in itr)
end

function sac(f, data, across, p, funcs...)
    axis = unique(fieldarrays(data)[1])
    res = splitapply(f, data, across, sortperm(across), axis)
    summaries(res.second, funcs...)
end



    
    
    




    
