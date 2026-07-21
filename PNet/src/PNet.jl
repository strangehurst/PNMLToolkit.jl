"""
"""
module PNet
__precompile__(true)

#using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
#import AutoHashEquals: @auto_hash_equals
import Graphs
import MetaGraphsNext
import Multisets: Multisets, Multiset
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import PNML
import PNML: AbstractPnmlMultiset, PnmlMultiset,
    conditions, initial_markings, inscriptions, nettype, pid,
    pnmlmodel, pntd_of, rates

#!import PNML.NetAPI: inscriptions
import StructEquality: @struct_hash_equal
import XMLDict

using DocStringExtensions
using Logging
using LoggingExtras
using Memoization
using NamedTupleTools
using PNML
using PNML: dot2int, input_matrix, inscription, inscription_value, inscriptions, output_matrix
#!using PNML.NetAPI #! Move to here
using PNML.Parser
using PNML.PnmlTypes
using TermInterface
using Graphs: Edge, SimpleDiGraphFromIterator
using MetaGraphsNext: MetaGraph

export AbstractPetriNet, SimpleNet, counted_transitions,
    labeled_transitions, pnmlnet, transition_function

public conditions, fire, fire2,
    metagraph,
    rates


#include("NetAPI/enabling_rule.jl")
include("NetAPI/firing_rule.jl")
include("NetAPI/metagraph.jl")

include("petrinet.jl")
include("transition_function.jl")
include("firing_rule.jl")

end # module PNet
