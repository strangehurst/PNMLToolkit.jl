# Created 2025-11-10
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is for a Time Petri net.
Expected XML: `<time> <text>0.3</text> </time>`.

TBD? Dynamic time is a function with arguments of net marking and transition.

"""
@kwdef struct Time{N <: AbstractPnmlNet, T <: PnmlExpr} <: Annotation
    text::Maybe{String} = nothing
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
end

value_type(::Type{Time}) = Float64
value_type(::Type{Time}, ::Any) = Float64
Base.eltype(::Time) = value_type(Time)
Base.eltype(::Type{Time}) = value_type(Time)
term(i::Time) = i.term
sortref(i::Time) = expr_sortref(term(i), i.net)::SortRef
"""
    (time::Time)(::NamedTuple)() -> Float64

Functor evaluating a PnmlExpr. Expected to be a `Real`.
"""
function (time::Time)(varsub::NamedTuple=NamedTuple())
    #todo @memoize
    eval(toexpr(term(time), varsub, time.net))::value_type(Time)
end

value(t::Time) = t()

#! label_value(t, :time, one(value_type(Time)))::value_type(Time)

function Base.show(io::IO, r::Time)
    print(io, "Time(", r.term, ", ", repr(r.graphics),  ", ", repr(r.toolspecinfos), ")")
end
