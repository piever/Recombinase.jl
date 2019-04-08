module Recombinase

using IterTools
using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde
using StructArrays: StructVector, StructArray, finduniquesorted, uniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, sortpermby, IndexedTable, colnames
import ColorBrewer
import Widgets, Observables
using Widgets: Widget, dropdown, toggle, button
using OrderedCollections: OrderedDict

datafolder = joinpath(@__DIR__, "..", "data")

include("analysisfunctions.jl")
include("timeseries.jl")
include("compute_error.jl")
include("styles.jl")
include("plots.jl")
include("gui.jl")

end # module
