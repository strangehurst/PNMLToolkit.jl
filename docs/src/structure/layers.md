```@meta
CurrentModule = PNML
```

```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypes.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
```

```@setup fields
using  PNML, InteractiveUtils, Markdown
list_fields(f) = foreach(println, fieldnames(f))
```

!!! note "Graphics are elided from this discussion"

	Everywhere there are `ToolInfo`s in this discussion one may assume that there
	is also an optional [`Graphics`](@ref) possible.

	While we parse graphics XML into "containers of strings" and [`Coordinate`](@ref)s
	no further use is implemented or planned. And no discussion of use is present.

## Core Layer

An intermediate representation (IR) of the XML model usable to form networks.
Many different flavors of Petri Nets are expected to be implemented using the IR.

XML attribute names and child element tag names are used as keys.
The _pnml_ standard/schemas do not use colliding names.

The core is implemented under the assumption the the input pnml file is valid.
All tags are assumed to be meaningful to the resulting network.
The pnmlcore schema requires undefined tags on objects will be considered pnml labels.

The IR is capable of handling arbitrary labels.

Many label tags from higherlevel pnml schemas are recognized by the IR core parser.
They will be parsed for `pnmlcore` nets. Users are expected to use a meta-model
if they want specific behavior.

Some parts of pnml are complicated.

The crude structure required by the pnmlcore schema:

PnmlModel
- Net
  * Pages
    - Places, Marking, Toolinfos, unclaimed labels  [SortType] [Capacity]
    - Transitions, Condition, Toolinfos, unclaimed labels [TransitionRate]
    - Arcs, Inscription, Toolinfos, unclaimed labels [ArcType]
    - Toolinfos [Labels.TokenGraphics]
    - Labels unclaimed, [Declaration]
    - Subpages
  * Name Label
  * Toolinfos
  * Labels

 This implementation will be a superset of what is in the standard.

Concepts from High-Level Petri Nets will be present in the Core layer.

## Declaration Dictionaries

The XML file format allows declarations to be declared in <net> and <page> elements.

All [`Declaration`](@ref) labels for a net share the same `DeclDict`.
It is net-level data even when in a <page>.

XML XPath is used to gather this information before parsing the rest of the elements.
Allows using `DeclDict` while parsing.

```@docs; canonical=false
DeclDict
```

## Net Data Dictionaries

This is where the graph node storage resides.

PnmlNet dictionaries contain ordered collections of the graph node objects, indexed by REFID symbols.

The XML file format distributes a <net> over one or more <page>s. As the pages are parsed,
the nodes are appended to a dictionary and a `PnmlNetKeys` set.

The `PnmlNet` data dictionaries maintain insertion order.

Each graph node may have labels attached.
What labels depends on the [`PnmlTypes`](@ref)

## ID Sets

[`PnmlNetKeys`](@ref) contains ordered sets of REFID symbols.

```@docs; canonical=false
PnmlNetKeys
```

Each `PnmlNetKeys` set maintains insertion order.

Uses REFIDs to keep track of which page owns which graph nodes or sub-page.
We always use the [`flatten_pages!`](@ref) version.
Testing of non-flattened nets is very minimal.

!!! warning
    After `flatten_pages!` the `PnmlNetKeys` of the only remaining page are assumed to be the same as the `keys` of corresponding `PnmlNet` dictionary.

## Diagram of memory footprint

![alternative text](data_layout.png)
