module GroupSummaries

using Statistics
using StatsBase: countmap, ecdf
using PooledArrays: PooledVector
using Loess: loess, predict
using KernelDensity: pdf, kde
using StructArrays: StructVector, finduniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened

include("analysisfunctions.jl")
include("compute_error.jl")

end # module
