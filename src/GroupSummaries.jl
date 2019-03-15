module GroupSummaries

using Statistics
using Loess: loess, predict
using StructArrays: StructVector, finduniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened

include("analysisfunctions.jl")
include("summaries.jl")

end # module
