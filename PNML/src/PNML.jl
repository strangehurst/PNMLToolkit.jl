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

import AutoHashEquals: @auto_hash_equals
import Base: *, +, -, <, <=, >, >=, eltype, iterate, keys, length, zero
import DataStructures
import ExproniconLite
import EzXML
import FunctionWrappers
import Graphs
import MacroTools
import MetaGraphsNext
import Metatheory
import Moshi
import Moshi.Data: @data, is_data_type, isa_variant, variant_type
import Moshi.Derive: @derive
import Moshi.Match: @match
import Multisets: Multisets, Multiset
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import SciMLPublic: @public
import XMLDict

using Accessors
using Base: @kwdef, Fix1, Fix2, RefValue, isempty, length
using DocStringExtensions
using EnumX: @enumx
using ExproniconLite: JLCall, JLExpr, JLField, JLFor, JLFunction, JLIfElse, JLKwField,
    JLKwStruct, JLStruct, xcall, xfirst, xgetindex, xiterate, xlast, xmap, xmapreduce,
    xnamedtuple, xprint, xprintln, xpush, xtuple
using Graphs: Edge, SimpleDiGraphFromIterator
using Logging
using LoggingExtras
using MetaGraphsNext: MetaGraph
using NamedTupleTools
using Preferences: load_preference, set_preferences!
using TermInterface

export @xml_str, APN, AbstractPnmlNet, ArbitrarySortRef, Arc, ArcTypeEnum, D,
    MultisetSortRef, NamedSortRef, Page, PartitionSortRef, Place, PnmlModel, PnmlNet,
    ProductSortRef, REFID, RefPlace, RefTransition, SortRef, SortRefImpl,
    Transition, UserSortRef, pnmlmodel, xmlnode

@public PnmlException, MissingIDException, DuplicateIDException, MalformedException
@public namedsort, productsort, Coordinate
@public basis, name, rates, mcontains, to_sort
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

include("PnmlTypes.jl")
using .PnmlTypes
include("IDRegistrys.jl")
using .IDRegistrys

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/coordinates.jl")
include("Core/anyelement.jl") # AnyElement, XmlDictType,
include("Core/interfaces.jl") # Function docstrings mostly.
include("Core/types.jl") # Abstract Types with docstrings.
include("Core/sortref.jl")
include("Core/toolparser.jl")
include("Core/labelparser.jl")
include("Core/decldictcore.jl") # define structure filled by Sorts, Declarations
include("Core/constterm.jl")

include("Sorts/Sorts.jl") # used in Variables, Operators, Places
using .Sorts
include("Declarations/Declarations.jl")
using .Declarations
include("Core/parse_context.jl") # parse context has id registry and DeclDict
include("Core/multisets.jl")
include("Core/variables.jl")
include("Core/expressions.jl")
using .Expressions
include("Core/operators.jl")
include("Core/rewrite.jl")
include("Core/pnmlnetkeys.jl") # Used by page, net; who owns what.

#^ Above here are things that appear in  DeclDict contents.
include("Core/decldict.jl") # Just contains show(). See decldictcore.jl.
include("Labels/Labels.jl")
using .Labels
include("Core/places.jl")
include("Core/transitions.jl")
include("Core/arcs.jl")
include("Core/page.jl")
include("Core/net.jl") # PnmlNet holds pages
include("Core/model.jl") # Holds multiple PnmlNets.
include("Core/flatten.jl") # Flatten pages of PnmlNet
include("NetAPI/NetAPI.jl") # API for Petri nets, graphs, et al.
using .NetAPI
include("Core/enable_filters.jl")
include("Parser/Parser.jl")
using .Parser

include("precompile.jl")

end # module PNML
