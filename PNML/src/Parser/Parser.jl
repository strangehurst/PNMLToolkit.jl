"""
Parser module of PNML.

See [`LabelParser`](@ref), (`ToolParser`)(@ref).
"""
module Parser
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import EzXML
import XMLDict
import Multisets: Multisets, Multiset

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras
using Moshi.Data: @data, isa_variant, is_data_type
using Moshi.Match: @match
using SciMLLogging: @SciMLMessage
using SciMLPublic: @public

using PNML
using ..Expressions
using ..IDRegistrys
using ..PnmlTypes
using ..Labels
using ..Labels: validate_toolinfos
using ..Sorts
using ..Sorts: make_sortref, equalSorts
using ..Declarations

using PNML: Maybe, CONFIG, AnyElement, PnmlLabel, D, registry_of, verify
using PNML: Graphics, Coordinate, coordinate_type, elements
using PNML: ToolInfo, XmlDictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys, decldict
using PNML: PartitionElement, PnmlMultiset, BooleanConstant, pnmlmultiset
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: FEConstant, feconstants, has_feconstant
using PNML: pid, fill_builtin_labelparsers!, fill_builtin_sorts!, fill_builtin_toolparsers!
using PNML: ToolParser, LabelParser, NamedSort, Operator
using PNML: fill_sort_tag!, fill_builtin_enabled_filters!
using PNML: namedsort, multisetsort, partitionsort, productsort, variabledecl, variabledecls
using PNML: namedoperators, operator
using PNML: has_namedsort, has_multisetsort, has_partitionsort, has_productsort, has_arbitrarysort
using PNML: namedsorts, multisetsorts, partitionsorts, productsorts, arbitrarysorts
using PNML: pagedict, placedict, transitiondict, arcdict, refplacedict, reftransitiondict
using PNML: page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset
using PNML: netsets, toolinfos, value_type, number_value
using PNML: NamedSortRef, PartitionSortRef, ProductSortRef, MultisetSortRef, ArbitrarySortRef
using PNML: to_sort
using PNML: PnmlException, MissingIDException, DuplicateIDException, MalformedException
using PNML: is_usersort, is_namedsort, is_partitionsort, is_productsort, is_multisetsort, is_arbitrarysort
using PNML: is_normal, is_inhibitor, is_read, is_reset
using PNML: has_place, place, pntd

# Methods implemented in this module.
import PNML: adjacent_place
import PNML: basis, sortref, sortelements, sortdefinition
import PNML: refid, netdata, tag, verify!

include("xmlutils.jl")
include("parseutils.jl")
include("anyelement.jl")
include("model.jl")
include("nodes.jl")
include("labels.jl")
include("extra_labels.jl")
include("graphics.jl")
include("declarations.jl")
include("terms.jl")
include("toolspecific.jl")

export XMLNode, xmlnode, @xml_str
export pnmlmodel

end
