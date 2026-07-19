# PnmlNet Utilities.

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
    Iterators.map(arcid -> PNML.source(PNML.arc(net, arcid)::Arc), PNML.tgt_arcs(net, id))
end

# ISO 15909-1:2019 Concept 5 postcondition of a transition, postset or t•
"""
    postset(net, id) -> Iterator

Iterate ids of output (arc's target) for source transition or place `id`.

See `PNet.out_inscriptions` and `PNet.transition_function``).
"""
postset(net::AbstractPnmlNet , id::Symbol) = begin
    Iterators.map(arcid -> PNML.target(PNML.arc(net, arcid)::Arc), PNML.src_arcs(net, id))
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

"""
    input_matrix(net::AbstractPnmlNet) -> Matrix{ivt}

Return matrix of proper type and shape, fill using `input_matrix!`
"""
function input_matrix end

function input_matrix(net::PnmlNet{T}) where {T <: AbstractPNTD}
    ivt = value_type(Inscription, pntd_of(net))
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net)
end
function input_matrix(net::PnmlNet{PT_HLPNG})
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = Int
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net)
end
function input_matrix(net::PnmlNet{T}) where {T <: AbstractHLCore}
    ivt = value_type(Inscription, pntd_of(net))
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net)
end

"""
    input_matrix!(imatrix, net::AbstractPnmlNet)
"""
function input_matrix!(imatrix, net::AbstractPnmlNet)
    varsub = NamedTuple()  #todo! add Symmetric and HL support
    for (p, place_id) in enumerate(place_idset(net))
        for (t, transition_id) in enumerate(transition_idset(net))
            a = arc(net, place_id, transition_id)::Maybe{Arc}
            val = if isnothing(a)
                zero_marking(place(net, place_id)) # 0 or empty multiset similar to placetype
            else
                inscription_value(a, varsub)
            end
            imatrix[t, p] = dot2int(pntd_of(net), val)
        end
    end
    return imatrix
end

"""
    output_matrix(net::AbstractPnmlNet) -> Matrix{ivt}

Return matrix of proper type and shape, fill using `output_matrix!`
"""
function output_matrix end
function output_matrix(net::PnmlNet{T}) where {T <: AbstractPNTD}
    ivt = value_type(Inscription, pntd_of(net))
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net)
end
function output_matrix(net::PnmlNet{PT_HLPNG})
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = Int
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net)
end
function output_matrix(net::PnmlNet{T}) where {T <: AbstractHLCore}
    ivt = value_type(Inscription, pntd_of(net))
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net)
end

function output_matrix!(omatrix, net::AbstractPnmlNet)
    varsub = NamedTuple() #todo! add Symmetric and HL support, variables
    for (p, place_id) in enumerate(place_idset(net))
        for (t, transition_id) in enumerate(transition_idset(net))
            a = arc(net, transition_id, place_id)::Maybe{Arc}
            val = if isnothing(a)
                z = zero_marking(place(net, place_id))
                if pntd_of(net) isa PT_HLPNG
                    @assert dot2int(pntd_of(net), z) == 0
                end
                z
            else
                inscription_value(a, varsub)
            end
            #@show typeof(omatrix) typeof(val)
            omatrix[t, p] = dot2int(pntd_of(net), val)
        end
    end
    return omatrix
end
dot2int(::PT_HLPNG, v) = cardinality(v)
dot2int(::AbstractHLCore, v) = v
dot2int(::AbstractPNTD, v) = v

"backward (input) incidence matrix element"
function pre(net::AbstractPnmlNet, p::Symbol, t::Symbol, varsubs=NamedTuple())
    @assert PNML.has_transition(net, t)
    @assert PNML.has_place(net, p)
    a = arc(net, p, t)::Maybe{Arc}
    iv = if isnothing(a)
        zero_marking(place(net, p))
    else
        inscription_value(a, varsubs)
    end
    println("pre(net, $p, $t) = ", iv)
    return iv
end

"forward (output) incidence matrix element"
function post(net::AbstractPnmlNet, t::Symbol, p::Symbol, varsubs=NamedTuple())
    @assert PNML.has_transition(net, t)
    @assert PNML.has_place(net, p)
    a = arc(net, t, p)::Maybe{Arc}
    iv = if isnothing(a)
        zero_marking(place(net, p))
    else
        inscription_value(a, varsubs)
    end
    println("post(net, $t, $p) = ", iv)
    return iv
end

"""
    incidence_matrix(petrinet) -> Matrix

When token identity is collective, marking and inscription values are Numbers and matrix
`C[arc(transition,place)] = inscription(arc(transition,place)) - inscription(arc(place,transition))`
is called the incidence_matrix.

High-level nets have tokens with individual identity, perhaps tuples of them.
Usually multisets of finite enumerations, can be other sorts including numbers, strings, lists.
Symmetric nets restricts multisets of finite enumerations, and thus easier to deal with and reason about.
"""
function incidence_matrix end

function incidence_matrix(net::AbstractPnmlNet)
    return output_matrix(net) - input_matrix(net)
end

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
    # Use <fifoinitialMarking><structure><makelist> expression for initial queue contents.
    # DataStructures.Queue{sorttype} will be an element in the marking vector.
    #? Do we segregate  FIFO from HL markings by a new xml tag?
