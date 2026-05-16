"""
Parser module of PNML.

See [`LabelParser`](@ref), (`ToolParser`)(@ref).
"""
module Parser
import AutoHashEquals: @auto_hash_equals
import Base: eltype
import EzXML
import Multisets: Multisets, Multiset
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import PNML: adjacent_place, netdata, refid, sortdefinition, sortelements, sortref, tag, verify!
import XMLDict

using ..Declarations
using ..Expressions
using ..IDRegistrys
using ..Labels
using ..Labels: validate_toolinfos
using ..PnmlTypes
using ..Sorts
using ..Sorts: equalSorts, make_sortref
using Base: isempty, length
using DocStringExtensions
using Logging
using LoggingExtras
using Moshi.Data: @data, is_data_type, isa_variant
using Moshi.Match: @match
using NamedTupleTools
using PNML
using PNML: AbstractPnmlNet, AnyElement, ArbitrarySortRef, BooleanConstant, CONFIG,
    Coordinate, D, DeclDict, DuplicateIDException, FEConstant, Graphics, LabelParser,
    MalformedException, Maybe, MissingIDException, MultisetSortRef, NamedSort, NamedSortRef,
    Operator, PartitionElement, PartitionSortRef, PnmlException, PnmlLabel, PnmlMultiset,
    PnmlNetData, PnmlNetKeys, ProductSortRef, ToolInfo, ToolParser, UserOperator,
    XmlDictType, arbitrarysorts, arc_idset, arcdict, arctype, basis, coordinate_type,
    decldict, elements, feconstants, fill_builtin_enabled_filters!,
    fill_builtin_labelparsers!, fill_builtin_sorts!, fill_builtin_toolparsers!,
    fill_sort_tag!, has_arbitrarysort, has_feconstant, has_multisetsort, has_namedsort,
    has_partitionsort, has_place, has_productsort, is_arbitrarysort, is_inhibitor,
    is_multisetsort, is_namedsort, is_normal, is_partitionsort, is_productsort, is_read,
    is_reset, is_usersort, multisetsort, multisetsorts, namedoperators, namedsort,
    namedsorts, netsets, number_value, operator, page_idset, pagedict, partitionsort,
    partitionsorts, pid, place, place_idset, placedict, pnmlmultiset, pntd, productsort,
    productsorts, refplace_idset, refplacedict, reftransition_idset, reftransitiondict,
    registry_of, to_sort, toolinfos, transition_idset, transitiondict, value_type,
    variabledecl, variabledecls, verify
using SciMLPublic: @public
using TermInterface

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
