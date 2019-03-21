_hbox(args...) = Widgets.div(args...; style = Dict("display" => "flex", "flex-direction"=>"row"))
_vbox(args...) = Widgets.div(args...; style = Dict("display" => "flex", "flex-direction"=>"column"))

const analysis_options = OrderedDict(
    "" => nothing,
    "Cumulative" => GroupSummaries.cumulative,
    "Density" => GroupSummaries.density,
    "Frequency" => GroupSummaries.frequency,
    "Hazard" => GroupSummaries.hazard,
    "Local Regression" => GroupSummaries.localregression,
    "Expected Value" => GroupSummaries.expectedvalue
)

"""
`gui(data, plotters)`

Create a gui around `data::IndexedTable` given a list of plotting
functions plotters.

## Examples

```julia
using StatsPlots, GroupSummaries, JuliaDB, Interact
school = loadtable(joinpath(GroupSummaries.datafolder, "school.csv"))
plotters = [plot, scatter, groupedbar]
GroupSummaries.gui(school, plotters)
```
"""
function gui(data, plotters)
    (data isa Observables.AbstractObservable) || (data = Observables.Observable{Any}(data))
    ns = Observables.@map collect(colnames(&data))
    maybens = Observables.@map vcat(Symbol(), &ns)
    xaxis = dropdown(ns,label = "X")
    yaxis = dropdown(maybens,label = "Y")
    an_opt = dropdown(analysis_options, label = "Analysis")
    across = dropdown(ns, label="Across")
    styles = collect(keys(style_dict))
    sort!(styles)
    splinters = [dropdown(maybens, label = string(style)) for style in styles]
    plotter = dropdown(plotters, label = "Plotter")
    ribbon = toggle("Ribbon", value = false)
    btn = button("Plot")
    output = Observables.Observable{Any}("Set the dropdown and press plot to get started.")
    Observables.@map! output begin
        &btn
        select = yaxis[] == Symbol() ? xaxis[] : (xaxis[], yaxis[])
        grps = Dict(key => val[] for (key, val) in zip(styles, splinters) if val[] != Symbol())
        args, kwargs = series2D(an_opt[], &data, Group(; grps...);
            select = select, across = across[], ribbon = ribbon[])
        plotter[](args...; kwargs...)
    end
    ui = Widget(
        OrderedDict(
            :xaxis => xaxis,
            :yaxis => yaxis,
            :analysis => an_opt,
            :across => across,
            :plotter => plotter,
            :plot_button => btn,
            :ribbon => ribbon,
            :splinters => splinters,
        ),
        output = output
    )
    Widgets.@layout! ui Widgets.div(_hbox(:xaxis, :yaxis, :analysis, :across, :plotter), :ribbon, :plot_button,
        _hbox(_vbox(:splinters...), output))
end
