"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See [`SortType`](@ref PNML.Labels.SortType).

NamedSort is a _SortDecl_ (SortDeclaration) that gives a name and id to a _Sort_.

The pnml standard sometimes uses overlapping language. And explains little, expecting one
to be knowledgeable about colored petri nets.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations,
products, dots and partitions.

And more sorts for HLPNG: integer, strings, list

With additions we made: real.

Oh, also ArbitrarySorts.

#! XXX The `eltype` is expected to be a
concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
  - `NamedSort` is a Declarations.SortDeclaration
  - `HLPNG` adds `ArbitrarySort`.
  - `PartitionSort` is called "Partition" in the standard.
  - `SortRef` holds the id symbol of a concrete sort.
  - We use sorts even for non-high-level nets.
  - Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
module Sorts

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using Moshi.Match: @match
using Moshi.Data: isa_variant, variant_type
using SciMLLogging: @SciMLMessage

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets: Multisets, Multiset

using PNML
using PNML: DeclDict, multisetsorts, find_valuekey, to_sort, DotConstant
using PNML: AbstractSort, namedsort, namedsorts, productsort, productsorts
using PNML: is_normal, is_inhibitor, is_read, is_reset, indent, inc_indent
using PNML: is_usersort, is_namedsort, is_partitionsort, is_productsort
using PNML: is_multisetsort, is_arbitrarysort

import PNML: sortref, sortelements, sortdefinition, basis
import PNML: value, term, tag, pid, refid
import PNML: fill_sort_tag!, unwrap_namedsort, indent, inc_indent

export AbstractSort, MultisetSort, ProductSort
export DotSort, BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
export EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
export ListSort, StringSort
export make_sortref, equalSorts

include("sorts.jl")
include("dots.jl")
include("enumerations.jl")
include("lists.jl")
include("numbers.jl")
include("strings.jl")

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

end # module Sorts
