module Labels

import ..Expressions: PnmlExpr, expr_sortref, toexpr
import AutoHashEquals: @auto_hash_equals
import Base: eltype
import Multisets
import PNML: Coordinate, arctype, basis, elements, get_label, graphics, has_graphics, name,
    number_value, refid, sortdefinition, sortelements, sortref, tag, term, toolinfos, value,
    value_type, verify!, version

using ..Expressions
using ..PnmlTypes
using ..Sorts
using Base: @kwdef, isempty, length
using DocStringExtensions
using Logging
using LoggingExtras
using NamedTupleTools
using PNML
using PNML: AbstractLabel, AbstractPnmlNode, Annotation, AnyElement, BooleanConstant, D,
    HLAnnotation, Maybe, ToolParser, indent, namedsort, pntd

export ArcType, ArcTypeEnum, Condition, Declaration, Graphics, Inscription, Marking, Name,
    PnmlGraphics, PnmlLabel, Priority, Rate, SortType, Time, ToolInfo, ToolParser,
    delay_value, get_label, label_value, priority_value, rate_value, text

include("toolinfos.jl") # labels and nodes can both have tool specific information.
include("toolinfo_content.jl") # Some infos have known content.

include("PnmlGraphics.jl") # labels and nodes can both have graphics
using .PnmlGraphics

include("labels.jl")
include("declaration.jl")
include("name.jl")
include("sorttype.jl")
include("inscriptions.jl")
include("markings.jl")
include("conditions.jl")
include("arctypes.jl")
include("rates.jl")
include("delays.jl")
include("priorities.jl")
include("structure.jl")
include("times.jl")

"""
    label_value(n::AbstractPnmlNode, tag::Symbol, default_value)

If there is a label `tag` in `node.extralabels`, return its value,
else return a default value.
"""
function label_value(node::AbstractPnmlNode, tag::Symbol, default_value)
    label = get_label(node, tag)
    isnothing(label) ? default_value : value(label)
end
end # module labels
