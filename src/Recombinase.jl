module Recombinase

using IterTools
using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde
using StructArrays: StructVector, StructArray, finduniquesorted, uniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, IndexedTable, colnames, pushcol
import IndexedTables: sortpermby
using ColorTypes: RGB
import Widgets, Observables
using Widgets: Widget, dropdown, toggle, button
using OrderedCollections: OrderedDict
using OnlineStatsBase: FTSeries, nobs, value, Mean
import OnlineStatsBase: fit!

datafolder = joinpath(@__DIR__, "..", "data")

include("analysisfunctions.jl")
include("timeseries.jl")
include("compute_error.jl")
include("styles.jl")
include("plots.jl")
include("gui.jl")

end # module
