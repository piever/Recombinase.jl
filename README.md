# Recombinase

[![Build Status](https://travis-ci.org/piever/Recombinase.jl.svg?branch=master)](https://travis-ci.org/piever/Recombinase.jl)

## Tutorial

First, let us load the relevant packages and an example dataset:

```julia
using Statistics, StatsBase, StatsPlots, JuliaDB
using Recombinase: Group, series2D, datafolder
using Recombinase: compute_summary, discrete, density, hazard, cumulative, prediction

data = loadtable(joinpath(datafolder, "school.csv"))
```

### Simple scatter plots

Then we can compute a simple scatter plot of one variable against an other. This is done in two steps: first the positional and named arguments of the plot call are computed, then they are passed to a plotting function:

```julia
args, kwargs = series2D(
    data,
    Group(:Sx),
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)
```
![crowded](https://user-images.githubusercontent.com/6333339/55731327-ef76e080-5a11-11e9-9270-0da5328bef42.png)

This creates an overcrowded plot. We could instead compute the average value of our columns of interest for each school and then plot just one point per school (with error bars representing variability within the school):

```julia
args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    )
scatter(args...; kwargs...)
```
![acrossschool](https://user-images.githubusercontent.com/6333339/55731389-0c131880-5a12-11e9-920e-1ead0d1a7d06.png)

The default is to compute mean and standard error of the mean for error bars. Any two functions could be used (or even just one function if one is not interested in the error bars):

```julia
args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    summarize = median
    )
scatter(args...; kwargs...)
```
![median](https://user-images.githubusercontent.com/6333339/55731479-3664d600-5a12-11e9-94ea-28ab98cb06cd.png)

### Splitting by many variables

We can use different attributes to split the data as follows:

```julia
args, kwargs = series2D(
    data,
    Group(color = :Sx, markershape = :Sector),
    error = :School,
    select = (:MAch, :SSS),
    summarize = median
    )
scatter(args...; kwargs...)
```
![multiple](https://user-images.githubusercontent.com/6333339/55732187-79737900-5a13-11e9-9c21-3f2102a95879.png)

### Styling the plot

There are two ways in which we can style the plot: first, we can pass a custom set of colors instead of the default palette:

```julia
args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    summarize = median,
    color = [:red, :blue]
    )
scatter(args...; kwargs...)
```
![customcolor](https://user-images.githubusercontent.com/6333339/55731756-a4110200-5a12-11e9-9f4e-1731e97cf58f.png)

Second, we can style plat attributes as we would normally do:

```julia
args, kwargs = series2D(
    data,
    Group(:Sx),
    error = :School,
    select = (:MAch, :SSS),
    summarize = median,
    )
scatter(args...; legend = :topleft, markersize = 10, kwargs...)
```
![styleplot](https://user-images.githubusercontent.com/6333339/55731961-feaa5e00-5a12-11e9-8d9d-2ba82a008811.png)

### Computing summaries

It is also possible to get average value and variability of a given analysis (density, cumulative, hazard rate and local regression are supported so far, but one can also add their own function) across groups.

For example (here we use `ribbon` to signal we want a shaded ribbon to denote the error estimate):

```julia
args, kwargs = series2D(
    cumulative,
    data,
    Group(:Sx),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :topleft)
```
![cumulative](https://user-images.githubusercontent.com/6333339/55733126-2c90a200-5a15-11e9-9fb0-168d247639d3.png)

Note that extra keyword arguments can be passed to the analysis:

```julia
args, kwargs = series2D(
    density(bandwidth = 1),
    data,
    Group(color=:Sx, linestyle=:Sector),
    error = :School,
    select = :MAch,
    ribbon = true
   )
plot(args...; kwargs..., legend = :bottom)
```
![density](https://user-images.githubusercontent.com/6333339/55733209-56e25f80-5a15-11e9-909b-c24da810e73e.png)

If we do not specify `error`, it defaults to `error = observations` (so we would compute the `sem` across observations).

```julia
args, kwargs = series2D(
    prediction,
    data,
    Group(color = :Minrty),
    select = (:Sx, :MAch),
)
groupedbar(args...; kwargs...)
```
![barplot](https://user-images.githubusercontent.com/6333339/55737555-4635e780-5a1d-11e9-90a1-ab8c6efd12c3.png)

This is useful to compute bar plots with error bars across observations, but makes less sense for other analyses (for example, for continuous analysis, it generally does not make sense). To instead clump all observations together, you can use `error = ()`.

### Axis style selection

Analysis try to infer the axis type (continuous if the variable is numeric, categorical otherwise). If that is not appropriate for your data you can use `discrete(prediction)` or `continuous(prediction)` (works for `hazard`, `density` and `cumulative` as well).

### Interactive plotting

Most of the above analysis can be selected from a simple [Interact](http://juliagizmos.github.io/Interact.jl/latest/)-based UI. To launch the UI simply do:

```julia
using Recombinase, Interact, StatsPlots, Blink
# here we give the functions we want to use for plotting
ui = Recombinase.gui(data, [plot, scatter, groupedbar]);
w = Window()
body!(w, ui)
```
![interactgui](https://user-images.githubusercontent.com/6333339/55816219-b3af4a00-5ae9-11e9-94f5-d3cc4e5d722d.png)
