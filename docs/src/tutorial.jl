# # Tutorial
#
# First, let us load the relevant packages and an example dataset:
#

using Statistics, StatsBase, StatsPlots, JuliaDB
using OnlineStats
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_summary, discrete, density, hazard, cumulative, prediction

data = loadtable(joinpath(datafolder, "school.csv"))

#
# ### Simple scatter plots
#
# Then we can compute a simple scatter plot of one variable against an other. This is done in two steps: first the positional and named arguments of the plot call are computed, then they are passed to a plotting function:
#

args, kwargs = series2D(
    data,
    Group(:Sx),
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

# This creates an overcrowded plot. We could instead compute the average value of our columns of interest for each school and then plot just one point per school (with error bars representing variability within the school):
#

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)

# By default, this computes the mean and standard error, we can pass `stats = Mean()` to only compute the mean.
#
# ### Splitting by many variables
#
# We can use different attributes to split the data as follows:
#

args, kwargs = series2D(
    data,
    Group(color = :Sx, markershape = :Sector),
    error = :School,
    select = (:MAch, :SSS),
    stats = Mean(),
    )
scatter(args...; kwargs...)

# ### Styling the plot
#
# There are two ways in which we can style the plot: first, we can pass a custom set of colors instead of the default palette:
#

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    stats = Mean(),
    color = [:red, :blue]
    )
scatter(args...; kwargs...)

# Second, we can style plat attributes as we would normally do:
#

args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    stats = Mean(),
    )
scatter(args...; legend = :topleft, markersize = 10, kwargs...)

# ### Computing summaries
#
# It is also possible to get average value and variability of a given analysis (density, cumulative, hazard rate and local regression are supported so far, but one can also add their own function) across groups.
#
# For example (here we use `ribbon` to signal we want a shaded ribbon to denote the error estimate):
#

args, kwargs = series2D(
    cumulative,
    data,
    Group(:Sx),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :topleft)

# Note that extra keyword arguments can be passed to the analysis:
#

args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :bottom)

# If we do not specify `error`, it defaults to the "analyses specific error". For discrete prediction it is the standard error of the mean across observations.
#

args, kwargs = series2D(
    prediction,
    data,
    Group(color = :Minrty),
    select = (:Sx, :MAch),
)
groupedbar(args...; kwargs...)

# ### Axis style selection
#
# Analysis try to infer the axis type (continuous if the variable is numeric, categorical otherwise). If that is not appropriate for your data you can use `discrete(prediction)` or `continuous(prediction)` (works for `hazard`, `density` and `cumulative` as well).
