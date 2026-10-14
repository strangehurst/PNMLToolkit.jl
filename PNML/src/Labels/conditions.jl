"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.
```
"""
@struct_hash_equal @kwdef struct Condition{N <: AbstractPnmlNet, T<:PnmlExpr} <: HLAnnotation
    text::Maybe{String} = nothing
    term::T # duck-typed AbstractBoolExpr
    # color function: uses term and args, Built/JITed
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
end

Condition(b::Bool, net::AbstractPnmlNet) = Condition(BooleanConstant(b), net)
Condition(c::BooleanConstant, net::AbstractPnmlNet) = Condition(; term=BooleanEx(c), net)
# Condition(expr::BooleanEx, net::AbstractPnmlNet) =
#     Condition(nothing, expr, nothing, nothing, net)
# Condition(text::AbstractString, term::BooleanEx, net::AbstractPnmlNet) =
#     Condition(; text, term, nothing, nothing, net)

Base.eltype(::Condition) = Bool
Base.eltype(::Type{<:Condition}) = Bool
value_type(::Type{<:Condition}) = eltype(BoolSort)
value_type(::Type{<:Condition}, ::Any) = eltype(BoolSort)

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
# The expression is used to construct a "color function" whose arguments are variables.
# The Condition functor is the color function.
term(c::Condition) = c.term #todo! pnml variables

"""
    $(TYPEDSIGNATURES)

Return iterable collection of `Symbol`s.
"""
function variables(c::Condition)
    find_vars(term(c)) # c.vars
end
"""
    (c::Condition)(args) -> Bool

Use `args`, a dictionary of variable substitutions into the expression to return a Bool.
"""
(c::Condition)(varsub::NamedTuple=NamedTuple()) = begin
    # `varsub` maps a variable REFID symbols to values.
    # Variable REFID is the key a variabledecl that provides a name and sortref.
    # Sortref of variabledecl and sorttype of place will be consistent when:
    #  - they are equalSorts.
    #  - place sorttype is a ProductSort and one of its element sorts are equalSorts with variable.
    #    NB: Can variable value be a multiset
    # It will be a "consistent substitution" when the value is legal.ArcType
    return eval_cond_term(c, varsub)
end

# color function?
#todo @memoize Dict function evaluate(c::Condition, varsub)::eltype(c)
function eval_cond_term(c::Condition, varsub::NamedTuple)
    # BooleanEx is a literal. AbstractBoolExpr <: PnmlExpr can be non-literal (non-ground term).
    isa(term(c), BooleanEx) || @warn term(c) varsub  #! debug
    t = substitute(term(c), varsub, c.net)::PnmlExpr
    @warn t
    eval(toexpr(t, c.net))::eltype(c) # Bool isa Number
end


function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, term(c))
    print(io, ")")
end
