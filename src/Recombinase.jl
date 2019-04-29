module Recombinase

using IterTools
using Statistics
using StatsBase: countmap, ecdf, sem
using Loess: loess, predict
using KernelDensity: pdf, kde, InterpKDE
using StructArrays: StructVector, StructArray, finduniquesorted, uniquesorted, fieldarrays, GroupPerm
using IndexedTables: collect_columns, collect_columns_flattened, rows, columns, IndexedTable, colnames, pushcol
import IndexedTables: sortpermby, lowerselection
using ColorTypes: RGB
import Widgets, Observables
using Widgets: Widget, dropdown, toggle, button
using OrderedCollections: OrderedDict
using OnlineStatsBase: Mean, Variance, FTSeries, fit!, OnlineStat, nobs, value

export Group, compute_summary, series2D
export discrete

datafolder = joinpath(@__DIR__, "..", "data")

include("analysisfunctions.jl")
include("timeseries.jl")
include("compute_summary.jl")
include("styles.jl")
include("plots.jl")
include("gui.jl")

end # module
