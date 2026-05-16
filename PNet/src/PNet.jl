module PNet
__precompile__(true)

#using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
import Multisets: Multisets, Multiset
import OrderedCollections: LittleDict, OrderedDict, OrderedSet, freeze
import PNML
import PNML: PnmlModel, PnmlMultiset, PnmlNet,
    initial_marking, initial_markings, metagraph, nettype, pid,
    pnmlmodel, pntd, rates
import XMLDict

using DocStringExtensions
using Logging
using LoggingExtras
using NamedTupleTools
using PNML.Declarations
using PNML.Labels
using PNML.NetAPI
using PNML.PnmlGraphics
using PNML.PnmlTypes
using PNML.Sorts
using TermInterface

export AbstractPetriNet, SimpleNet
export input_matrix, output_matrix, transition_function, pnmlnet
export labeled_transitions, counted_transitions

include("petrinet.jl")
include("transition_function.jl")
include("firing_rule.jl")

end # module PNet
