# PnmlNet Utilities.

adjacent_place(net::AbstractPnmlNet, a::Arc) = adjacent_place(netdata(net), a)
adjacent_place(netdata::PnmlNetData, a::Arc) = adjacent_place(netdata, source(a), target(a))

#-----------------------------------------------------------------
# Given x ∈ S ∪ T
#   - the set •x = {y | (y, x) ∈ F } is the preset of x.
#   - the set x• = {y | (x, y) ∈ F } is the postset of x.


# ISO 15909-1:2019 Concept 4 precondition of a transition, preset or •t
"""
    preset(net, id) -> Iterator

Iterate ids of input (arc's source) for output transition or place `id`.

See `PNet.in_inscriptions` and `PNet.transition_function`.
"""
preset(net::AbstractPnmlNet, id::Symbol) = begin
    Iterators.map(arcid -> source(arcdict(net)[arcid]), tgt_arcs(net, id))
end

# ISO 15909-1:2019 Concept 5 postcondition of a transition, postset or t•
"""
    postset(net, id) -> Iterator

Iterate ids of output (arc's target) for source transition or place `id`.

See `PNet.out_inscriptions` and `PNet.transition_function``).
"""
postset(net::AbstractPnmlNet , id::Symbol) = begin
    Iterators.map(arcid -> target(arcdict(net)[arcid]), src_arcs(net, id))
end


function inscriptions(net::AbstractPnmlNet)
    Iterators.map((arc_id, a)->arc_id => inscription(a)(NamedTuple()), pairs(arcdict(net)))
end

function inscriptions(net::AbstractHLCore) #TODO! non-ground terms for HL
    @error "high level net $(pid(net)) needs variable substitution"
end

function conditions(net::AbstractPnmlNet)
    Iterators.map((tr_id, t)->tr_id => condition(t)(NamedTuple()), pairs(transitiondict(net)))
end

function conditions(net::AbstractHLCore) #TODO! non-ground terms for HL
    @error "high level net $(pid(net)) needs variable substitution"
end

function rates(net::AbstractPnmlNet)
    #[tid => rate_value(t) for (tid, t) in pairs(transitiondict(net))]
    Iterators.map((tr_id, t)->tr_id => rate_value(t), pairs(transitiondict(net)))
end

"""
inscription_value(a::Maybe{Arc}, def, varsub) -> T

If `a` is nothing return `def` else evaluate inscription expression with varsub,
where `def` is a default value of same sort as adjacent place.
and `varsub` is a possibly empty variable substitution.

Used to create arrays where the default value is used when
there is no arc between an place and transition of the net.
"""
function inscription_value end

function inscription_value(a::Maybe{Arc}, def, varsub)
    if isnothing(a)
        def
    else
        eval(toexpr(term(inscription(a)), varsub, a.net))
    end
end

"Convert inscription value of PT_HLPNG from multiset to cardinality of the multiset."
function _cvt_inscription_value(pntd::APNTD, a::Maybe{Arc}, def, varsub)
    val = inscription_value(a, def, varsub)
    return pntd isa PT_HLPNG ? cardinality(val) : val
end

#==========================================================================
Notes based on ISO/IEC 15909-1:2019 (Part 1, 2nd Edition).

ISO 15909-1:2019 Concept 13: Color class is a non-empty finite set,
may be linearly ordered, circular or unordered.
Color domain (concept 14) a finite cartesian product of color classes.
C is a mapping which defines for each place and each transition its color domain.
W is the weight function, associates with each arc
    a general color function from C(t) to Bag(C(p)).

Color functions (concept 16, 17),
Let D be a color domain
Basic color functions are:
- projection that selects one component of a color
- successor that selects successor of color component
- all that maps any color to the "sum" of color components in class Cᵢ (`<all>` operator)
Class/General color functions
- linear combination (fᵢ) of basic color functions that select >0 tokens

Arcs must have a weight function (inscrition) that is a general color function.

Color Domain vs. Place SortType
ProductSort defines a color domain with >1 color classes (aka other Sorts).
Color functions select a single color component from the domain.
ProductSort -> PnmlTuple elements.
Selecting one tuple field is well founded math, julia handles it.
ProductSort only used by high-level nets.
Tuple elements will evaluate to Bags whose basis matches the place's ProductSort sorttype.

Need a PnmlMultiset that serves as `zero` for `*` and `+`.
PnmlMultiset with basis of `zero` or `null` sort, hold an empty Multiset{T}
matching eltype T for type stability, and acting like `zero`.
#~ See the zero method.
#todo test these axioms
Let z be the special PnmlMultiset
Let m be an ordinary PnmlMultiset
z * m = z
z + m = m

Where can special PnmlMultiset appear: incidence_matrix, where it represents no arc.
They are forbidden as a marking since the basis used is imaginary.
Will not appear in input marking or output of fir!(incidence, enabled, marking).

===========================================================================#

########################################################################################
# firing rule
########################################################################################
function input_matrix(net::AbstractPnmlNet)
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = pntd(net) isa PT_HLPNG ? Int : value_type(Inscription, pntd(net))
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net) # Dispatch on net type.
end

#! Default `<:Number`
function input_matrix!(imatrix, net::AbstractPnmlNet)
    varsub = NamedTuple() # PT_HLPNG is only supported High-level net here
    for (p, place_id) in enumerate(place_idset(net))
        for (t, transition_id) in enumerate(transition_idset(net))
            z = zero_marking(place(net, place_id)) # 0 or empty multiset similar to placetype
            a = arc(net, place_id, transition_id)
            imatrix[t, p] = _cvt_inscription_value(pntd(net), a, z, varsub)#::Number
        end
    end
return imatrix
end

function output_matrix(net::AbstractPnmlNet)
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = pntd(net) isa PT_HLPNG ? Int : value_type(Inscription, pntd(net))
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net) # Dispatch on net type.
end

function output_matrix!(omatrix, net::AbstractPnmlNet)
    varsub = NamedTuple()
    for (p, place_id) in enumerate(place_idset(net))
        for (t, transition_id) in enumerate(transition_idset(net))
            z = zero_marking(place(net, place_id))
            a = arc(net, transition_id, place_id)
            omatrix[t, p] = _cvt_inscription_value(pntd(net), a, z, varsub)#::Number
        end
    end
return omatrix
end

"""
    incidence_matrix(petrinet) -> Matrix

When token identity is collective, marking and inscription values are Numbers and matrix
`C[arc(transition,place)] = inscription(arc(transition,place)) - inscription(arc(place,transition))`
is called the incidence_matrix.

High-level nets have tokens with individual identity, perhaps tuples of them,
usually multisets of finite enumerations, can be other sorts including numbers, strings, lists.
Symmetric nets are restricted, and thus easier to deal with and reason about.
"""
function incidence_matrix end

function incidence_matrix(net::AbstractPnmlNet)
    return output_matrix(net) - input_matrix(net)
end

# Vector{NamedTuple} cached in transition field.
varsubs(net::APN, transition_id::Symbol) = varsubs(transition(net, transition_id))

"""
    initial_markings(petrinet) -> Tuple{Pair{id(place),value_type(marking(place))}

Tuple of Pair(place_id, initial_marking value).

High-level P/T Nets use cardinality of its multiset place marking value.
Really, the implementation should be the same as for PTNet.

Other HL Nets use multisets.
"""
function initial_markings end

function initial_markings(net::AbstractPnmlNet)
    [initial_marking(p)::Number for p in PNML.places(net)]
end

# PT_HLPNG multisets of dotconstants map well to integer via cardinality.
function initial_markings(net::PnmlNet{PT_HLPNG})
    [PNML.cardinality(initial_marking(p)::PnmlMultiset)::Number for p in PNML.places(net)]
end

#! XXX Other HL nets need it to be treated as multiset, not simple numbers! XXX
function initial_markings(net::PnmlNet{<:AbstractHLCore})
    # Evaluate the ground term expression into a multiset.
    [PNML.cardinality(initial_marking(p)::PnmlMultiset)::Number for p in PNML.places(net)]
    #! FIFO places use queues, will co-exist with multisets from regular HL places.
end
