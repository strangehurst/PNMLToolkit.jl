
"""
    default(::Type{T<:AbstractLabel}, net::APN) -> T

Return a default instance of label `T` for `pntd`.
"""
function default end

# parse nodes of graph
"Fill place_set, place_dict."
function parse_place!(netsets, netdata, node, net::APN)
    pl = parse_place(node, net)::valtype(placedict(netdata))
    #@show valtype(placedict(netdata)) typeof(placedict(netdata))
    push!(place_idset(netsets)::OrderedSet{Symbol}, pid(pl))
    placedict(netdata)[pid(pl)] = pl
    return place_idset(netsets) #place_set
end

"Fill transition_set, transition_dict."
function parse_transition!(netsets, netdata, node, net::APN)
    tr = parse_transition(node, net)::valtype(transitiondict(netdata))
    push!(transition_idset(netsets)::OrderedSet{Symbol}, pid(tr))
    transitiondict(netdata)[pid(tr)] = tr
    return transition_idset(netsets)
end

"Fill arc_set, arc_dict."
function parse_arc!(netsets, netdata, node, net::APN)
    a = parse_arc(node, net)
    a isa valtype(arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(arcdict(netdata)))) $(pntd(net)) $(repr(a))")
    push!(arc_idset(netsets)::OrderedSet{Symbol}, pid(a))
    arcdict(netdata)[pid(a)] = a
    return arc_idset(netsets)
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(netsets, netdata, node, net::APN)
    rp = parse_refPlace(node, net)::valtype(refplacedict(netdata))
    push!(refplace_idset(netsets)::OrderedSet{Symbol}, pid(rp))
    refplacedict(netdata)[pid(rp)] = rp
    return refplace_idset(netsets)
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(netsets, netdata, node, net::APN)
    rt = parse_refTransition(node, net)::valtype(reftransitiondict(netdata))
    push!(reftransition_idset(netsets)::OrderedSet{Symbol}, pid(rt))
    reftransitiondict(netdata)[pid(rt)] = rt
    return reftransition_idset(netsets)
end


"""
$(TYPEDSIGNATURES)
Return default marking value based on `APNTD`. Has meaning of empty, as in `zero`.
For high-level nets, the marking is an empty multiset whose basis matches `placetype`.
Others have a marking that is a `Number`.
"""
function default(::Type{<:Marking}, net::APN, _placetype::SortType)
    Marking(zero(value_type(Marking, pntd(net))), net) # not high-level!
end

function default(::Type{<:Marking}, net::PnmlNet{T}, placetype::SortType) where {T <: AbstractHLCore}
    el = def_sort_element(placetype)
    Marking(Bag(sortref(placetype), el, 0), "default", net) # el used for its type
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, net::APN)
    check_nodename(node, "place")
    placeid = register_idof!(net.idregistry, node)
    D()&& println("## parse_place ", repr(placeid))
    mark = nothing

    # Get sorttype to use in parsing marking.
    sorttype::Maybe{SortType} = let typenode = firstchild(node, "type")
        if isnothing(typenode) # Deduce sort type of place if possible.
            if isa(pntd(net), AbstractHLCore) && !isa(pntd(net), PT_HLPNG)
                nothing # Deduce from initial marking.
            else
                SortType("default", Labels.default_typesort(pntd(net)), net)
            end
        else
            parse_sorttype(typenode, net; parentid=placeid)
        end
    end

    namelabel::Maybe{Name}           = nothing
    graphics::Maybe{Graphics}        = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol, Any} = LittleDict{Symbol, Any}()

    for place_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(place_child))
        if tag == :initialMarking || tag == :hlinitialMarking tag == :fifoinitialMarking
            isnothing(sorttype) && @warn "$pntd parse_place $placeid sorttype is nothing"
            mark = net.labelparser[tag](place_child, sorttype, net, parentid=placeid)
        elseif tag == :type
            # we already handled this
        elseif tag == :name
            namelabel = net.labelparser[tag](place_child, net, parentid=placeid)
        elseif tag == :graphics
            graphics = parse_graphics(place_child, pntd(net))
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, place_child, net) # place
        else
            unexpected_label!(extralabels, place_child, tag, net; parentid=placeid)
        end
    end

    if isnothing(mark) # Use additive identity of proper sort as default value.
        effective_sorttype = if is_highlevel(pntd(net)) && isnothing(sorttype)
            #D()&&
            @error("$pntd parse_place $(repr(placeid)) has neither a mark nor sorttype, " *
                            "use :dot even if it is WRONG")
            SortType("dummy", NamedSortRef(:dot), net)
        else
            sorttype # Already parsed a <type> or default for non-HL.
        end
        mark = default(Marking, net, effective_sorttype::SortType)
    end

    if isnothing(sorttype) # Infer sortype of place from mark.
        D()&& @warn("$pntd parse_place $(repr(placeid)) infer sorttype ", mark)
        sorttype = SortType("default", basis(mark)::SortRef, net)
    end
    Place(placeid, mark, sorttype, namelabel, graphics, toolspecinfos, extralabels, net)
end

function default(::Type{<:Labels.Condition}, net::APN)
    #@info "default Condition"
    Labels.Condition(BooleanEx(BooleanConstant(true)), net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, net::APN)
    check_nodename(node, "transition")
    transitionid = register_idof!(net.idregistry, node)
    D()&& println("## parse_transition ", repr(transitionid))

    cond::Maybe{PNML.Labels.Condition} = nothing

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol, Any}()

    for trans_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(trans_child))
        if tag == :condition
            cond = net.labelparser[tag](trans_child, net; parentid=transitionid)
        elseif tag == :name
            namelabel = net.labelparser[tag](trans_child, net, parentid=transitionid)
        elseif tag == :graphics
            graphics = parse_graphics(trans_child, pntd(net))
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, trans_child, net)
        else
            unexpected_label!(extralabels,
                              trans_child, tag, net; parentid=transitionid)
        end
    end

    Transition(transitionid,
            something(cond, default(Labels.Condition, net)),
            namelabel, graphics, toolspecinfos, extralabels,
            Set{REFID}(),
            NamedTuple[], net)
end #= function parse_transition =#

function default(::Type{<:Inscription}, net::APN)
    #! Move this check to a verify! method! XXX
    # if refid(placetype) !== :positive
    #     @error(string("$(pntd(net)) default Inscription $placetype mismatch ",
    #                   "$(repr(refid(placetype))) != :positive"))
    # end
    Inscription(nothing, NumberEx(NamedSortRef(:positive), one(Int)), nothing, nothing, REFID[], net)
end

function default(::Type{<:Inscription}, net::PnmlNet{T}) where {T <: AbstractContinuousNet}
    #! Move this check to a verify! method! XXX
    # if refid(placetype) !== :real
    #     @error "$pntd default Inscription $placetype mismatch $(refid(placetype)) != :real"
    # end
    Inscription(nothing, NumberEx(NamedSortRef(:real), one(Float64)), nothing, nothing, REFID[], net)
end

function default(::Type{<:Inscription}, net::PnmlNet{T}) where {T <: PT_HLPNG}
    Inscription(nothing, DotConstantEx(), nothing, nothing, REFID[], net)
end

# Requires placetype
function default(::Type{<:Inscription}, net::PnmlNet{T}, placetype::SortType) where {T <: AbstractHLCore}
    basis = sortref(placetype)::SortRef
    el = def_sort_element(placetype)
    Inscription(nothing, Bag(basis, el, 1), nothing, nothing, REFID[], net)
end

"""
    parse_arc(node::XMLNode, net::APN) -> Arc

Construct an `Arc` with labels specialized for the APNTD.
"""
function parse_arc(node::XMLNode, net::APN)
    check_nodename(node, "arc")
    arc_id = register_idof!(net.idregistry, node)

    source = Symbol(attribute(node, "source"))
    target = Symbol(attribute(node, "target"))
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    arc_type_label::Maybe{ArcType} = nothing

    D()&& println("## parse_arc $arc_id source $source -> target $target")

    for arc_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(arc_child))
        if tag == :inscription || tag == :hlinscription
            # Input arc inscription and source's marking/placesort must have equal Sorts.
            # Output arc inscription and target's marking/placesort must have equal Sorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = net.labelparser[tag](arc_child, source, target, net, parentid=arc_id)
        elseif tag == :name
            namelabel = net.labelparser[tag](arc_child, net, parentid=arc_id)
        elseif tag == :arctype
            arc_type_label = net.labelparser[tag](arc_child, net, parentid=arc_id)
        elseif tag == :graphics
            graphics = parse_graphics(arc_child, pntd(net))
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, arc_child, net)
        else
            unexpected_label!(extralabels, arc_child, tag, net; parentid=arc_id)
        end
    end

    # We are using REFIDs to access both the adjacent place in a dictionary.
    # This (an inscription) is an expression returning a ground term.
    # It may have non-ground terms as parameters.

    if isnothing(inscription)
    #     dummy_placetype = if is_highlevel(pntd(net))
    #         if pntd isa PT_HLPNG
    #             SortType("dummy PT_HLPNG", NamedSortRef(:dot), net)
    #         else
    #             # For other high-level nets, try to deduce using the adjacent place.
    #             # Note that the adjacent place may have not been parsed yet.
    #             sr = if has_place(net, source)
    #                 sortref(place(net, source))
    #             elseif has_place(net, target)
    #                 sortref(place(net, target))
    #             else
    #                 @error string("$pntd inscription not provided for ",
    #                             "arc $arc_id ($source -> $target), ",
    #                             "and we failed to deduce a sorttype, will use :dot.")
    #                 NamedSortRef(:dot)
    #             end
    #             SortType("dummy HIGHLEVEL", sr,  net)
    #        end
    #     elseif is_continuous(pntd(net))
    #         SortType("dummy CONTINUOUS", NamedSortRef(:real), net)
    #     elseif is_discrete(pntd(net))
    #         SortType("dummy DISCRETE", NamedSortRef(:positive), net)
    #     end
        if is_collective_token(pntd(net))
            inscription = default(Inscription, net)
        elseif is_individual_token(pntd(net))
            # Try to deduce using the adjacent place.
            # NB: adjacent place may have not been parsed yet.
            sr = if has_place(net, source)
                sortref(place(net, source))
            elseif has_place(net, target)
                sortref(place(net, target))
            else
                @error string("$pntd inscription not provided for ",
                            "arc $arc_id ($source -> $target), ",
                            "and we failed to deduce a sorttype, will use :dot.")
                NamedSortRef(:dot)
            end
            inscription = default(Inscription, net, SortType("dummy HIGHLEVEL", sr,  net))
       else
            error()
        end
    end

    if isnothing(arc_type_label)
        arc_type_label = ArcType()
        @assert is_normal(arc_type_label)
    end

    Arc(; id=arc_id, source=Ref(source), target=Ref(target),
        inscription, arctypelabel=arc_type_label, namelabel, graphics,
        toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, net::APN)
    check_nodename(node, "referencePlace")
    refp_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refPlace ", repr(refp_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for refp_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(refp_child))
        if tag == :name
            namelabel = net.labelparser[tag](refp_child, net, parentid=refp_id)
        elseif tag == :graphics
            graphics =  parse_graphics(refp_child, pntd(net))
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, refp_child, net)
        else
            unexpected_label!(extralabels, refp_child, tag, net; parentid=refp_id)
        end
    end

    RefPlace(refp_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, net::APN)
    check_nodename(node, "referenceTransition")
    reft_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refTransition ", repr(reft_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for reft_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(reft_child))
        if tag == :name
            namelabel = net.labelparser[tag](reft_child, net, parentid=reft_id)
        elseif tag == :graphics
            graphics = parse_graphics(reft_child, pntd(net))
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, reft_child, net)
        else
            unexpected_label!(extralabels, reft_child, tag, net; parentid=reft_id)
        end
    end

    RefTransition(reft_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end
