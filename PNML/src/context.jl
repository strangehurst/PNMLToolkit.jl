#=

Context of a PNML model. Would be the global context.
Context of a PNML net. Adds PNTD core context.
Context of a Petri/other net. Adds meta-model context.

Context is immutable.
Context may be chained: model <- pnml net <- petri, stockflow, et al.

# Referencs
    Mustache src/context.jl:
    > A context stores objects where named values are looked up.

# GATlab src/syntax used contexts

# others

# Parser Context is `PnmlNet` level. Common bits may be model level.

Tool and label parsers used for `PnmlObjects`
Includes PnmlModel, PnmlNet, Page, Place, Transition, Arc

Only Tool parsers used for `AbstractLabels`.
Defined (or otherwise claimed) labels will not have AbstractLabels as content.
Examples marking, inscription condition, sorttype, declaration

## `ToolParser` collection
  - Each net will have a possibly-empty iteratable collection of parsers.
  - All nets have the same fallback to `AnyElement`.
  - `PNTD` may/should correlate with contents of collection.
  - There will be Vector{ToolInfo} to localize the toolspecific additions.

## `LabelParser` collection
  - `PNTD` definitely correlates with contents of collection.
  - This is how we define the behavior of a net.
  - Fallback is parsed with `XMLDict` into `AnyElement`.
  - There will be Vector{PnmlLabel} to localize the labels.

## Variables
  - relocate `parse_term` `var` keyword arg to a context?

##

##

##

=#

#"Start as Singleton"
#struct Context end
