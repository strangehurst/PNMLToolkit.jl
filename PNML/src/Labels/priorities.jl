# Created 2025-11-10
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is as a static transition Priority.
Expected XML: `<priority> <text>0.3</text> </priority>`.

Dynamic priority is a function with arguments of net marking and transition.
"""
@kwdef struct Priority{N <: APN, T <: PnmlExpr} <: Annotation
    text::Maybe{String} = nothing
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
end

value_type(::Type{Priority}) = Float64
value_type(::Type{Priority}, ::APNTD) = Float64

Base.eltype(::Priority) = value_type(Priority)
Base.eltype(::Type{Priority}) = value_type(Priority)

term(i::Priority{N, T}) where {N <: APN, T <: PnmlExpr} = i.term
sortref(i::Priority) = expr_sortref(term(i), i.net)::SortRef

function (priority::Priority)(varsub::NamedTuple=NamedTuple())
    eval(toexpr(term(priority), varsub, priority.net))::value_type(Priority)
end

value(r::Priority) = r()

function Base.show(io::IO, r::Priority)
    print(io, "Priority(", r.term, ", ", repr(r.graphics),  ", ", repr(r.toolspecinfos), ")")
end

"""
    priority_value(t) -> Real

Return value of a `Priority` label.  Missing priority labels are defaulted to one.

Expected label XML: `<priority> <text>0.3</text> </priority>`

# Arguments
    `t` is anything that supports `get_label(t, tag)`.
"""
function priority_value(t)
    label_value(t, :priority, one(value_type(Priority)))::value_type(Priority)
end
