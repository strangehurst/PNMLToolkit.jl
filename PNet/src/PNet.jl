"""
"""
module PNet
__precompile__(true)

#using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
import Multisets: Multisets, Multiset
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import PNML
import PNML: PnmlMultiset,
    initial_marking, initial_markings, inscription, metagraph, nettype, pid,
    pnmlmodel, pntd_of, rates
import PNML.NetAPI: inscriptions, conditions
import XMLDict

using DocStringExtensions
using Logging
using LoggingExtras
using NamedTupleTools
using PNML
using PNML.NetAPI
using PNML.Parser
using PNML.PnmlTypes #!: AbstractPNTD, AbstractPNTD
using TermInterface

export AbstractPetriNet, SimpleNet, counted_transitions, input_matrix,
    labeled_transitions, output_matrix, pnmlnet, transition_function

include("petrinet.jl")
include("transition_function.jl")
include("firing_rule.jl")

end # module PNet
