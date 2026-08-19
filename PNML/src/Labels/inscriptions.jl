"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc with a expression term .

`Inscription(t::PnmlExpr)()` is a functor evaluating the expression and
returns a value of the `eltype` of sort of inscription.
"""
struct Inscription{N <: AbstractPnmlNet, T <: PnmlExpr} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::Vector{Symbol}
    net::N
end

term(i::Inscription) = i.term
sortref(i::Inscription) = expr_sortref(term(i), i.net)::SortRef

#todo @memoize Dict function evaluate(inscription::Inscription, varsub)
function (inscription::Inscription)(varsub::NamedTuple = NamedTuple())
    eval(toexpr(term(inscription), varsub, inscription.net))
end

variables(inscription::Inscription) = inscription.vars

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, term(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, toolinfos(inscription));
    end
    print(io, ")")
end

# Non-high-level have a fixed, single value type for inscriptions, marks that is a Number.
# High-level use a multiset or bag over a basis or support set.
# Sometimes the basis is an infinite set. That is possible with HLPNG.
# Symmetric nets are restrictd to finite sets: enumerations, integer ranges.
# The desire to support marking & inscriptions that use Real value type introduces complications.
#
# Approaches
# - Only use Real for non-HL. The multiset implementation uses integer multiplicity.
#   Restrict the basis to ?
# - PnmlMultiset wraps a multiset and a sort. The sort and the contents of the multiset
#   must have the same type.
#
# Terms sort and type are related. Type is very much a Julia mechanism. Like sort it is found
# in mathmatical texts that also use type.

# Julia Type is the "fixed" part.

#!============================================================================
#! inscription value_type must match adjacent place marking value_type
#! with inscription being PositiveSort and marking being NaturalSort.
#!============================================================================

value_type(::Type{Inscription}, ::AbstractPNTD) = eltype(PositiveSort) #::Int
value_type(::Type{Inscription}, ::AbstractContinuousPNTD) = eltype(RealSort) #::Float64
value_type(::Type{Inscription}, ::PT_HLPNG) = eltype(DotSort)
function value_type(::Type{Inscription}, pntd::AbstractHLPNTD)
    @outline(pntd, @error("value_type(::Type{Inscription}, $pntd) undefined. Using Any.")) #! XXX TODO XXX
    Any # eltype(DotSort) #! XXX TODO XXX
end

function value_type(::Type{Inscription}, s::Symbol)
    if s === :pnmlcore || s === :ptnet
        eltype(PositiveSort)
    elseif s === :continuous
        eltype(RealSort)
    elseif s == :pt_hlpng
        eltype(DotSort)
    elseif is_highlevel(s)
        @outline(s, @error("value_type(::Type{Inscription}, $s) undefined. Using DotSort.")) #! XXX TODO XXX
        eltype(DotSort) #! XXX TODO XXX
    else
        error("not a valid PNTD symbol: $s")
    end
end
# is_collective_token
value_type(::Type{Inscription}, ::Val{:pnmlcore}) = eltype(PositiveSort)
value_type(::Type{Inscription}, ::Val{:ptnet}) = eltype(PositiveSort)
value_type(::Type{Inscription}, ::Val{:pt_hlpng}) = eltype(DotSort)
value_type(::Type{Inscription}, ::Val{:continuous}) = eltype(RealSort)
# For rest of is_highlevel is_individual_token is true.
# Each place and adjacent arcs' inscriptions have the same basis sort (SortType label).
# Any basis sort except MultisetSort.
value_type(::Type{Inscription}, ::Val{:hlcore}) = Any
value_type(::Type{Inscription}, ::Val{:hlnet}) = Any
value_type(::Type{Inscription}, ::Val{:symmetric}) = Any
