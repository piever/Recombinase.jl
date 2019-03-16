module GroupSummaries

using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde
using StructArrays: StructVector, finduniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, sortpermby, IndexedTable

include("analysisfunctions.jl")
include("compute_error.jl")
include("groupsummaries.jl")

end # module
