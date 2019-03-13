function _locreg(t, xaxis; estimator = mean)
    cols = fieldarrays(t)
    itr = finduniquesorted(cols[1])
    collect_columns((key, estimator(cols[2][idxs])) for (key, idxs) in itr)
end
