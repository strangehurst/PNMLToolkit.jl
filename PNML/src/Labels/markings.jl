"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of [`Place`](@ref).

Is a functor that returns the `value`.
```
"""
struct Marking{N <: APN, T <: PnmlExpr} <: Annotation
    term::T #! expression
    text::Maybe{String} # Supposed to be for human consumption.
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in toolspecinfos rather than graphics.
    toolspecinfos::Maybe{Vector{ToolInfo}}
    net::N
end

# Allow any Number subtype, only a few concrete subtypes are expected.
function Marking(m::Number, net::APN)
    Marking(NumberEx(sortref(m)::SortRef, m), net)
end
Marking(nx::NumberEx, net::APN) = Marking(nx, nothing, nothing, nothing, net)
Marking(t::PnmlExpr, s::Maybe{AbstractString}, net::APN) = Marking(t, s, nothing, nothing, net)

term(marking::Marking) = marking.term

# 1'value where value isa eltype(marking)
# because we assume a multiplicity of 1, and the sort is simple
# Assume eltype(sortdefinition(marking)) == typeof(value(marking))

# """
# $(TYPEDEF)
# $(TYPEDFIELDS)

# Multiset of a sort labeling of a `Place` in a High-level Petri Net Graph.
# See [`AbstractHLCore`](@ref), [`AbstractTerm`](@ref), [`Marking`](@ref).

# Is a functor that returns the evaluated `value`.

# > ... is a term with some multiset sort denoting a collection of tokens on the corresponding place, which defines its initial marking.
# NB: The place's sorttype is not a multiset

# > a ground term of the corresponding multiset sort. (does not contain variables)

# > For every sort, the multiset sort over this basis sort is interpreted as
# > the set of multisets over the type associated with the basis sort.

# Multiset literals ... are defined using Add and NumberOf (multiset operators).

# The term is a expression that will, when evaluated, have a `Sort`.
# Implement the Sort interface.

# # Examples


# Marking(Bag(NamedSortRef(:integer), 1))

# julia> m()
# 1
# ```

# This is where the initial value EXPRESSION is stored.
# The evaluated value is placed in the marking vector (as the initial value:).
# Firing rules use arc inscriptions to determine the new value for marking vector.

# NOTE: marking also be a tuple/PnmlTuple matching placetype ProductSort?

# Inscription and condition expressions may contain variables that map to a place's current marking.
# HL Nets need to evaluate expressions after variable substitution as part of enabling and transition firing rules.
# The result must be a ground term, and is used to update a marking vector.

# For non-High,level nets, the inscrition expression is a
# `NumberEx` (`<numberconstant> in HL-speak), default one`)
# and the condition is a boolean expression (default true).
# """
"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by evaluating term expression.

Place/Transition Nets (and ContinuousNet) use collective token identity (map to `Number`).
High-level Nets (SymmetricNet, HLPNG) use individual token identity (colored petri nets).

There is a multi-sorted algebra definition mechanism defined for HL Nets.
HL Net Marking values are a ground terms of this multi-sorted algebra.

Used to initialize a marking vector that will then be updated by firing a transition.
"""
(mark::Marking)() = eval(toexpr(term(mark)::PnmlExpr, NamedTuple(), mark.net))

basis(m::Marking)   = sortref(term(m))::SortRef
sortref(m::Marking) = expr_sortref(term(m), m.net)::SortRef

function Base.show(io::IO, ptm::Marking)
    print(io, indent(io), "Marking(")
    show(io, term(ptm))
    if has_graphics(ptm)
        print(io, ", ")
        show(io, graphics(ptm))
    end
    if has_tools(ptm)
        print(io, ", ")
        show(io, toolinfos(ptm));
    end
    print(io, ")")
end

#--------------------------------------------------------------------------------------
value_type(::Type{Marking}, net::APN) = value_type(Marking, pntd(net))

# These are networks where the tokens have a collective identities.
value_type(::Type{Marking}, ::APNTD) = eltype(NaturalSort) #::Int
value_type(::Type{Marking}, ::AbstractContinuousNet) = eltype(RealSort) #::Float64

# These are networks were the tokens have individual identities.
function value_type(::Type{Marking}, pntd::AbstractHLCore)
    @error("value_type(::Type{Marking}, $pntd) undefined. Using DotSort.")
    eltype(DotSort)
end

# PT_HLPNG is restricted to DotSort, we treat its singleton multisets as  NaturalSort.
value_type(::Type{Marking}, ::PT_HLPNG) = eltype(NaturalSort) #::Int

#~ Note the close relation of marking value_type to inscription value_type.
#~ Inscription values are non-zero while marking values may be zero.

#--------------------------------------------------------------------------------------
# Basis sort can be, and are, restricted by/on APNTD in the ISO 15909 standard.
# That is a statement about the XML file content. Allows a partial implementation that
# only supports the PTNet meta-model or SymmetricNet meta-model of Petri nets.
# The PnmlCoreNet, upon which PTNet, SymmetricNet, HLPNG, etc. are defined can be used
# to implement non-Petri net meta-models.
#
# PnmlCoreNet is a directed graph with extensible labels (and pages, tool specific).
#
# PNML.jl extensions: RealSort <: NumberSort

# PTNet and ContinuousNet:
#   NumberSort = IntegerSort, PositiveSort, NaturalSort, RealSort

# Symmetric Net:
#   BoolSort, FiniteIntRangeSort, FiniteEnumerationSort, CyclicEnumerationSort and DotSort

# High-Level Petri Net Graph adds:
#   IntegerSort, PositiveSort, NaturalSort
#   StringSort, ListSort
#
# Implementation detail: the concrete NumberSort subtypes are Singleton types held in a field.
# NB: not all sort types are singletons, example FiniteEnumerationSort.
