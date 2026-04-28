module Labels

export Inscription, Marking, Condition
export Name, PnmlLabel, SortType, Declaration
export HLLabel
export Graphics, PnmlGraphics
export ToolInfo
export text, get_label, label_value, rate_value, priority_value, delay_value
export def_sort_element
export ToolParser
export ArcType, ArcTypeEnum
export Rate, Priority, Time
export validate_toolinfos, variables

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage
using Moshi.Data: @data, isa_variant, is_data_type

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet

using PNML
using PNML: Maybe, AnyElement, D, indent, inc_indent, pntd
using PNML: AbstractPnmlNode, AbstractLabel, Annotation, HLAnnotation
using PNML: DeclDict
using PNML: BooleanConstant, PnmlMultiset
using PNML: namedsort
using PNML: ToolParser

import PNML: name, Coordinate
import PNML: value_type, number_value
import PNML: value, term, graphics, toolinfos, refid, tag, elements
import PNML: has_graphics, get_label, labels, declarations
import PNML:  arctype, is_normal, is_inhibitor, is_read, is_reset, verify!

using ..PnmlTypes # PNML PNTD

using ..Expressions
import ..Expressions: toexpr, PnmlExpr, expr_sortref

using ..Sorts
# Some labels implement the Sort interface
import PNML: basis, sortref, sortelements, sortdefinition, version

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
