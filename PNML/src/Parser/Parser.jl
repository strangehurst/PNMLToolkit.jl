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
using ..Sorts: equalSorts, sorts
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
    XmlDictType, arbitrarysorts, arc_idset, arcdict, basis, coordinate_type,
    decldict, feconstants,
    fill_builtin_enabled_filters!, fill_builtin_labelparsers!, fill_builtin_sorts!,
    fill_builtin_toolparsers!, fill_sort_tag!, has_arbitrarysort,
    has_feconstant, has_multisetsort, has_namedsort, has_partitionsort, has_place,
    has_productsort, is_arbitrarysort, is_inhibitor, is_multisetsort,
    is_namedsort, is_normal,
    is_partitionsort, is_productsort, is_read, is_reset, is_usersort, multisetsorts,
    namedoperators, namedsorts, netsets, number_value, operator, page_idset, pagedict,
    partitionsorts, pid, place, place_idset, placedict, pntd_of, productsorts,
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

"""
    make_sortref(net, dict, sort, seed, sort_id, name) ->  SortRef`

 - `dict` is a method/callable that returns an AbstractDict attached to `net`.
 - `sort` ia a concrete sort that is to be in `dict`.
 - `seed` is passed to `gensym` if `sort_id` is `nothing` and no `sort` is already in `dict`.
 - `sort_id` is a `Symbol` and the string `name` are `nothing` and ""
    unless there is a wrapper providing such information,

Uses `fill_sort_tag!`.

Return concrete SortRef matching `dict`, wrapping `id`.
"""
function make_sortref(net, dict, sort, seed, sort_id, name=nothing)
    #println("\n## make_sortref $(pid(net)) $dict $sort $(repr(sort_id)) '$name'")
    # See if there is an existing `sort` in `dict`
    if isnothing(sort_id) # No provided id, if no existing sort found, invent an id.
        if isnothing(find_valuekey(dict(net), sort))
            sort_id = gensym(seed) # so invent one.
        end
    end
    # fill_sort_tag! will not overwrite existing
    return fill_sort_tag!(net, sort_id, sort, dict)::SortRef # in make_sortref
end

"Look for matching value `x` in dictionary `d`, return key symbol or nothing."
function find_valuekey(d::AbstractDict, x, func=identity)
    id = nothing
    for (k,v) in pairs(skipmissing(d))
        if func(v) == x # Apply `func` to each value, looking for a match.
            id = k
            @warn("found existing $id for $x")
            break
        end
    end
    return id #  Key of matched value or nothing.
end

end
