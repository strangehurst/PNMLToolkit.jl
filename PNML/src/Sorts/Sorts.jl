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

import AutoHashEquals: @auto_hash_equals
import Base: eltype
import PNML: basis, inc_indent, indent, refid, sortdefinition, sortelements,
    sortref, unwrap_namedsort
import StructEquality: @struct_hash_equal

using Base: Fix2, length
using DocStringExtensions
using Logging
using LoggingExtras
using Moshi.Data: isa_variant, variant_type
using Moshi.Match: @match
using NamedTupleTools
using PNML
using PNML: AbstractSort, DotConstant, inc_indent, indent, is_multisetsort,
    is_namedsort, namedsort, productsort, to_sort

export AbstractSort, BoolSort, CyclicEnumerationSort, DotSort, EnumerationSort,
    FiniteEnumerationSort, FiniteIntRangeSort, IntegerSort, ListSort, MultisetSort,
    NaturalSort, NumberSort, PositiveSort, ProductSort, RealSort, StringSort, equalSorts,
    sorts

include("sorts.jl")
include("dots.jl")
include("enumerations.jl")
include("lists.jl")
include("numbers.jl")
include("strings.jl")

end # module Sorts
