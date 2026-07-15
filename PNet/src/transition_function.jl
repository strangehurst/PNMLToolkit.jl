"""
transition_function(petrinet::AbstractPetriNet) -> Vector{Pair{Symbol, Vector{Symbol}}

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions of the arc.

# keys are transition ids
# values are tuple of input, output labeled vectors,
# label is source or target place id - inscription (integer?)
"""
function transition_function end

transition_function(petrinet::AbstractPetriNet) = transition_function(pnmlnet(petrinet))
transition_function(@nospecialize(net::AbstractPnmlNet)) =
    [tid => in_out(net, tid) for tid in PNML.transition_idset(net)]

"""
    civ(net, arcid) -> inscription_value

Lookup the `Arc`, find its inscription's value.
#TODO add variables for full HL support
"""
function civ(@nospecialize(net::AbstractPnmlNet), arc_id::Symbol)
    a = PNML.arcdict(net)[arc_id]::Arc
    dot2int(pntd_of(net), inscription_value(net, a, NamedTuple()))
end

"""
    labeled_transitions((net::AbstractPnmlNet)) -> `(t_name=>t_rate)=>((input_states)=>(output_states))`

Iterates over transitions producing a pair for each tansition :=
    `Pair{Pair{Symbol,Number}, Pair{Tuple,Tuple}}`
where the Symbol is the transition ID, Number is the transition's rate value and
the Tuples are transition's input and out place IDs tupled with arc's inscription value.
"""
function labeled_transitions end
labeled_transitions(petrinet::AbstractPetriNet) = labeled_transitions(pnmlnet(petrinet))
function labeled_transitions(@nospecialize(net::AbstractPnmlNet))
    Iterators.map(PNML.transitions(net)) do tr # states are places
        # tuple of tuple place id, arc inscription value as integer
        ins = tuple(zip(PNML.preset(net, pid(tr)),
                   Iterators.map(arcid -> civ(net, arcid), PNML.tgt_arcs(net, pid(tr)))))
        outs = tuple(zip(PNML.postset(net, pid(tr)),
                    Iterators.map(arcid -> civ(net, arcid), PNML.src_arcs(net, pid(tr)))))
        Pair(pid(tr)=>PNML.rate_value(tr), ins=>outs)
    end
end
"""
    counted_transitions(net) -> Pair(pid(tr)=>(in_counts=>out_counts))

Iterates over transitions producing a pair for each tansition :=
    of a pair of tuples of inscription values for preset, postset arcs.
Useful for petri net meta-models that need special handling to expand when inscription > 1.
"""
function counted_transitions end
counted_transitions(petrinet::AbstractPetriNet) = counted_transitions(pnmlnet(petrinet))
function counted_transitions(net::AbstractPnmlNet)
    Iterators.map(PNML.transitions(net)) do tr
        in_counts = tuple(map(arcid  -> civ(net, arcid), PNML.tgt_arcs(net, pid(tr))))
        out_counts = tuple(map(arcid -> civ(net, arcid), PNML.src_arcs(net, pid(tr))))
        pid(tr)=>(in_counts=>out_counts)
    end
end

"""
$(TYPEDSIGNATURES)

Return tuple of input, output tuples of place ids, arc inscription's value.
For use in a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end
function in_out(petrinet::AbstractPetriNet, transition_id)
    in_out(pnmlnet(petrinet), transition_id)
end
function in_out(net::AbstractPnmlNet, transition_id)
    (in_inscriptions(net, transition_id),
    out_inscriptions(net, transition_id))
end

# """
#     ins(net, transition_id) -> LVector

# Inscription values labeled with source place id for arcs with `transition_id` as the target id.
# """
# ins(net::AbstractPnmlNet, transition_id::Symbol) = LVector((; collect(in_inscriptions(net, transition_id))...))

# """
#     outs(net, transition_id) -> LVector

# Inscription values labeled with target place id for arcs with `transition_id` as the source id.
# """
# outs(net::AbstractPnmlNet, transition_id::Symbol) = LVector((; collect(out_inscriptions(net, transition_id))...))

#
# See input flow #todo cite ISO 15909-1:2019
"""
    in_inscriptions(net, transitionid) -> Iterator

Iterate over preset of transition, returning source place id => inscription value pairs.
"""
function in_inscriptions(net::AbstractPnmlNet, transitionid)
    Iterators.map(PNML.preset(net, transitionid)) do placeid
        a = PNML.arc(net, placeid, transitionid)::Union{Arc, Nothing}
        isnothing(a) &&
            error("did not locate in arc $placeid -> $transitionid $placeid")
        PNML.source(a) => PNML.inscription(a)(NamedTuple())
    end
end

# See output flow #todo cite  ISO 15909-1:2019
"""
    out_inscriptions(net, transitionid) -> Iterator

Iterate over postset of transition, returning target place id => inscription value pairs.
"""
function out_inscriptions(net::AbstractPnmlNet, transitionid)
    Iterators.map(PNML.postset(net, transitionid)) do placeid
        a = PNML.arc(net, transitionid, placeid)::Union{Arc, Nothing}
        isnothing(a) &&
            error("did not locate out arc $transitionid -> $placeid")
        PNML.target(a) => PNML.inscription(a)(NamedTuple())
    end
end

#! FROM AlgebraicPetri.jl uses whole grained petri nets
"""
    TransitionMatrices

This data structure stores the transition matrix of an Petri net object.
This is primarily used for constructing the vectorfield representation of the
Petri net.

These are matrices of inscription `value_type`
"""
struct TransitionMatrices{T<:Number} #Int except for ContinuousNet where it is Float64
    input::Matrix{T}
    output::Matrix{T}
end
function TransitionMatrices(p::AbstractPnmlNet)
    input  = input_matrix(p)
    output = output_matrix(p)
    TransitionMatrices(input, output)
end
