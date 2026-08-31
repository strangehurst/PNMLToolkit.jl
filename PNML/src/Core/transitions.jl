"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Transition{N <: AbstractPnmlNet, T <: PnmlExpr}  <: AbstractPnmlNode
    id::Symbol
    condition::Labels.Condition{N, T} #! booleran expression label
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

"""
    condition(::Transition) -> Condition

Return condition label.
"""
condition(transition::Transition) = transition.condition

function Base.show(io::IO, trans::Transition)
    print(io, nameof(typeof(trans)), "(", repr(pid(trans)), ", ", repr(name(trans)), ", ")
    show(io, term(condition(trans)))
    print(io, ")")
end

function verify!(errors, t::Transition, verbose::Bool , net::AbstractPnmlNet)
    verbose && println("## verify Transition $(pid(t))")
    !isregistered(registry_of(net), pid(t)) &&
        push!(errors, string("transition ", repr(pid(t)), " not registered")::String)

    # TODO more verify transition

     return errors
end

"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition{N <: AbstractPnmlNet} <: ReferenceNode
    id::Symbol
    ref::Symbol # Transition or RefTransition IDREF
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, nameof(typeof(r)), "(", repr(pid(r)), ",  ", repr(refid_of(r)), ")")
end
function verify!(errors, r::ReferenceNode, verbose::Bool , net::AbstractPnmlNet)
    verbose && println("## verify $(typeof(r)) $(pid(r))")
    !isregistered(registry_of(net), pid(r)) &&
        push!(errors, string("arc ", repr(pid(r)), " not registered")::String)

    # TODO verify ReferenceNode

     return errors
end
