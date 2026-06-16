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

page_idset(s::PnmlNetKeys) = s.page_set
place_idset(s::PnmlNetKeys) = s.place_set
transition_idset(s::PnmlNetKeys) = s.transition_set
arc_idset(s::PnmlNetKeys) = s.arc_set
inhibit_arc_idset(s::PnmlNetKeys) = s.inhibit_arc_set
read_arc_idset(s::PnmlNetKeys) = s.read_arc_set
reftransition_idset(s::PnmlNetKeys) = s.reftransition_set
refplace_idset(s::PnmlNetKeys) = s.refplace_set

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
    string(length(page_idset(pns)), " pages, ",
            length(place_idset(pns)), " places, ",
            length(transition_idset(pns)), " transitions, ",
            length(arc_idset(pns)), " arcs, ",
            length(refplace_idset(pns)), " refPlaces, ",
            length(reftransition_idset(pns)), " refTransitions, ",
        )::String
end

function Base.show(io::IO, pns::PnmlNetKeys)
    for (tag, idset) in (("pages", page_idset),
                        ("places", place_idset),
                        ("transitions", transition_idset),
                        ("arcs", arc_idset),
                        ("refplaces", refplace_idset),
                        ("refTransitions", reftransition_idset))
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
