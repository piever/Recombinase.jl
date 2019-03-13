module GroupSummaries

using Statistics
using StructArrays: StructVector, finduniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened

include("analysisfunctions.jl")
include("groupsummaries.jl")

end # module
