"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.

`PNTD` binds the other type parameters together to express a specific PNG.
See [`PnmlNet`](@ref)
"""
@kwdef mutable struct Page{N<:AbstractPnmlNet} <: AbstractPnmlObject
    net::N
    id::Symbol
    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    netsets::PnmlNetKeys # This page's keys of items owned in net dictionaries. Not shared.
    # Note: `PnmlNet` only has `page_idset` because all PNML net Objects
    # are attached to a `Page`. And there must be at least one `Page`.
    # There could be >1 nets. `netdata` is ordered, `netsets` are unordered.
end

net(page::Page) = page.net
pagedict(page::Page) = pagedict(net(page))
netsets(page::Page)  = page.netsets

placedict(page::Page)         = placedict(net(page))
transitiondict(page::Page)    = transitiondict(net(page))
arcdict(page::Page)           = arcdict(net(page))
refplacedict(page::Page)      = refplacedict(net(page))
reftransitiondict(page::Page) = reftransitiondict(net(page))

#! Do not expect the page api to see much use, so it is likely not very efficient.
pages(page::Page)       = Iterators.filter(v -> in(pid(v), page_idsets(page)), values(pagedict(page)))
places(page::Page)      = Iterators.filter(v -> in(pid(v), place_idsets(page)), values(placedict(page)))
transitions(page::Page) = Iterators.filter(v -> in(pid(v), transition_idsets(page)), values(transitiondict(page)))
arcs(page::Page)        = Iterators.filter(v -> in(pid(v), arc_idsets(page)), values(arcdict(page)))
refplaces(page::Page)   = Iterators.filter(v -> in(pid(v), refplace_idsets(page)), values(refplacedict(page)))
reftransitions(page::Page) = Iterators.filter(v -> in(pid(v), reftransition_idsets(page)), values(reftransitiondict(page)))

page_idsets(page::Page)          = page_idsets(netsets(page)) # subpages of this page
place_idsets(page::Page)         = place_idsets(netsets(page))
transition_idsets(page::Page)    = transition_idsets(netsets(page))
arc_idsets(page::Page)           = arc_idsets(netsets(page))
reftransition_idsets(page::Page) = reftransition_idsets(netsets(page))
refplace_idsets(page::Page)      = refplace_idsets(netsets(page))

place(page::Page, id::Symbol) = placedict(page)[id]
has_place(page::Page, id::Symbol) = in(id, place_idsets(page))

transition(page::Page, id::Symbol) = transitiondict(page)[id]
has_transition(page::Page, id::Symbol) = in(id, transition_idsets(page))

arc(page::Page, id::Symbol) = arcdict(page)[id]
has_arc(page::Page, id::Symbol) = in(id, arc_idsets(page))

refplace(page::Page, id::Symbol)     = refplacedict(page)[id]
has_refplace(page::Page, id::Symbol) = in(id, refplace_idsets(page))

reftransition(page::Page, id::Symbol)     = reftransitiondict(page)[id]
has_reftransition(page::Page, id::Symbol) = in(id, reftransition_idsets(page))

function Base.show(io::IO, page::Page{N}) where {N <: AbstractPnmlNet}
    #TODO Add support for :trim and :compact
    print(io, "Page{",N,"}("),
    show(io, pid(page)); print(io, ", ")
    show(io, name(page)); print(io, ", ")
    println(io)
    iio = inc_indent(io)    # Will indent subpages.
    print(iio, indent(iio), "places: ",       repr(place_idsets(page)), ",\n");
    print(iio, indent(iio), "transitions: ",  repr(transition_idsets(page)), ",\n");
    print(iio, indent(iio), "arcs: ",         repr(arc_idsets(page)), ",\n");
    print(iio, indent(iio), "refPlaces:",     repr(refplace_idsets(page)), ",\n");
    print(iio, indent(iio), "refTransitions: ", repr(reftransition_idsets(page)), ",\n");
    print(iio, indent(iio), "subpages: ",     repr(page_idsets(page)), ",\n");
    print(iio, indent(iio), ")")
end

function verify(page::Page, verbose::Bool, net::AbstractPnmlNet)
    errors = String[]
    verify!(errors, page, verbose, net)
    isempty(errors) ||
        error("verify(page) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors, page::Page, verbose::Bool, net::AbstractPnmlNet)
    verbose && println("## verify $(typeof(page)) $(pid(page))")
    !isregistered(registry_of(net), pid(page)) &&
        push!(errors, string("page ", repr(pid(page)), " not registered")::String)

    # TODO more verify Page

     return errors
end
