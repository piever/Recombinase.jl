# # Digging deeper

# The core functioning of Recombinase is based on a set of preimplemented analysis
# functions and on the [OnlineStats](https://github.com/joshday/OnlineStats.jl) package
# to compute summary statistics efficiently.

# ## Analysis functions

# Under the hood, the actual computations are implemented in some built-in `Analysis`
# objects. Each `Analysis` takes some vectors (a varying number, one for `density`
# and two for `prediction` for example), an optional `axis` argument to specify
# the `x` axis argument and returns an iterator of `(x, y)` values, representing
# the `y` value corresponding to each point of the `x` axis.

using Recombinase: density, hazard, cumulative, prediction
x = randn(100)
res = density(x)
collect(Iterators.take(res, 5)) # let's see the first few elements

# We can collect the iterator in a table container to see
# that we recover the `x` and `y` axis, ready for plotting

using JuliaDB
s = table(res)

# `prediction` is similar but requrires two arguments:

xs = 10 .* rand(100)
ys = sin.(xs) .+ 0.5 .* rand(100)

res = prediction(xs, ys)
table(res)

# The function `discrete` can turn any analysis into its discrete counter-part
# (analyses are continuous for numerical axes and discrete otherwise by default).
# It also automatically comutes the error of the prediction (s.e.m).

using Recombinase: discrete

x = rand(1:3, 1000)
y = rand(1000) .+ 0.1 .* x

res = discrete(prediction)(x, y)
table(res)

# ## OnlineStats integration

# Summary statistics are computed using the excellent [OnlineStats](https://github.com/joshday/OnlineStats.jl)
# package. First the data is split by the splitting variable (in this case `School`),
# then the analysis is computed on each split chunk on the selected column(s).
# Finally the results from different schools are put together in summary statistics
# (default is `mean` and `s.e.m`):

using Recombinase: datafolder, compute_summary
data = loadtable(joinpath(datafolder, "school.csv"))
compute_summary(density, data, :School; select = :MAch)

# The computation of the summary statistic works in two steps. First statistics from the keyword
# argument `estimator = (Mean, Variance)` of `compute_summary` are computed online,
# then the function from a keyword argument `postprocess = (nobs, mean, var) -> (mean, sqrt(var / nobs))`
# turn this statistics into values we plot (`mean` and `s.e.m`). `postprocess` needs to take one more
# argument than the number of statistics of `estimator` (the number of observations, which is the first argument).
# To compute a different error bar (for example just the standard deviation) you can simply do:

compute_summary(density, data, :School; select = :MAch, postprocess = (nobs, mean, var) -> (mean, sqrt(var)))
