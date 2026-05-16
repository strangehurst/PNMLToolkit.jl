module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
export      VariableDeclaration, UnknownDeclaration

export element_ids, verify_partition

using Base: isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using Logging, LoggingExtras

using PNML
using PNML: REFID, AnyElement, DotConstant, toexpr, indent, inc_indent
using PNML: namedsort, partitionsort

import PNML: sortref, sortdefinition, sortelements#, basis # Sort related
import PNML: name, pid, verify!

using ..Sorts
using ..Sorts: equalSorts
using ..IDRegistrys

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations
