"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.

`PNTD` binds the other type parameters together to express a specific PNG.
See [`PnmlNet`](@ref)
"""
@kwdef mutable struct Page{N <: APN} <: AbstractPnmlObject
    net::N
    id::Symbol
    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    netsets::PnmlNetKeys # This page's keys of items owned in netdata/pagedict. Not shared.
    # Note: `PnmlNet` only has `page_idset` becpage_setause all PNML net Objects
    # are attached to a `Page`. And there must be at least one `Page`.
    # There could be >1 nets. `netdata` is ordered, `netsets` are unordered.
end

nettype(pg::Page) = nettype(net(pg))

net(page::Page) = page.net
pagedict(page::Page) = pagedict(net(page))
netdata(page::Page)  = netdata(net(page))
netsets(page::Page)  = page.netsets

placedict(page::Page)         = placedict(netdata(page))
transitiondict(page::Page)    = transitiondict(netdata(page))
arcdict(page::Page)           = arcdict(netdata(page))
refplacedict(page::Page)      = refplacedict(netdata(page))
reftransitiondict(page::Page) = reftransitiondict(netdata(page))

#! Do not expect the page api to see much use, so it is likely not very efficient.
pages(page::Page)       = Iterators.filter(v -> in(pid(v), page_idset(page)), values(pagedict(page)))
places(page::Page)      = Iterators.filter(v -> in(pid(v), place_idset(page)), values(placedict(page)))
transitions(page::Page) = Iterators.filter(v -> in(pid(v), transition_idset(page)), values(transitiondict(page)))
arcs(page::Page)        = Iterators.filter(v -> in(pid(v), arc_idset(page)), values(arcdict(page)))
refplaces(page::Page)   = Iterators.filter(v -> in(pid(v), refplace_idset(page)), values(refplacedict(page)))
reftransitions(page::Page) = Iterators.filter(v -> in(pid(v), reftransition_idset(page)), values(reftransitiondict(page)))

page_idset(page::Page)          = page_idset(netsets(page)) # subpages of this page
place_idset(page::Page)         = place_idset(netsets(page))
transition_idset(page::Page)    = transition_idset(netsets(page))
arc_idset(page::Page)           = arc_idset(netsets(page))
reftransition_idset(page::Page) = reftransition_idset(netsets(page))
refplace_idset(page::Page)      = refplace_idset(netsets(page))

place(page::Page, id::Symbol) = placedict(page)[id]
has_place(page::Page, id::Symbol) = in(id, place_idset(page))

transition(page::Page, id::Symbol) = transitiondict(page)[id]
has_transition(page::Page, id::Symbol) = in(id, transition_idset(page))

arc(page::Page, id::Symbol) = arcdict(page)[id]
has_arc(page::Page, id::Symbol) = in(id, arc_idset(page))

refplace(page::Page, id::Symbol)     = refplacedict(page)[id]
has_refplace(page::Page, id::Symbol) = in(id, refplace_idset(page))

reftransition(page::Page, id::Symbol)     = reftransitiondict(page)[id]
has_reftransition(page::Page, id::Symbol) = in(id, reftransition_idset(page))

function Base.show(io::IO, page::Page{N}) where {N <: APN}
    #TODO Add support for :trim and :compact
    print(io, "Page{",N,"}("),
    show(io, pid(page)); print(io, ", ")
    show(io, name(page)); print(io, ", ")
    println(io)
    iio = inc_indent(io)    # Will indent subpages.
    print(iio, indent(iio), "places: ",       repr(place_idset(page)), ",\n");
    print(iio, indent(iio), "transitions: ",  repr(transition_idset(page)), ",\n");
    print(iio, indent(iio), "arcs: ",         repr(arc_idset(page)), ",\n");
    print(iio, indent(iio), "refPlaces:",     repr(refplace_idset(page)), ",\n");
    print(iio, indent(iio), "refTransitions: ", repr(reftransition_idset(page)), ",\n");
    print(iio, indent(iio), "subpages: ",     repr(page_idset(page)), ",\n");
    print(io, ")")
end

function verify(page::Page, verbose::Bool, net::APN)
    errors = String[]
    verify!(errors, page, verbose, net)
    isempty(errors) ||
        error("verify(page) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors, page::Page, verbose::Bool, net::APN)
    verbose && println("## verify $(typeof(page)) $(pid(page))")
    !isregistered(registry_of(net), pid(page)) &&
        push!(errors, string("page ", repr(pid(page)), " not registered")::String)

    # TODO more verify Page

     return errors
end
