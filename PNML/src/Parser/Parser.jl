"""
Parser module of PNML.

Exports: [`@xml_str`(@ref)], [`XMLNode`](@ref), [`pnmlmodel`](@ref), [`xmlnode`](@ref).

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
using ..Sorts: equalSorts, make_sortref, sorts
using ..PnmlGraphics
using Base: isempty, length
using DocStringExtensions
using Logging
using LoggingExtras
using Moshi.Data: @data, is_data_type, isa_variant
using Moshi.Match: @match
using NamedTupleTools
using PNML
using PNML: AnyElement, BooleanConstant, CONFIG, Coordinate, D, DeclDict,
    FEConstant, MalformedException, Maybe, MissingIDException, PnmlNetData, PnmlNetKeys,
    XmlDictType, arbitrarysorts, arc_idset, arcdict, basis, coordinate_type, feconstants,
    fill_builtin_enabled_filters!, fill_builtin_labelparsers!, fill_builtin_sorts!,
    fill_builtin_toolparsers!, fill_sort_tag!, has_arbitrarysort, has_feconstant,
    has_multisetsort, has_namedsort, has_partitionsort, has_place, has_productsort,
    is_arbitrarysort, is_inhibitor, is_multisetsort, is_namedsort, is_normal,
    is_partitionsort, is_productsort, is_read, is_reset, is_usersort, multisetsorts,
    namedoperators, namedsorts, netsets, number_value, operator, page_idset, pagedict,
    partitionsorts, pid, place, place_idset, placedict, pntd, productsorts,
    refplace_idset, refplace_idset, refplacedict, reftransition_idset, reftransitiondict,
    registry_of, to_sort, toolinfos, transition_idset, transitiondict, value_type,
    variabledecl, variabledecls, verify

using SciMLPublic: @public
using TermInterface

export @xml_str, XMLNode, pnmlmodel, xmlnode

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

end
