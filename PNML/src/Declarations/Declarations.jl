module Declarations
#import AutoHashEquals: @auto_hash_equals
import Base: eltype
import PNML: name, pid, sortdefinition, sortelements, sortref, verify!
import StructEquality: @struct_hash_equal

using ..IDRegistrys
using ..Sorts
using Base: isempty, length
using DocStringExtensions
using Logging
using LoggingExtras
using Memoization
using PNML
using PNML: AnyElement, DotConstant, REFID, inc_indent, indent, namedsort,
    partitionsort, toexpr

export AbstractDeclaration, ArbitraryOperator, ArbitrarySort, NamedOperator, NamedSort,
    OperatorDeclaration, PartitionElement, PartitionSort, SortDeclaration,
    UnknownDeclaration, VariableDeclaration, element_ids, verify_partition

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations
