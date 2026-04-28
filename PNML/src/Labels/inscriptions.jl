"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc with a expression term .

`Inscription(t::PnmlExpr)()` is a functor evaluating the expression and
returns a value of the `eltype` of sort of inscription.
"""
struct Inscription{N <: APN, T <: PnmlExpr} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::Vector{Symbol}
    net::N
end

term(i::Inscription) = i.term
sortref(i::Inscription) = expr_sortref(term(i), i.net)::SortRef

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

value_type(::Type{Inscription}, ::APNTD) = eltype(PositiveSort) #::Int
value_type(::Type{Inscription}, ::AbstractContinuousNet) = eltype(RealSort) #::Float64
value_type(::Type{Inscription}, ::PT_HLPNG) = eltype(DotSort)

function value_type(::Type{Inscription}, pntd::AbstractHLCore)
    @error("value_type(::Type{Inscription}, $pntd) undefined. Using DotSort.") #! XXX TODO XXX
    eltype(DotSort) #! XXX TODO XXX
end
