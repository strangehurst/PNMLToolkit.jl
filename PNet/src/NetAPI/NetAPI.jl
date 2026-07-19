"""
    NetAPI
"""
module NetAPI
import AutoHashEquals: @auto_hash_equals
import Graphs
import Multisets: Multiset, Multisets
import OrderedCollections
import PNML: varsubs
import StructEquality: @struct_hash_equal

using Base: Fix2, length
using DocStringExtensions
using Graphs: Edge, SimpleDiGraphFromIterator
using Logging
using LoggingExtras
using Memoization
using MetaGraphsNext: MetaGraph
using Moshi.Data: isa_variant, variant_type
using Moshi.Match: @match
using NamedTupleTools
using OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
using PNML
using PNML: APNTD, AbstractHLCore, AbstractPnmlNet, AbstractPNTD, Arc, Inscription,
    Marking, Maybe, PT_HLPNG, Place, PnmlMultiset, arc, arcdict, arcs, cardinality,
    condition, filters, initial_marking, inscription,
    is_collective_token, is_productsort, multiset, narcs, nets, nplaces, ntransitions,
    pid, place, place_idset, places, pntd_of, rate_value, refid, sortref,
    source, src_arcs, target, term,
    tgt_arcs, toexpr, transition, transition_idset, transitiondict, transitions,
    value_type, variabledecl, zero_marking
using PNML.Declarations
using PNML.PnmlGraphics
using PNML.Sorts

export conditions, dot2int, enabled, fire, fire2, incidence_matrix, initial_markings, input_matrix,
    inscription_value, inscriptions, metagraph, output_matrix, post, postset, pre, preset,
    rates

include("netutils.jl")
include("enabling_rule.jl")
include("firing_rule.jl")
include("metagraph.jl")

end # module NetAPI
