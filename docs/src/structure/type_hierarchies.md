```@meta
CurrentModule = PNML
```

Overview of some type hierarchies.

```@setup type
using PNML, InteractiveUtils, Markdown, AbstractTrees
AbstractTrees.children(x::Type) = subtypes(x)
type_tree(t) = println(AbstractTrees.repr_tree(t))
```
## AbstractPNTD - Petri Net Type Definition (PNTD)

See [`PnmlTypes`](@ref) module page.

There are levels:  Core (Place-Transition), Continuous and High-Level PNG (HLPNG).

[`PnmlCoreNet`](@ref) is a concrete subtype of [`AbstractPNTD`](@ref).
`PnmlCoreNet` is used by some `PNet.AbstractPetriNet` concrete types (`PNet.SimpleNet`).

[`ContinuousNet`](@ref) is a concrete type of [`AbstractContinuousNet`](@ref).
`ContinuousNet` uses floating point marking and inscriptions.
It is a nonstandard extension to the ISO standard.

[`HLCoreNet`](@ref) is a concrete subtype of [`AbstractHLCore`](@ref).
`HLCoreNet` is used by some `PNet.AbstractPetriNet` concrete types (`PNet.HLPetriNet`).
Think of it as a testable implementation of `AbstractHLCore`.

Tries to represent the model (all models) at a structural level.
Tries to avoid imposing semantics. It is a toolkit with a wide range of behavior.
Those semantics should be part of `PNet.AbstractPetriNet`.
Yes, the [`AbstractPNTD`](@ref) in use selects some semantics and affects the toolkit.

```@example type
type_tree(PNML.PnmlTypes.AbstractPNTD) # hide
```

| PnmlType     | Description                                               |
| :---------   | :-------------------------------------------------------- |
| PnmlCoreNet  | Core structure. Only defined label is <name>.  |
| PTNet        | Using <initialMarking>, <inscription> labels that have a <text> containing a number.  |
| HLCoreNet    | HL Petri Net Graphs structure. Using <hlinitialMarking>, <hlinscription> labels with <structure>. Multisorted algebra.      |
| PT-HLPNG     | Restrict sort to dot, condition always true.              |
| SymmetricNet | Restrict sorts to finite, annotations have <structure>.   |
| HLNet        | Unrestricted, Arbitrary Sorts, Operators, Lists, Strings. |
| Stochastic   | Extended PNML. Use <rate> label                           |
| Timed        | Extended PNML.                                            |
| Open         | Extended PNML .                                           |

Todo: Continuous Petri Net

## PNet.AbstractPetriNet

`PNet.AbstractPetriNet` uses the Intermediate Representation's
[`PnmlNet`](@ref) and `AbstractPNTD` to implement a Petri Net Graph (PNG).

## AbstractPnmlObject

[`Page`](@ref), [`Arc`](@ref), [`Place`](@ref), [`Transition`](@ref) define the graph of a [`PnmlNet`](@ref).

```@example type
type_tree(PNML.AbstractPnmlObject) # hide
```

### Structure

Fields expected of every subtype of [`AbstractPnmlObject`](@ref):

| Name      | Description |
|:----------|:-----------------------------------|
| id        | Symbol, see ['REFID](@ref PNML.REFID) |
| pntd      | <: [`AbstractPNTD`](@ref) identifies the meta-model of a net. |
| name      | Optional [`Name`](@ref) label. |
| labels    | Optional [`PnmlLabel`](@ref) collection of unclaimed labels. |
| toolspecinfos | Optional [`ToolInfo`](@ref) collection of tool specific content. |

Note that subtypes may have additional fields. For example, Page has a subpages field.

### ADT

```julia
using Moshi.Data: @data

@data NetNode{PNTD,} begin
    Arc
    Place
    Transition
    RefPlace
    RefTransition
    Page
end
```







## AbstractLabel

[`AbstractLabel`](@ref)s are attached to `AbstractPnmlObject`s.
Kinds of label include: marking, inscription, condition and declarations, sort, and ad-hoc.
Ad-hoc is where we assume any undefined element attached to a `AbstractPnmlObject` instance
is a label and add it to a collection of 'other labels'.
Some 'other labels' can be accessed using: [`rate_value`](@ref), [`delay_value`](@ref).

**Some Labels of Interest**

| Full Name     | Node       | Label Description                                   |
|:--------------|:-----------|:----------------------------------------------------|
| Marking       | Place      | Value is a number or ground term.                   |
| Inscription   | Arc        | Value is a number or ground term.                   |
| Condition     | Transition | Value is a boolean term.                            |
| Rate          | Transition | Value is a floating point number.                   |
| Priority      | Transition | Firing order of enabled transitions.                |
| Weight        | Transition | Firing tiebreaker.                                  |

Note that *Rate*, *Priority* and *Weight* are not part of base standard.
See [Unclaimed Labels](@ref)

```@example type
type_tree(PNML.AbstractLabel) # hide
```

!!! info "Difference between Object and Label"

	- Objects have *id*s and `Name`s.
    - Labels are attached to Objects.
    - Some Labels (attributes) do not have `Graphics`.
    - Labels are extendable.
    - Labels are named by the xml tag. Any "unknown" tag of an Object is presumed to be a label.


## PnmlException
```@example type
type_tree(PNML.PnmlException) # hide
```

# Many-sorted Algebra Concepts

The PNML Standard builds the High-level Petri Net Graph as a layer using a Core layer (PnmlCore). The main feature of the HL layer (HLCore) is to require all annotation labels to have <text> and <structure> elements. All meaning is required to reside in a single child of <structure>. With the <text> for human/documentation use.

Implemented so that it is mostly part of the PnmlCore implementation.
At which level, both <text> and <structure> are optional.

The <type> label of a [`Place`](@ref) is meant to be a _sort_ of a _many-sorted algebra_.
We call it _sorttype_ to reduce the confusion.

PNML.jl allows/requires all net type's places to have _sorttype_ objects. Only high-level PNML input is expected to contain a <type> tag. For other nets we interpret the [`SortType`](@ref PNML.Labels.SortType) to be [`IntegerSort`](@ref) or [`RealSort`](@ref) based on PNTD. And [`Marking`](@ref) values of non-high-level nets are interpreted as multisets with airity of 1.
This allows more common implementation in the core layer.

For high-level nets the sorttype object is an [`SortType`](@ref PNML.Labels.SortType) `HLAnnotation`
subtype containing an [`AbstractSort`](@ref).

## AbstractDeclaration
Labels attached to [`PnmlNet`](@ref) and/or [`Page`](@ref).
The [`Declaration`](@ref)s contained in a <declarations> apply to the whole net even when attached to a `Page`.
```@example type
type_tree(PNML.AbstractDeclaration) # hide
```
## AbstractSort
Each `Place` has a sorttype containing an `AbstractSort`.
```@example type
type_tree(PNML.AbstractSort) # hide
```
## AbstractTerm
Part of the *many-sorted algebra* of a High-level net.
See [`AbstractOperator`](@ref). [`Variable`](@ref)
```@example type
type_tree(PNML.AbstractTerm) # hide
```

## PnmlExpr
Expressions of the *many-sorted algebra* are part of a petri net's dynamic behavior.
[`PnmlExpr`](@ref) are `TermInterface` compatible.
Used to do variable substitution before evaluation of mutisorted algebra expressions
in enabling and firing rules. Ground terms contain no variables and therefore
do not depend on the current marking of the net.
```@example type
type_tree(PNML.PnmlExpr) # hide
```
