"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of [`Place`](@ref).

Is a functor that returns the `value`.
```
"""
@kwdef struct Marking{N <: AbstractPnmlNet, T <: PnmlExpr} <: Annotation
    term::T #! expression
    text::Maybe{String} = nothing # Supposed to be for human consumption.
    graphics::Maybe{Graphics} = nothing# PTNet uses TokenGraphics in toolspecinfos rather than graphics.
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
    place::Symbol
end

import Base: ==, hash
function Base.:(==)(a::Marking, b::Marking)
    return (a.term == b.term) &&
        (a.text == b.text) &&
        (a.graphics == b.graphics) &&
        (a.toolspecinfos == b.toolspecinfos) &&
        (a.net == b.net) &&
        (a.place == b.place)
end

function Base.hash(u::Marking, h::UInt)
    # Mix the type symbol and the field hashes with the incoming salt 'h'
    return Base.hash(u.term,
                     hash(u.text,
                     hash(u.graphics,
                     hash(u.toolspecinfos,
                     hash(u.net,
                     hash(:Marking,
                     h))))))
end

# Allow any Number subtype, only a few concrete subtypes are expected.
function Marking(m::Number, net::AbstractPnmlNet, place::Symbol)
    Marking(; term=NumberEx(sortref(m)::SortRef, m), net, place)
end

term(marking::Marking) = marking.term

# 1'value where value isa eltype(marking)
# because we assume a multiplicity of 1, and the sort is simple
# Assume eltype(sortdefinition(marking)) == typeof(value(marking))

# """
# $(TYPEDEF)
# $(TYPEDFIELDS)

# Multiset of a sort labeling of a `Place` in a High-level Petri Net Graph.
# See [`AbstractHLPNTD`](@ref), [`AbstractTerm`](@ref), [`Marking`](@ref).

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
(mark::Marking)() = evaluate_mark(mark)
@memoize function evaluate_mark(mark::Marking)
    eval(toexpr(term(mark)::PnmlExpr, NamedTuple(), mark.net))
end

basis(m::Marking) = sortref(term(m))::SortRef
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
# is_collective_token
value_type(::Type{Marking}, ::Val{:pnmlcore}) = Int
value_type(::Type{Marking}, ::Val{:ptnet}) = Int
value_type(::Type{Marking}, ::Val{:continuous}) = Float64
value_type(::Type{Marking}, ::Val{:pt_hlpng}) = Int
# For rest of is_highlevel is_individual_token is true.
# Each place and adjacent arcs' inscriptions have the same basis sort (SortType label).
# Any basis sort except MultisetSort.
value_type(::Type{Marking}, ::Val{:hlcore}) = Any
value_type(::Type{Marking}, ::Val{:hlnet}) = Any
value_type(::Type{Marking}, ::Val{:symmetric}) = Any
# Place markings are bags over a basis sort.
# Place's SortType label wraps that basis sort.
# Each place has a SortType refering to any non-multiset sort in net's DeclDicts.
# Symmetric nets restricted to finite sorts. Enumerations, integer ranges.ArcType
# High level adds sorts of integer, string, list, arbitrary.

#~ Note the close relation of marking value_type to inscription value_type.
#~ Inscription values are non-zero while marking values may be zero.

#--------------------------------------------------------------------------------------
# Basis sort can be, and are, restricted by/on AbstractPNTD in the ISO 15909 standard.
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
