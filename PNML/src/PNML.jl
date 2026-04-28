"""
[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.

What is accepted as values is ~~often~~ a superset of what a given pntd schema specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

The pnml standard has layers. This package has layers: `PnmlNet`, `AbstractPetriNet`

The core layer is useful and extendable. The standard defines extensions of the core,
called meta-models, for
  - place-transition petri nets (integers) and
  - high-level petri net graphs (many-sorted algebra).
This package family adds non-standard continuous net (float64) support.
Note that there is not yet any RelaxNG schema for our extensions.

On top of the concrete `PnmlNet` of the IR are net adaptions and interpertations.
This is the level that Petri Net conformance can be imposed.
It is also where other Net constructs can be defined over `PnmlNet`s. Perhaps as new meta-models.
"""
module PNML
__precompile__(true)

using Accessors
using Preferences: load_preference, set_preferences!
import AutoHashEquals: @auto_hash_equals
import Base: eltype, keys, *, +, -, <, >,>=, <=, zero, length, iterate
import FunctionWrappers
import Graphs
import MetaGraphsNext
import MacroTools
import DataStructures
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import EzXML
import XMLDict
import Multisets: Multisets, Multiset
import Moshi
import Moshi.Match: @match
import Moshi.Data: @data, isa_variant, is_data_type, variant_type
import Moshi.Derive: @derive
import SciMLPublic: @public
import Metatheory
import ExproniconLite

#= ExproniconLite_exports = NoDefault,
    JLCall, JLExpr, JLFor, JLIfElse, JLFunction, JLField, JLKwField, JLStruct, JLKwStruct,
    @expr, @test_expr, compare_expr, AnalysisError, SyntaxError,
    is_function, is_kw_function, is_struct, is_tuple, is_splat, is_ifelse, is_for,
    is_field, is_field_default, is_datatype_expr, is_matrix_expr,
    split_function, split_function_head, split_anonymous_function_head,
    split_struct, split_struct_name, split_ifelse, split_signature,
    arg2type, uninferrable_typevars, has_symbol,
    is_literal, is_gensym,
    alias_gensym, has_kwfn_constructor, has_plain_constructor,
    guess_type, guess_module, guess_value, Substitute, no_default,
    prettify, rm_lineinfo, flatten_blocks, name_only, annotations_only,
    rm_annotations, rm_single_block, rm_nothing, substitute,
    eval_interp, eval_literal, renumber_gensym, expr_map, nexprs,
    codegen_ast, codegen_ast_kwfn, codegen_ast_kwfn_plain, codegen_ast_kwfn_infer,
    codegen_ast_struct, codegen_ast_struct_head, codegen_ast_struct_body,
    struct_name_plain, struct_name_without_inferable,
    xtuple, xnamedtuple, xcall, xpush, xgetindex, xfirst, xlast,
    xprint, xprintln, xmap, xmapreduce, xiterate,
    print_inline, print_expr, sprint_expr
=#
using ExproniconLite: JLCall, JLExpr, JLFor, JLIfElse, JLFunction,
                      JLField, JLKwField, JLStruct, JLKwStruct
using ExproniconLite: xtuple, xnamedtuple, xcall, xpush, xgetindex, xfirst, xlast,
                      xprint, xprintln, xmap, xmapreduce, xiterate

using Logging
using LoggingExtras
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using TermInterface
using Graphs: SimpleDiGraphFromIterator, Edge
using MetaGraphsNext: MetaGraph
using NamedTupleTools
using DocStringExtensions
using EnumX: @enumx

# EXPORTS

export PnmlModel, APN, PnmlNet, Page
export Place, RefPlace, Transition, RefTransition, Arc
export REFID, SortRefImpl, SortRef, ArcTypeEnum
export UserSortRef # From SortRefImpl ADT
export NamedSortRef, ProductSortRef, PartitionSortRef, MultisetSortRef, ArbitrarySortRef
export decldict
export @xml_str, xmlnode, D

@public pnmlmodel
@public PnmlException, MissingIDException, DuplicateIDException, MalformedException
@public namedsort, Coordinate
@public rates, mcontains, to_sort
@public is_usersort, is_namedsort, is_partitionsort, is_productsort, is_multisetsort, is_arbitrarysort

Multisets.set_key_value_show()

include("config.jl")
include("preferences.jl") # read_config!, save_config, show
__init__() = read_config!()

D() = CONFIG.verbose # Guard for bring-up/debug noise.

# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

#include("logging.jl") # SciMLLogging based: `silent`, `verbose`, `logger_for_pnml`

include("PnmlTypes.jl")
using .PnmlTypes
import .PnmlTypes: is_discrete, is_continuous, is_highlevel,
                   is_collective_token, is_individual_token

include("IDRegistrys.jl")
using .IDRegistrys

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/coordinates.jl")

include("context.jl")

include("Core/interfaces.jl") # Function docstrings mostly.
include("Core/anyelement.jl") # AnyElement, XmlDictType, XDVT
include("Core/types.jl") # Abstract Types with docstrings.
include("Core/sortref.jl")

include("Core/toolparser.jl")
include("Core/labelparser.jl")

# Parts of Labels and Nodes.

include("Core/decldictcore.jl") # define structure filled by Sorts, Declarations
include("terms/constterm.jl")

include("Sorts/Sorts.jl") # used in Variables, Operators, Places
using .Sorts
using .Sorts: MultisetSort
using .Sorts: AbstractSort, MultisetSort, ProductSort
using .Sorts: DotSort, BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
using .Sorts: EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
using .Sorts: ListSort, StringSort


include("Declarations/Declarations.jl")
using .Declarations
using .Declarations: SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
using .Declarations: OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
using .Declarations: VariableDeclaration

# include("Core/decldictcore.jl") # define structure filled by Sorts, Declarations
include("Core/parse_context.jl") # parse context has id registry and DeclDict

include("terms/multisets.jl")
include("terms/variables.jl")

include("terms/expressions.jl")
using .Expressions
#!using .Expressions: toexpr, PnmlExpr, AbstractBoolExpr, AbstractOpExpr

include("terms/operators.jl")

include("terms/terms.jl") # Variables and AbstractOperators preceed this.
include("Core/rewrite.jl")

include("Core/pnmlnetdata.jl") # Used by page, net; holds places, transitions, arcs.

#^ Above here are things that appear in  DeclDict contents.
#^ 2024-07-17 Changed DeclDict to be Any based,
#^ with the hope that the accessor methods provide type inferrability.
include("Core/decldict.jl") # Just contains show(). See decldictcore.jl.

# Labels
include("Labels/Labels.jl")
using .Labels

# Nodes #TODO make into a module?
include("nodes/nodes.jl") # Concrete place, transition, arc.
include("nodes/page.jl") # Contains nodes.
include("nodes/net.jl") # PnmlNet holds pages
include("nodes/model.jl") # Holds multiple PnmlNets.
include("nodes/flatten.jl") # Flatten pages of PnmlNet

include("NetAPI/netutils.jl") # API for Petri nets, graphs, et al.
include("NetAPI/enable_filters.jl")
include("NetAPI/enabling_rule.jl")
include("NetAPI/firing_rule.jl")
include("NetAPI/metagraph.jl")

# PARSE
include("Parser/Parser.jl")
using .Parser

# API Facade:
#! 2026-01-12 Split PNet into a package
#! include("PNet/PNet.jl")
#! using .PNet

include("precompile.jl")

end # module PNML
