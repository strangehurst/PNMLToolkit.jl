# SnoopPNML

The `snoopy` environment for the PNML multi-package repository.

```shell
julia --startup-file="no" --project=@.
```

```julia
julia> @time include("setup.jl");
```

When done in the REPL will set
  * pnmlxml::String,
  * m::PnmlModel,
  * n::PnmlNet
that can be analyzed interactivly.

Hardcoded pnmlxml string needs to be done for more net types. We start with `pnmlcore`.

```julia
julia> @code_warntype parse_str(pnmlxml)
julia> @code_warntype PNML.first_net(m)
julia> typeof(PNML.first_net(m))
```
The net is incompletely specified. Not inferrable.

```julia
julia> @code_warntype parse_pnml(xmlnode(pnmlxml); reg = PnmlIDRegistry())
```

```julia
julia> @code_warntype PNML.places(n)
julia> @code_warntype PNML.transitions(n)
julia> @code_warntype PNML.arcs(n)
julia> @code_warntype PNML.conditions(n)
julia> @code_warntype PNML.transitions(n)
julia> @code_warntype PNML.flatten_pages!(n)
julia> @code_warntype PNML.all_arcs(n, :a11)
julia> @code_warntype PNML.arc(n, :a11)

julia> @code_warntype PNML.idregistry(m)
julia> @code_warntype PNML.isregistered(PNML.idregistry(m), :a11)
```

An example of the minimal non-empty pnml model. The parser will still throw a `MalformedException` because there are no <net> elements.

```julia
julia> @code_warntype parse_str("<pnml></pnml>")
```

#TODO

## LVector

This returns an incompletely typed LArray (LVector). Would a barrier function help?
```julia
julia> @code_warntype PNML.initial_markings(n)
```


using AbstractTrees;
    print_tree(tinf)

using ProfileView
    ProfileView.view(flamegraph(tinf))
