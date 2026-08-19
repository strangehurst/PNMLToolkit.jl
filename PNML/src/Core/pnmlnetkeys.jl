"""
$(TYPEDEF)
$(TYPEDFIELDS)

Per-page structure of `OrderedSet`s of pnml IDs for each "owned" `Page` and other
[`AbstractPnmlObject`](@ref).
"""
@kwdef struct PnmlNetKeys
    page_set::OrderedSet{Symbol} = OrderedSet{Symbol}() # Subpages of page, empty if no children.
    place_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    transition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    arc_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    inhibit_arc_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    read_arc_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    reftransition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    refplace_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
end

page_idsets(s::PnmlNetKeys) = s.page_set
place_idsets(s::PnmlNetKeys) = s.place_set
transition_idsets(s::PnmlNetKeys) = s.transition_set
arc_idsets(s::PnmlNetKeys) = s.arc_set
inhibit_arc_idsets(s::PnmlNetKeys) = s.inhibit_arc_set
read_arc_idsets(s::PnmlNetKeys) = s.read_arc_set
reftransition_idsets(s::PnmlNetKeys) = s.reftransition_set
refplace_idsets(s::PnmlNetKeys) = s.refplace_set

function tunesize!(s::PnmlNetKeys;
                   npage::Int = 1, # Usually just 1 page per net.
                   nplace::Int = 32, # TODO Preferences.
                   ntransition::Int = 32,
                   narc::Int = 32,
                   npref::Int = 1, # References only matter when npage > 1.
                   ntref::Int = 1)
    sizehint!(s.page_set, npage)
    sizehint!(s.place_set, nplace)
    sizehint!(s.transition_set, ntransition)
    sizehint!(s.arc_set, narc)
    sizehint!(s.reftransition_set, ntref)
    sizehint!(s.refplace_set, npref)
end

#-------------------
Base.summary(io::IO, pns::PnmlNetKeys) = print(io, summary(pns))
function Base.summary(pns::PnmlNetKeys)
    string(length(page_idsets(pns)), " pages, ",
            length(place_idsets(pns)), " places, ",
            length(transition_idsets(pns)), " transitions, ",
            length(arc_idsets(pns)), " arcs, ",
            length(refplace_idsets(pns)), " refPlaces, ",
            length(reftransition_idsets(pns)), " refTransitions, ",
        )::String
end

function Base.show(io::IO, pns::PnmlNetKeys)
    for (tag, idset) in (
            ("pages", page_idsets),
            ("places", place_idsets),
            ("transitions", transition_idsets),
            ("arcs", arc_idsets),
            ("refplaces", refplace_idsets),
            ("refTransitions", reftransition_idsets))
        print(io, indent(io), length(idset(pns)), " ", tag, ": ")
        iio = inc_indent(io)
        for (i,k) in enumerate(values(idset(pns)))
            print(io, repr(k), ", ")
            if (i < length(idset(pns))) && (i % 15 == 0)
                print(iio, '\n', indent(iio))
            end
        end
        println(io)
    end
end
