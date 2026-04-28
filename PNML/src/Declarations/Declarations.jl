module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
export      VariableDeclaration, UnknownDeclaration

export element_ids, verify_partition

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage

using PNML
using PNML: REFID, AnyElement, DotConstant, toexpr, indent, inc_indent
using PNML: namedsort, partitionsort
#using PNML: arbitraryop,  multisetsort
#using PNML: is_usersort, is_namedsort, is_partitionsort, is_productsort
#using PNML: is_multisetsort, is_arbitrarysort, indent, inc_indent
#using PNML: PnmlException, MissingIDException, DuplicateIDException, MalformedException

import PNML: sortref, sortdefinition, sortelements#, basis # Sort related
import PNML: name, pid, verify!

using ..Sorts
using ..Sorts: equalSorts
using ..IDRegistrys

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations
