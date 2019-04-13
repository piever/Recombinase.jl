module Recombinase

using IterTools
using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde, InterpKDE
using StructArrays: StructVector, StructArray, finduniquesorted, uniquesorted, fieldarrays
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, IndexedTable, colnames, pushcol
import IndexedTables: sortpermby
using ColorTypes: RGB
import Widgets, Observables
using Widgets: Widget, dropdown, toggle, button
using OrderedCollections: OrderedDict
using OnlineStatsBase: FTSeries, value, Mean, Variance
import OnlineStatsBase: fit!, nobs

datafolder = joinpath(@__DIR__, "..", "data")

include("analysisfunctions.jl")
include("timeseries.jl")
include("compute_summary.jl")
include("styles.jl")
include("plots.jl")
include("gui.jl")

end # module
