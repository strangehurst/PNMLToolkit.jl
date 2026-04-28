"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.

Each place has an initial marking that has a basis matching sorttype.
M is a "multiset sort denoting a collection of tokens".
A "multiset sort over a basis sort is interpreted as
"the set of multisets over the type associated with the basis sort".
"""
@kwdef mutable struct Place{N <: APN}  <: AbstractPnmlNode
    id::Symbol
    initialMarking::Marking{N} # Expression as value. Used to create marking vector.

    # For each place, a sort defines the type of the marking tokens of the place (sorttype).
    # The inscription of an arc to or from a place defines which tokens are added or removed
    # when the corresponding transition fires. These tokens must also be of sorttype.
    sorttype::SortType{N}
    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = nothing
    net::N
end

initial_marking(place::Place) = (place.initialMarking)()
net(place::Place) = place.net
sortref(place::Place) = sortref(place.sorttype)::SortRef

"""
Return zero-valued object with same `basis` and `eltype` as place's marking.

Used in enabling and firing rules to deduce type of `Arc`'s `adjacent_place`.
"""
zero_marking(place::Place) = 0 * initial_marking(place)

function Base.show(io::IO, place::Place)
    print(io, nameof(typeof(place)), "(")
    show(io, pid(place)); print(io, ", ")
    show(io, name(place)); print(io, ", ")
    show(io, place.sorttype); print(io, ", ")
    show(io, term(place.initialMarking)) #initial_marking(place));
    print(io, ")")
end

function verify!(errors, p::Place, verbose::Bool , net::APN)
    verbose && println("## verify Place{$(sortref(p))} $(pid(p))")
    !isregistered(registry_of(net), pid(p)) &&
        push!(errors, string("place ", repr(pid(p)), " not registered")::String)

    # TODO more verify place

     return errors
end

#----------------------------------------------------------------------------
#----------------------------------------------------------------------------
#----------------------------------------------------------------------------

    # Use <fifoinitialMarking><structure><makelist> expression for initial queue contents.
    # DataStructures.Queue{sorttype} will be an element in the marking vector.
    #? Do we segregate  FIFO from HL markings by a new xml tag?

#----------------------------------------------------------------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Transition{N <: APN}  <: AbstractPnmlNode
    id::Symbol
    condition::Labels.Condition{N} #! booleran expression label
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}

    vars::Set{REFID}
    "Cache of variable substitutons for this transition"
    varsubs::Vector{NamedTuple}
    net::N
end

"""
    varsubs(transition) -> Vector{NamedTuple}

Access the variable substitutions of a transition.

Variable substitutions depend on the current marking.
Cache value in transition field as part of enabling rule phase of a Petri net lifecycle.
"""
function varsubs end

varsubs(transition::Transition) = transition.varsubs

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

function verify!(errors, t::Transition, verbose::Bool , net::APN)
    verbose && println("## verify Transition $(pid(t))")
    !isregistered(registry_of(net), pid(t)) &&
        push!(errors, string("transition ", repr(pid(t)), " not registered")::String)

    # TODO more verify transition

     return errors
end

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef mutable struct Arc{N <: APN, T <: PnmlExpr} <: AbstractPnmlNode #Object
    id::Symbol
    source::RefValue{Symbol} # IDREF
    target::RefValue{Symbol} # IDREF
    inscription::Inscription{N,T} #! expression label
    arctypelabel::ArcType
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

"""
    inscription(arc::Arc) -> Inscription

Access inscription label of arc.
"""
function inscription(arc::Arc)
    arc.inscription # label
end

#TODO ====================================================================
#TODO Move extensions/enhancements to ISO 150909-1:2004 (1st ED.) to own file.

"""
    arctypelabel(arc::Arc) -> ArcType

Access arctype label of arc.
"""
function arctypelabel(arc::Arc)
    arc.arctypelabel # label
end

is_normal(arc::Arc)    = is_normal(arctypelabel(arc))
is_inhibitor(arc::Arc) = is_inhibitor(arctypelabel(arc))
is_read(arc::Arc)      = is_read(arctypelabel(arc))
is_reset(arc::Arc)     = is_reset(arctypelabel(arc))

is_normal(label::ArcType)    = is_normal(arctype(label))
is_inhibitor(label::ArcType) = is_inhibitor(arctype(label))
is_read(label::ArcType)      = is_read(arctype(label))
is_reset(label::ArcType)     = is_reset(arctype(label))

is_normal(e::ArcTypeEnum.T)    = e == ArcTypeEnum.Normal
is_inhibitor(e::ArcTypeEnum.T) = e == ArcTypeEnum.Inhibitor
is_read(e::ArcTypeEnum.T)      = e == ArcTypeEnum.Read
is_reset(e::ArcTypeEnum.T)     = e == ArcTypeEnum.Reset

"""
    source(arc) -> Symbol

Return identity symbol of source of `arc`.
"""
source(arc::Arc)::Symbol = arc.source[]

"""
    target(arc) -> Symbol

Return identity symbol of target of `arc`.
"""
target(arc::Arc)::Symbol = arc.target[]

function Base.show(io::IO, arc::Arc)
    print(io, nameof(typeof(arc)), "(", repr(pid(arc)),
          ", ", repr(name(arc)),
          ", ", repr(source(arc)),
          ", ", repr(target(arc)),
          ", ", repr(inscription(arc)),
          ", ", repr(arctypelabel(arc)))
    print(io, ")")
end

function verify!(errors, a::Arc, verbose::Bool , net::APN)
    verbose && println("## verify Transition $(pid(a))")
    !isregistered(registry_of(net), pid(a)) &&
        push!(errors, string("arc ", repr(pid(a)), " not registered")::String)

    # TODO verify arc

     return errors
end

#-------------------
"""
Reference Place node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)r
$(TYPEDFIELDS)
"""
struct RefPlace{N <: APN} <: ReferenceNode
    id::Symbol
    ref::Symbol # Place or RefPlace
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition{N <: APN} <: ReferenceNode
    id::Symbol
    ref::Symbol # Transition or RefTransition IDREF
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, nameof(typeof(r)), "(", repr(pid(r)), ",  ", repr(refid(r)), ")")
end
function verify!(errors, r::ReferenceNode, verbose::Bool , net::APN)
    verbose && println("## verify $(typeof(r)) $(pid(r))")
    !isregistered(registry_of(net), pid(r)) &&
        push!(errors, string("arc ", repr(pid(r)), " not registered")::String)

    # TODO verify ReferenceNode

     return errors
end
