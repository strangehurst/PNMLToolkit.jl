```@meta
CurrentModule = PNML
```

```@setup methods
using PNML, InteractiveUtils, Markdown
```

```@setup methods
using PNML, InteractiveUtils, Markdown
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

# Interface

!!! warning
    Being a work in progress, there will be obsolete, optimistic or incoherent bits.

    Eventually this section will cover interfaces in a useful way.

The intermediate representation is used to implement networks expressed in a pnml model. The consumer of the IR is a network is most naturally a varity of Petri Net.


We start a description of the net IR here.

## Dict Type

[`XmlDictType`](@ref) used by:
  * [`AnyElement`](@ref)
  * [`Labels.PnmlLabel`](@ref)
  * [`Labels.SortType`](@ref)
  * [`Parser.xmldict`](@ref)

## Top Level: Model, Net, Page

At the top level[^layers] a <pnml> model is one or more networks::[`PnmlNet`](@ref),
each described by a <net> tag and one or more <page> tags.

[`Page`](@ref)
 is a required element mostly present for visual presentation to humans.
It contains [`AbstractPnmlObject`](@ref) types that implement the Petri Net Graph (PNG).

[^layers]:
    `Page` inside a `PnmlNet` inside a `PNet.AbstractPetriNet`.
    Where the Petri Net part is expressed as a Petri Net Type Definition XML schema
    file (.pntd) identified by a URI. Or would if our nonstandard extensions had schemas
    defined. Someday there will be such schemas.

While [`Graphics`](@ref) is implemented
it is not dicussed further (until someone extends/uses it).

[`ToolInfo`](@ref) used to attach well-formed XML almost anywhere in the PNG.
TODO: document toolparser.

Parse pnml for input, worry about writing back out and interchange later (future extensions).
Another future extension may be to use pages for distributed computing.

The pnml standard permits that multiple pages canto be flattened
(by [`flatten_pages!`](@ref)) to a single `Page` before use. We do that.

`PNet.AbstractPetriNet` subtypes wrap and extend [`PnmlNet`](@ref).
Note the **Pnml** to **Petri**.

`PnmlNet` and its contents can be considered an intermediate representation (IR).
A concrete `PNet.AbstractPetriNet` type uses the IR to produce higher-level behavior.
This is the level at which [`flatten_pages!`](@ref) and [`deref!`](@ref) operate.

`PNet.AbstractPetriNet` is the level of most Petri Net Graph semantics.
One example is enforcing integer, non-negative, positive.
One mechanism used is type parameters.

Remember, the IR trys to be as promiscuous as possible.

XML <net> tags are parsed by [`parse_net`](@ref PNML.Parser.parse_net) into a [`PnmlNet`](@ref).

XML <page> tags are parsed by [`parse_page!`](@ref PNML.Parser.parse_page!) into a [`Page`](@ref).

## Places

Properties that various places may have one or more of:
  * discrete
  * continuous
  * timed

## Transitions

Properties that various transitions may have one or more of:
  * discrete
  * continuous
  * hybrid of discrete & continuous subnets
  * stochastic
  * immediate
  * deterministically time delayed
  * scheduled

The pnml schemas and primer only try to cover the discrete case as Place-Transition and High-Level Petri Nets.

## Extensions to PNML

### Continuous Values

Continous support is present where possible. For instance, when a number appers in the XML
[`number_value`](@ref) is used to parse the string to `Int` or `Float64`.
This is currently (2022) "non-standard" so such pnml files will not be generally
interchangable with other tools.

['Discrete, Continuous, and Hybrid Petri Nets' by Rene David and Hassane Alla](https://link.springer.com/book/10.1007/978-3-642-10669-9)

[VANESA](https://www.sciencedirect.com/science/article/pii/S0303264721001714#b8)

See [`rate_value`](@ref) for a use of non-standard labels.
Implements a stochastic petri net as part of the first working use-case.
Demonstrates the expressiveness of pnml.

## Petri Net Graphs and Networks

There are 3 top-level forms:
  - `PNet.AbstractPetriNet` subtypes wraping a single `PnmlNet`.
  - [`PnmlNet`](@ref)  maybe multiple pages.
  - [`Page`](@ref) as the only page of the only net in a `Abstractpetrinet`.

The simplest arrangement is a pnml model with a single <net> element having
a single <page>. Any <net> may be flatten to a single page.

The initial `PNet.AbstractPetriNet` subtypes are built using the assumption that
multiple pages will be flattened to a single page.

## Simple Interface Methods

What makes a method simple? No other arguments besides the object it operates upon.

### pid(x) - get PNML ID symbol

Many things within a pnml net have unique identifiers,
which are used for referring to the object.

[`PNML.pid`](@ref)
```@example methods
methods(PNML.pid) # hide
```

### name(x) - get name

`AbstractPnmlObject`s and `PnmlNet`s have a name label.
[`PNML.Labels.Declaration`](@ref)s have a name attribute.
[`ToolInfo`](@ref)s have a toolname attribute.

[`PNML.name`](@ref)
```@example methods
methods(PNML.name) # hide
```

### tag(x) - access XML tag symbol

[`PNML.tag`](@ref)
```@example methods
methods(PNML.tag) # hide
```

### nettype(x) - return PnmlType identifying PNTD

[`PNML.nettype`](@ref)
```@example methods
methods(PNML.nettype) # hide
```

## Nodes of Petri Net Graph

Return vector of nodes.  Assumes flattened net so that the `PnmlNet` and `Page`
refer to the same net-level `AbstractDict` data structure.

### places
[`PNML.places`](@ref)
```@example methods
methods(PNML.places) # hide
```
### transitions
[`PNML.transitions`](@ref)
```@example methods
methods(PNML.transitions) # hide
```
### arcs
[`PNML.arcs`](@ref)
```@example methods
methods(PNML.arcs) # hide
```
### refplaces
[`PNML.refplaces`](@ref)
```@example methods
methods(PNML.refplaces)  # hide
```
### reftransitions
[`PNML.reftransitions`](@ref)
```@example methods
methods(PNML.reftransitions)  # hide
```

## Node Predicates - uses PNML ID

### has\_place
[`PNML.has_place`](@ref)
```@example methods
methods(PNML.has_place)  # hide
```
### has\_transition
[`PNML.has_place`](@ref)
```@example methods
methods(PNML.has_transition)  # hide
```
### has\_arc
[`PNML.has_arc`](@ref)
```@example methods
methods(PNML.has_arc) # hide
```
### has\_refplace
[`PNML.has_refplace`](@ref)
```@example methods
methods(PNML.has_refplace)  # hide
```
### has\_reftransition
[`PNML.has_reftransition`](@ref)
```@example methods
methods(PNML.has_reftransition)  # hide
```

## Node Access - uses PNML ID

### place
[`PNML.place`](@ref)
```@example methods
methods(PNML.place)  # hide
```
### transition
[`PNML.transition`](@ref)
```@example methods
methods(PNML.transition) # hide
```
### arc
[`PNML.arc`](@ref)
```@example methods
methods(PNML.arc)  # hide
```
### refplace
[`PNML.refplace`](@ref)
```@example methods
methods(PNML.refplace)  # hide
```
### reftransition
[`PNML.reftransition`](@ref)
```@example methods
methods(PNML.reftransition)  # hide
```

## Node ID Iteratables

Better to iterate than allocate. Using a set abstraction that iterates consistently, perhaps in insertion order.

### place\_idset
| Object       | Synopsis                     | Comment                              |
|:-------------|:-----------------------------|:-------------------------------------|
| PnmlNet      | `keys(placedict(net))`       | Iterates [`PnmlNetData`](@ref) OrderedDict keys |
| Page         | `place_idset(netsets(page))` | Iterates [`PnmlNetKeys`](@ref) OrderedSet |
| PnmlNetKeys  | `OrderedSet` | Iterates [`PnmlNetKeys`](@ref) OrderedSet |

Both iterate over REFIDs that are indices into PnmlNetData.,
To access a `Place` in the `PnmlNetData` use `place(refid)`.

The contents of PnmlKeySet are indices into PnmlNetData.
When there is only one page, the keys of the `placedict` and `place_set` will be (must be) the same.

For the foreseeable future, there will be little use of multi-page APIs.
It is expected that flattened PNML nets will be the fully supported,
tested, thought-through API.

The discussion using place\_idset also applies to other \*_idsets.

[`PNML.place_idset`](@ref)
```@example methods
methods(PNML.place_idset)  # hide
```
### transition\_idset
[`PNML.transition_idset`](@ref)
```@example methods
methods(PNML.transition_idset)  # hide
```
### arc\_idset
[`PNML.arc_idset`](@ref)
```@example methods
methods(PNML.arc_idset)  # hide
```
### refplace\_idset
[`PNML.refplace_idset`](@ref)
```@example methods
methods(PNML.refplace_idset)  # hide
```
### reftransition\_idset
[`PNML.reftransition_idset`](@ref)
```@example methods
methods(PNML.reftransition_idset)  # hide
```

## Arc Related

### all\_arcs - source or target is PNML ID
[`PNML.all_arcs`](@ref)
```@example methods
methods(PNML.all_arcs)  # hide
```
### src\_arcs - source is PNML ID
[`PNML.src_arcs`](@ref)
```@example methods
methods(PNML.src_arcs)  # hide
```
### tgt\_arcs - target is PNML ID
[`tgt_arcs`](@ref)
```@example methods
methods(PNML.tgt_arcs)  # hide
```
### inscription - evaluate inscription value (or return default)
[`inscription`](@ref)
```@example methods
methods(PNML.inscription)  # hide
```
### deref! - dereference all references of flattened net
[`deref!`](@ref)
```@example methods
methods(PNML.deref!)  # hide
```
### deref\_place - dereference one place
[`deref_place`](@ref)
```@example methods
methods(PNML.deref_place)  # hide
```
### deref\_transition - dereference one transition
[`deref_transition`](@ref)
```@example methods
methods(PNML.deref_transition)  # hide
```

## Place Related

### initial_marking - evaluate marking value (or return default)
[`initial_marking`](@ref)
```@example methods
methods(PNML.initial_marking)  # hide
```
## Transition Related

### conditions - collect evaluated conditions
[`conditions`](@ref)
```@example methods
methods(PNML.conditions)  # hide
```
### condition - evaluate condition of one transition
[`condition`](@ref)
```@example methods
methods(PNML.condition)  # hide
```
## Labels - `Annotation` and `HLAnnotation`

Both kinds (all labels) have `Graphics` and `ToolInfo`.
[`Labels.HLAnnotation`](@ref) adds optional <text>, <structure>.

### text
[`text`](@ref)
```@example methods
methods(PNML.text) # hide
```

### value
[`value`](@ref)
```@example methods
methods(PNML.value) # hide
```

### get_label - get a specific label
[`get_label`](@ref PNML.Labels.get_label)
```@example methods
methods(PNML.Labels.get_label) # hide
```

## ToolInfo

### get_toolinfo - get a specific toolinfo exist
[`PNML.Labels.get_toolinfo`](@ref)
```@example methods
methods(PNML.Labels.get_toolinfo) # hide
```


## Type Lookup

Petri Net Graph Object Types are parameterized by [Label Types](@ref).
What labels are "allowed" (syntax vs. semantics vs. schema vs. standard)
is parameterized on the PNTD (Petri Net Type Definition).

See [`PnmlNet`](@ref)s & [`AbstractPnmlObject`](@ref)s, and
 [`PnmlTypes`](@ref) for details of the singleton types used.

### Value Types

TBD



!!! info "parse_sorttype is different"
    [`Parser.parse_sorttype`](@ref) is used to parse an XML <type> element.
    It is not one of these look-up a type trait methods.
