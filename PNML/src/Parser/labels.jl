"""
$(TYPEDSIGNATURES)

Return the stripped string of `<text>` node's content.
"""
function parse_text(node::XMLNode, _::APNTD)
    check_nodename(node, "text")
    return string(strip(EzXML.nodecontent(node)))::String
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding `<text>` value.
With optional `<toolspecific>` & `<graphics>` information.
"""
function parse_name(node::XMLNode, net::APN; parentid)
    check_nodename(node, "name")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd(net))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net) # of name label
        else
            @warn "$parentid ignoring unexpected child of <name>: '$tag'"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        emsg = "<name> missing <text> element."
        if CONFIG.text_optional
            text = string(strip(EzXML.nodecontent(node)))::String
            @warn string(emsg, "Using content = '", text, "'")::String
        else
            throw(ArgumentError(emsg))
        end
    end

    # Since names are for humans and do not need to be unique we will allow empty strings.
    # When the "lint" methods are implemented, they can complain.
    return Name(text, graphics, toolspecinfos)
end

# function parse_name(node::XMLNode, _pntd::APNTD; net::APN, parentid)
#     parse_name(node, net; parentid)
# end


"""
$(TYPEDSIGNATURES)

Return [`ArcType`](@ref) label holding `<text>` value.
With optional `<toolspecific>` & `<graphics>` information.
"""
function parse_arctype(node::XMLNode, net::APN; parentid)
    check_nodename(node, "arctype")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd(net))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net) # name label
        else
            @warn "$parentid ignoring unexpected child of <arctype>: '$tag'"
        end
    end

    if isnothing(text)
        emsg = "<arctype> missing <text> element."
        throw(ArgumentError(emsg))
    end

    #@show text
    arctype = @match text begin
        "inhibitor" => ArcTypeEnum.Inhibitor
        "read" => ArcTypeEnum.Read
        "reset" => ArcTypeEnum.Reset
        _ => ArcTypeEnum.Normal
    end
    #@show arctype
    return ArcType(; text, arctype, graphics, toolspecinfos)
end


#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------

"""
    parse_label_content(node::XMLNode, termparser, net) -> NamedTuple

Parse top-level label  `node` using a `termparser` callable applied to a `<structure>` element
Return named tuple of: text, exp, sort, graphics, toolspecinfos, vars

Top-level labels are attached to nodes, such as: marking, inscription, condition.
Each having a `termparser`.

Returns vars, a tuple of PNML variable REFIDs.
Used in the muti-sorted algebra of High-level nets.
"""
function parse_label_content(node::XMLNode, termparser::F, net::APN) where {F}
    EzXML.haselement(node) || error("xml node is empty")

    text::Maybe{Union{String,SubString{String}}} = nothing
    exp::Maybe{Any} = nothing # Filled by `termparser`.
    ref::Maybe{SortRef} = nothing # Filled by `termparser`.
    vars = () # Will be replaced/updated by `termparer`.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd(net))
        elseif tag == "structure"
            (; exp, ref, vars) = termparser(child, net) #collects variables
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net)
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'", termparser, pntd(net))
        end
    end
    isnothing(exp) && isnothing(text) &&
        error("$(pntd(net)) parse_label_content missing <structure> and <text> for $(EzXML.nodename(node)), one or both is expected")
    #D()&& @info "parse_label_content", text, exp, ref, graphics, toolspecinfos, vars
    return (; text, exp, sort=ref, graphics, toolspecinfos, vars)
end


############################################################################
# Marking
############################################################################

# Sorts are sets in Part 1 of the ISO 15909 standard that defines the semantics.
# Very much mathy, so thinking of sorts as collections is natural.
# Some of the sets are finite: boolean, enumerations, ranges.
# Others include integers, natural, and positive numbers (Also floats/reals).
# Some High-levl Petri nets, in particular Symmetric nets, are restricted to finite sets.
# We support the possibility of full-fat High-level nets with
# arbitrary sort and arbitrary operation definitions.

# Part 2 of the standard that defines the syntax of the xml markup language
# maps these sets to sorts (similar to Type). And adds things.
# Partitions, Lists,

# Part 3 of the standard is a math and semantics extension covering
# modules, extensions, more net types. Not reflected in Part 2 as on August 2024.
# The 2nd edition of Part 1 is contemporaneous with Part 3.
# Part 2 add some of these features through the www.pnml.org Schema repository.

# `sortelements` is needed to support the <all> operator that forms a multiset out of
# one of each of the finite sorts elements. This leads to iteration. Thus eltype.

# If there is no appropriate eltype method defined expect
# `eltype(x) @ Base abstractarray.jl:241` to return Int64.

# Base.eltype is for collections: what an iterator would return.

# Parse <text> as a `Number` of appropriate type or use apropriate default.

"""
$(TYPEDSIGNATURES)

Non-high-level `APNTD` initial marking parser. Most things are assumed to be Numbers.
See also [`parse_hlinitialMarking`](@ref), [`parse_fifoinitialMarking`](@ref).
"""
function parse_initialMarking(node::XMLNode, placetype::Maybe{SortType}, net::APN;
                                parentid::Symbol)
    nn = check_nodename(node, "initialMarking")
    isnothing(placetype) && error("parse_initialMarking expects placetype to be not-nothing")
    # See if there is a <structure> attached to the label. This is non-standard.
    # Use of same mechanism used for high-level nets: if there is a <structure> attached
    # to the label apply `parse_structure` as a `termparser`.
    l = parse_label_content(node, parse_structure, net)::NamedTuple
    if !isnothing(l.exp) # There was a <structure> tag. It is now an expression.
        @warn "$nn place $parentid <structure> element in $(pntd(net)) net; parsed as $(l.exp)"
    end
    if isnothing(l.text) # Expected for non-HL values if there is an <initialMarking>.
        @warn "$nn place $parentid <text> element expected for $(pntd(net)) net"
    end
    @assert isempty(l.vars) # All markings are ground terms.
    # sr = @show sortref(placetype)
    # ts = @show to_sort(sr, net)
    # pt = @show eltype(ts)
    pt = eltype(to_sort(sortref(placetype), net))
    mvt = eltype(value_type(Marking, pntd(net)))
    pt <: mvt ||
        @error("initial marking value type of $(pntd(net)) must be $mvt, found: $pt")
    value = isnothing(l.text) ? zero(pt) : number_value(pt, l.text)
    # We ate the text to make the expression.
    Marking(NumberEx(sortref(placetype), value), nothing, l.graphics, l.toolspecinfos, net)
end

"""
$(TYPEDSIGNATURES)
Ignore the source & target symbols.
"""
function parse_inscription(node::XMLNode, _source::Symbol, _target::Symbol, net::APN; parentid::Symbol)
    @assert !(pntd(net) isa AbstractHLCore) "inscription unexpected on pntd $(pntd(net)): $parentid"
    check_nodename(node, "inscription")
    value = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            value = number_value(value_type(Inscription, pntd(net)), parse_text(child, pntd(net)))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net) # inscription label
        else
            @warn("ignoring unexpected child of <inscription>: '$tag'")
        end
    end

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value)
        value = one(value_type(Inscription, pntd(net)))
    end
    term = NumberEx(sortref(value), value)
    Inscription(nothing, term, graphics, toolspecinfos, REFID[], net)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a <structure> child containing a ground term.
Sort of marking term must be the same as `placetype`, the places SortType.

NB: Used by PTNets that assume placetype is DotSort().
See also [`parse_initialMarking`](@ref), [`parse_fifoinitialMarking`](@ref).
"""
function parse_hlinitialMarking(node::XMLNode, default_sorttype::Maybe{SortType}, net::APN;
                                parentid::Symbol)
    check_nodename(node, "hlinitialMarking")
    #! non-PT_HLPNG High Level nets are expected to always have a marking.
    #! And that marking may be used to deduce the sorttype.
    defsort = isnothing(default_sorttype) ? nothing : sortref(default_sorttype)

    l = parse_label_content(node, ParseMarkingTerm(defsort), net)::NamedTuple
    isnothing(l.sort) &&
        error("Missing parse_hlinitialMarking sort")
    isnothing(l.exp) &&
        error("Missing expression for $(pntd(net)) net")
    placetype = l.sort

    if !(is_namedsort(placetype) ||
        (is_productsort(placetype) && all(is_namedsort, Sorts.sorts(placetype, net))))
        @error("$(pntd(net)) placetype of $parentid expected to be NamedSortRef" *
                " or product of named sorts, found $placetype")
    end

    #^ Do an equalSorts default_sorttype if !nothing.
    if !isnothing(default_sorttype)
        if !is_namedsort(sortref(default_sorttype))
            error("$(pntd(net)) default_sorttype of $parentid " *
                    "expected to be NamedSortRef, found $default_sorttype")
        end
        if !equalSorts(net, sortref(default_sorttype), placetype)
            println()
            @error("$(pntd(net)) parse_hlinitialMarking of $parentid " *
                    "sortref mismatch: $default_sorttype != $placetype",
                    default_sorttype, placetype, l)
            println()
        end
    end

    markexp = if isnothing(l.exp)
        # Default is an empty multiset whose basis matches placetype.
        Bag(sortref(placetype), def_sort_element(placetype), 0)
    else
        l.exp
    end
    Marking(markexp, l.text, l.graphics, l.toolspecinfos, net)
end # parse_hlinitialMarking



"""
$(TYPEDSIGNATURES)

FIFO initial marking labels are expected to have a <structure> child containing ground terms.
Sort of marking term must be the same as `placetype`, the place's SortType.

NB: Will coexist with hlinitialMarkings.
See also [`parse_initialMarking`](@ref), [`parse_hlinitialMarking`](@ref).
"""
function parse_fifoinitialMarking(node::XMLNode, default_sorttype::Maybe{SortType}, net::APN;
                                    parentid::Symbol)
    check_nodename(node, "fifoinitialMarking")
    #! non-PT_HLPNG High Level nets are expected to always have a marking.
    #! And that marking may be used to deduce the sorttype.
    defsort = isnothing(default_sorttype) ? nothing : sortref(default_sorttype)

    l = parse_label_content(node, ParseMarkingTerm(defsort), net)::NamedTuple
    isnothing(l.exp) &&
        error("Missing expression for $(pntd(net)) net")
    isnothing(l.sort) &&
        error("Missing parse_fifoinitialMarking sort")
    placetype = l.sort

    if !(is_namedsort(placetype) ||
            (is_productsort(placetype) && all(is_namedsort, Sorts.sorts(placetype, net))))
        @error(string("$(pntd(net)) placetype of $parentid expected to be NamedSortRef",
                      " or product of named sorts, found $placetype"))
        is_productsort(placetype) && foreach(println, Sorts.sorts(placetype, net))
    end

    #^ Do an equalSorts default_sorttype if !nothing.
    if !isnothing(default_sorttype)
        if !is_namedsort(sortref(default_sorttype))
            error("$(pntd(net)) default_sorttype of $parentid expected to be NamedSortRef" *
                    ", found $default_sorttype")
        end
        if !equalSorts(net, sortref(default_sorttype), placetype)
            println()
            @error(string("$(pntd(net)) parse_fifoinitialMarking of $parentid",
                          " sortref mismatch: $default_sorttype != $placetype"),
                    default_sorttype, placetype, l)
            println()
        end
    end

    markexp = if isnothing(l.exp)
        # Default is an empty queue whose eltype matches placetype.
        Bag(sortref(placetype), def_sort_element(placetype), 0)
    else
        l.exp
    end
    Marking(markexp, l.text, l.graphics, l.toolspecinfos, net)
end # parse_fifoinitialMarking


"""
    ParseMarkingTerm(defsort) -> Functor

Holds parameters for parsing when called as (f::T)(::XMLNode, ::APNTD)
"""
struct ParseMarkingTerm{S}
    defplacetype::S
end

placetype(pmt::ParseMarkingTerm) = pmt.defplacetype::Maybe{SortRef}


#! MARK will be a TERM, a symbolic expression that, when evaluated,
#! produces a PnmlMultiset element object. Or a tuple of objects if a ProductSort is used.
function (pmt::ParseMarkingTerm)(marknode::XMLNode, net::APN)
    check_nodename(marknode, "structure")

    if EzXML.haselement(marknode)
        term = EzXML.firstelement(marknode) # ignore any others

        # Here we are parsing a term from XML to a ground term, which must be an operator.
        mark_tj = parse_term(term, net; vars=()) # ParseMarkingTerm
        isempty(mark_tj.vars) || error("unexpected variables in $mark_tj")
        if isnothing(placetype(pmt))
            @warn "$(pntd(net)) ParseMarkingTerm placetype(pmt) is nothing"
        elseif !equalSorts(net, mark_tj.ref, placetype(pmt)::SortRef)
            @warn "$(pntd(net)) ParseMarkingTerm sort mismatch" mark_tj.ref placetype(pmt) mark_tj
        end
        return mark_tj

        # PnmlMultiset (datastructure) vs UserOperator/NamedOperator (term/expression)
        # Like with sorts, we have useroperator -> namedoperator -> operator.
        # NamedOperators will be joined by ArbitraryOperators for HLPNGs.
        # Operators include built-in operators, multiset operators, tuples
        # Multiset operators must be evaluated to become PnmlMultiset objects.
        # Markings are multisets (a.k.a. bags).
    end
    throw(ArgumentError("missing marking term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, source::Symbol, target::Symbol, net::APN;
                                parentid::Symbol)
    check_nodename(node, "hlinscription")
    l = parse_label_content(node, ParseInscriptionTerm(source, target), net)::NamedTuple
    Inscription(l.text, l.exp, l.graphics, l.toolspecinfos, REFID[l.vars...], net)
end

"""
    ParseInscriptionTerm( Functor

Holds `source` & `target` parameters for parsing an inscription.
The sort of the inscription must match the place sorttype.
Input arcs (source is a transition) and output arcs (source is a place)
called as (pit::ParseInscriptionTerm)(::XMLNode, ::APNTD)
"""
struct ParseInscriptionTerm
    source::Symbol
    target::Symbol
    #!netdata::PnmlNetData
end

source(pit::ParseInscriptionTerm) = pit.source
target(pit::ParseInscriptionTerm) = pit.target
#netdata(pit::ParseInscriptionTerm) = pit.netdata

function (pit::ParseInscriptionTerm)(node::XMLNode, net::APN)
    check_nodename(node, "structure")
    # D()&& println("\nParseInscriptionTerm ", pit)
    isa(target(pit), Symbol) ||
        error("target is a $(nameof(typeof(target(pit)))), expected Symbol")
    isa(source(pit), Symbol) ||
        error("source is a $(nameof(typeof(source(pit)))), expected Symbol")

    # The core PNML standard allows arcs from place to place, and transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).

    # Find adjacent place's sorttype using `netdata`.
    adjacentplace = adjacent_place(netdata(net), source(pit), target(pit))
    placesort = sortref(adjacentplace)::SortRef
    # D()&& @show adjacentplace placesort

    # Variable substitution for a transition affects postset arc inscription,
    # whose expression is used to determine the new marking.
    # Variable substitution covers all variables in a transition. Variables are from inscriptions.
    # A condition expression may use variables from an inscripion.

    EzXML.haselement(node) ||
        error("missing inscription term of arc $(source(pit)) -> $(target(pit))")
    tj = parse_term(EzXML.firstelement(node), net; vars=())::TermJunk

    isa(tj.exp, PnmlExpr) ||
        error("inscription is a $(nameof(typeof(tj.exp))), expected PnmlExpr")

    if !equalSorts(net, tj.ref, placesort)
        @error("arc $(source(pit)) -> $(target(pit)) inscription term sort mismatch: $(tj.ref) != $placesort",
                tj, adjacentplace)
    end
    return tj
end

function adjacent_place(netdata::PnmlNetData, source::REFID, target::REFID, strict=true)
    # `strict` means enforce Meta-model constraint for Petri nets
    # that arcs must be between place and transition.

    if haskey(placedict(netdata), source)
        if strict && !haskey(transitiondict(netdata), target)
            error("adjacent source place $source does not have transition target $target")
        end
        return @inline placedict(netdata)[source]
    elseif haskey(placedict(netdata), target)
        if strict && !haskey(transitiondict(netdata), source)
             error("adjacent target place $target does not have transition source $source")
        end
        return @inline placedict(netdata)[target]
    elseif strict
        # Forbid speculative lookup attempt.
        error("adjacent place not found for source = $source, target = $target")
    end
    return nothing # Means place not yet parsed.
end


# default inscription with sort of adjacent place
function def_insc(netdata, source,::REFID, target::REFID, net::APN)
    # Core PNML standard allows arcs from place to place & transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = adjacent_place(netdata, source, target)
    place_type = place.sorttype
    sort_element = def_sort_element(place_type)
    @info "def_insc $source -> $target singleton pnmlmultiset: $place_type $sort_element"
    return pnmlmultiset(sortref(place_type), sort_element, 1; net)::PnmlMultiset
end

"""
    parse_condition(::XMLNode, ::APNTD; net::APN) -> Condition

Label of transition node. Used in the enabling function.

# Details

ISO/IEC 15909-1:2019(E) Concept 15 (symmetric net) introduces
Φ(transition), a guard or filter function, that is and'ed into the enabling function.
15909-2 maps this to `<condition>` expressions.

Later concepts add filter functions that are also and'ed into the enabling function.
- Concept 28 (prioritized Petri net enabling rule)
- Concept 31 (time Petri net enabling rule)

We support PTNets having `<condition>` with same syntax as High-level nets.
Condition has `<text>` and `<structure>` elements, with all meaning in the `<structure>`
that holds an expression evaluating to a boolean value.

One field of a Condition holds a boolean expression, `AbstractBoolExpr`.
Another field holds information on variables in the expression.
"""
function parse_condition(node::XMLNode, net::APN; parentid)
    l = parse_label_content(node, parse_condition_term, net)::NamedTuple
    isnothing(l.exp) &&
        throw(MalformedException("$parentid missing condition term in $l"))
    PNML.Labels.Condition(l.text, l.exp, l.graphics, l.toolspecinfos, REFID[l.vars...], net)
end

"""
    parse_condition_term(::XMLNode, net::APN) -> PnmlExpr, SortRef, Tuple

Used as `termparser` by [`parse_label_content`](@ref) for `Condition` label of a `Transition`;
will have a structure element containing a term.
"""
function parse_condition_term(cnode::XMLNode, net::APN)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        return parse_term(EzXML.firstelement(cnode), net; vars=())
    end
    throw(ArgumentError("missing condition term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Annotation Label that defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type. Nor a pnml sort.

We allow all pntd's places to have a <type> label.
Non-high-level net places are expecting a numeric sort: eltype(sort) <: Number.
"""
function parse_sorttype(node::XMLNode, net::APN; parentid)
    check_nodename(node, "type")
    l = parse_label_content(node, parse_sorttype_term, net)::NamedTuple
    @assert isempty(l.vars) # No variables as sort is not a term.
    # High-level nets are expected to have a sorttype defined
    # or inferred from initial marking value.

    SortType(; l.text, sort=l.exp, l.graphics, l.toolspecinfos, net)
end

"""
    parse_sorttype_term(::XMLNode, ::APNTD; net::APN) -> PnmlExpr, SortRef, Tuple

The PNML `<type>` of a `<place>` is a "sort" of the high-level many-sorted algebra.
Because we are using the HL implementation with the other meta-models,
we support it in all nets.

The term here is a concrete sort.
It is possible to have an inlined concrete sort that is anonymous.
We place all these concrete sorts in the `decldict(net)`` and pass around a SortRef.

See [`parse_sorttype`](@ref) for the rest of the `AnnotationLabel` structure.
"""
function parse_sorttype_term(typenode::XMLNode, net::APN)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing <type> element in <structure>"))
    # Expect only child element to be a sort.
    sort_node = EzXML.firstelement(typenode)::XMLNode
    sort_type = parse_sort(sort_node, net, nothing, "")::SortRef
    is_multisetsort(sort_type) && error("multiset sort not allowed for place <type>")
    # We use TermJunk because it is convenient. #! Does it work?
    return TermJunk(sort_type, sort_type, ()) # Not a term; has no variables.
end

"""
$(TYPEDSIGNATURES)

For future support of structure elements in non-High-Level nets.
"""
function parse_structure(node::XMLNode, net::APN)
    check_nodename(node, "structure")
    @warn "parse_structure is not implemented for $(pntd(net)) " xmldict(node)
    error("parse_structure is not implemented for $(pntd(net))")
end

function parse_rate(node::XMLNode, net::APN, parentid)
    check_nodename(node, "rate")
    D()&& println("## parse_rate of $(repr(parentid))")
    value = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            value = number_value(value_type(Rate, pntd(net)), parse_text(child, pntd(net)))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net) # inscription label
        else
            @warn("ignoring unexpected child of <rate>: '$tag'")
        end
    end

    # Treat missing value as if the <rate> element was absent.
    if isnothing(value)
        value = one(value_type(Rate, pntd(net)))
    end

    term = NumberEx(sortref(value), value)
    return Rate(; term, graphics, toolspecinfos, net)
end


function parse_priority(node::XMLNode, net::APN, parentid)
    check_nodename(node, "priority")
    #@warn "parse_priority of $(repr(parentid))"
    value = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            value = number_value(value_type(Priority, pntd(net)), parse_text(child, pntd(net)))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd(net))
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, net) # inscription label
        else
            @warn("ignoring unexpected child of <priority>: '$tag'")
        end
    end

    # Treat missing value as if the element was absent.
    if isnothing(value)
        value = one(value_type(Priority, pntd(net)))
    end

    term = NumberEx(sortref(value), value)
    return Priority(; term, graphics, toolspecinfos, net)
end
