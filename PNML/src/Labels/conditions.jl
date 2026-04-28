"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.
```
"""
@auto_hash_equals struct Condition{N <: APN, T<:PnmlExpr} <: HLAnnotation
    text::Maybe{String}
    term::T # duck-typed AbstractBoolExpr
    # color function: uses term and args, Built/JITed
    graphics::Maybe{Graphics} #TODO switch order of graphics, toolinfos everywhere!
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::Vector{REFID} #! XXX DOCUMENT ME XXX
    net::N
end

Condition(b::Bool, net::APN) = Condition(BooleanConstant(b), net)
Condition(c::BooleanConstant, net::APN) = Condition(BooleanEx(c), net)
Condition(expr::BooleanEx, net::APN) =
    Condition(nothing, expr, nothing, nothing, REFID[], net)
Condition(text::AbstractString, expr::BooleanEx, net::APN) =
    Condition(text, expr, nothing, nothing, REFID[], net)

Base.eltype(::Condition) = Bool
Base.eltype(::Type{<:Condition}) = Bool
value_type(::Type{<:Condition}, ::APNTD) = eltype(BoolSort)

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
# The expression is used to construct a "color function" whose arguments are variables.
# The Condition functor is the color function.
term(c::Condition) = c.term #todo! pnml variables

variables(c::Condition) = c.vars

"""
    (c::Condition)(args) -> Bool

Use `args`, a dictionary of variable substitutions into the expression to return a Bool.
"""
(c::Condition)(varsub::NamedTuple=NamedTuple()) = begin
    # `varsub` maps a variable REFID symbol to an element of the basis sort of marking multiset.
    # It will be a "consistent substitution"
    # Markings are ground terms, can be fully evaluated here. In fact, here we are operating
    # on a marking vector. This vector starts with the initial_marking expression's value.
    return cond_implementation(c, varsub)
end

# color function?
function cond_implementation(c::Condition, varsub::NamedTuple)
    # BooleanEx is a literal. AbstractBoolExpr <: PnmlExpr can be non-literal (non-ground term).
    isa(term(c), BooleanEx) || @warn term(c) varsub  #! debug
    eval(toexpr(term(c), varsub, c.net))::eltype(c) # Bool isa Number
end


function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, term(c))
    print(io, ")")
end
