"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.

Each place has an initial marking that has a basis matching sorttype.
M is a "multiset sort denoting a collection of tokens".
A "multiset sort over a basis sort is interpreted as
"the set of multisets over the type associated with the basis sort".
"""
@kwdef mutable struct Place{N <: APN, T <: PnmlExpr}  <: AbstractPnmlNode
    id::Symbol
    initialMarking::Marking{N, T} # Expression as value. Used to create marking vector.

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
