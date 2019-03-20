module GroupSummaries

using IterTools
using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde
using StructArrays: StructVector, finduniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, sortpermby, IndexedTable
import ColorBrewer

datafolder = joinpath(@__DIR__, "..", "data")

include("analysisfunctions.jl")
include("compute_error.jl")
include("styles.jl")
include("groupsummaries.jl")

end # module
