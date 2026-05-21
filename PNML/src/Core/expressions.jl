"""
Expressions Module
"""
module Expressions

import Metatheory
import Multisets: Multiset
import PNML: PNML, basis, sortref, toexpr

using Base: Fix2
using Metatheory: @matchable
using PNML
using PNML: BooleanConstant, DotConstant, FEConstant, FiniteIntRangeConstant,
    NumberConstant, PnmlMultiset, ProductSort, feconstant, mcontains, multiset, operator,
    partitionsort, pnmlmultiset, value, variabledecl
using TermInterface

export expr_sortref, toexpr
# abstract types
export AbstractBoolExpr, AbstractOpExpr, PnmlExpr
# concrete types
export BooleanEx, DotConstantEx, NumberEx, PnmlTupleEx, UserOperatorEx, VariableEx
export Add, Bag, Cardinality, CardinalityOf, Contains, ScalarProduct, Subtract
export And, Equality, Imply, Inequality, Not, Or, Predecessor, Successor
export PartitionElementOf, PartitionGreaterThan, PartitionLessThan
export Addition, Division, Multiplication, Subtraction
export GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Modulo
export Append, Concatenation, StringLength, SubstringEx
export StringGreaterThan, StringGreaterThanOrEqual, StringLessThan, StringLessThanOrEqual
export ListAppend, ListConcatenation, ListEx, ListLength, MemberAtIndex, Sublist


"""
TermInterface expression types.
"""
abstract type PnmlExpr end

"""
TermInterface boolean expression types.

All boolean expressions have a known sort `:bool`.
"""
abstract type AbstractBoolExpr <: PnmlExpr end
basis(::AbstractBoolExpr) = NamedSortRef(:bool)
sortref(::AbstractBoolExpr) = NamedSortRef(:bool)
expr_sortref(b::AbstractBoolExpr, _net) = sortref(b)::SortRef

"""
TermInterface operator expression types.
"""
abstract type AbstractOpExpr <: PnmlExpr end

##################################################################

# Some expressions are ground terms that have no variables.
toexpr(::Nothing, ::NamedTuple, _net) = nothing
toexpr(x::T, ::NamedTuple, _net) where {T <: Number} = identity(x) #! literal
toexpr(s::Symbol, ::NamedTuple, _net) = QuoteNode(s)
function toexpr(t::Tuple, vsub::NamedTuple, _net)
    isempty(vsub) || @error "variable substitutions NOT Empty: " t vsub
    return t
end
function toexpr(t::Multiset, vsub::NamedTuple, _net)
    isempty(vsub) || @error "variable substitutions NOT Empty: " t vsub
    return t
end
toexpr(nc::NumberConstant, ::NamedTuple, _net) = value(nc)
toexpr(c::FiniteIntRangeConstant, ::NamedTuple, _net) = value(c)
toexpr(::DotConstant, ::NamedTuple, _net) = DotConstant()
toexpr(c::BooleanConstant, ::NamedTuple, _net) = value(c)

"""
    expr_sortref(v::PnmlExpr, net) -> SortRef

Return concrete SortRef of PnmlExpr. Sometimes aliased to `basis`, `sortref`.
"""
function expr_sortref end

# TermInterface infrastructure
####################################################################################
##! add *MORE* TermInteface here
####################################################################################

#==================================
 TermInterface
:(arr[i, j]) == maketerm(Expr, :ref, [:arr, :i, :j]) #~ varaible?
:(f(a, b))   == maketerm(Expr, :call, [:f, :a, :b])  #~ operator

:(f()) == maketerm(Expr, :call, [:f])  #~ Operator is a constant when 0-airy callable

variables are used in token firing rules.
Of all enabled firing modes for a transition one is chosen (randomly?).
Marking expressions are made of ground terms (without variables).
Arc inscriptiins and transition condition expessions may include variable terms.
Selecting a firing mode associates tokens with variables.
Transition firing removes tokens from input places and adds tokens into output places.
Variables in input inscription, output inscription and conditions are associated with same token sort.

variables: store in dictionary named "variables", key is PNML ID: maketerm(Expr, :ref, [:variables, :pid])

===================================#
#! From SymbolicUtils.jl NOTE: this is NOT TermInterface (a.k.a. PnmlExpr)
recurse_expr(ex::Expr, varsub::NamedTuple, _net) = Expr(ex.head, recurse_expr.(ex.args, (varsub,))...)
recurse_expr(ex::Any, varsub::NamedTuple, net) = toexpr(ex, varsub, net)

#recurse_expr(ex::PnmlExpr, sub) = Expr(ex.head, recurse_expr.(ex.args, (sub,))...)

"@matchable TermInterface expressions"
function TermInterface.maketerm(::Type{<:PnmlExpr}, head, children, _metadata = nothing)
  head(children...)
end

# head and operation are the structure name, i.e. type/constructor
# children and arguments are the fields of the structure
# arity is length of fields
#

#! From Metatheory.jl. see also SymbolicUtils.substitute for recursive use of maketerm
# function to_expr(x::PatExpr)
#     if iscall(x)
#       maketerm(Expr, :call, [x.quoted_head; to_expr.(arguments(x))], nothing)
#     else
#       maketerm(Expr, operation(x), to_expr.(arguments(x)), nothing)
#     end
# end

# Metatheory.quoted_head: nameof(x) for Union{Function,DataType}), else identity.
# All @matchable structs are iscall() so use Metatheory.quoted_head?
# The other leg is for things that are not callable.
# NB: constructors are callable

# We also need to define equality for our matchables expression. Ignore any metadata.
# function Base.:(==)(a::PnmlExpr, b::PnmlExpr)
#     a.head == b.head && a.args == b.args && a.foo == b.foo #! is this corrct XXX
# end

###################################################################################
# expression constructing a `Variable` wrapping a REFID symbol to a `VariableDeclaration`.
@matchable struct VariableEx <: PnmlExpr
    refid::Symbol
end

function toexpr(op::VariableEx, varsub::NamedTuple, net)
    # `op` holds `refid`, an index into a `DeclDict` operator dictionary.
    # `varsub`
    vsub = varsub[op.refid]
    if vsub isa Symbol
        Expr(:call, feconstant, QuoteNode(net), QuoteNode(vsub))
    else
        :($(vsub))
    end
end

expr_sortref(v::VariableEx, net) = sortref(variabledecl(net, v.refid))::SortRef

function Base.show(io::IO, x::VariableEx)
    print(io, "VariableEx(", x.refid, ")" )
end

###################################################################################
# expression wrapping a REFID symbol used to do operator lookup `operator(net, REFID)`.
@matchable struct UserOperatorEx <: AbstractOpExpr
    refid::Symbol # operator(net, REFID) returns operator callable.
end

function toexpr(op::UserOperatorEx, varsub::NamedTuple, net)
    #@warn "toexpr(op::UserOperatorEx, varsub::NamedTuple)" op varsub operator(net, op.refid)
    Expr(:call, operator, QuoteNode(net), QuoteNode(op.refid)) #
end

function expr_sortref(o::UserOperatorEx, net)
    #todo or other constant/operator, not just feconstant
    return sortref(feconstant(net, o.refid))::SortRef
end

function Base.show(io::IO, x::UserOperatorEx)
    print(io, "UserOperatorEx(", x.refid, ")" )
end


###################################################################################
@matchable struct NamedOperatorEx <: AbstractOpExpr
    refid::Symbol # operator(net, REFID) returns operator callable.
end

function toexpr(op::NamedOperatorEx, varsub::NamedTuple, net)
    Expr(:call, operator, QuoteNode(net), QuoteNode(op.refid)) #
end

function expr_sortref(o::NamedOperatorEx, net)
    #todo or other constant/operator, not just feconstant
    return sortref(feconstant(net, o.refid))::SortRef
end

function Base.show(io::IO, x::NamedOperatorEx)
    print(io, "NamedOperatorEx(", x.refid, ")" )
end


###################################################################################
"""
Bag:
Expression calling pnmlmultiset(basis, x, multi) to construct a [`PnmlMultiset`](@ref).
"""
Bag # Need to avoid @matchable to have docstring
@matchable struct Bag{E <: Any, M <: Any} <: PnmlExpr
    basis::SortRef
    element::E # ground term expression or Multiset
    multi::M # multiplicity expression of element in a multiset
    # Bag(b, x, m) = begin
    #     # if x isa PnmlTupleEx
    #     #     @error "bag element is tuple" b x m
    #     # end
    #     new(b, x, m)
    # end h
end
Bag(b::SortRef, x) = Bag(b::SortRef, x, 1) # singleton multiset
Bag(ms::PnmlMultiset) = Bag(basis(ms), multiset(ms))
Bag(b::SortRef, x::Multiset) = Bag(b::SortRef, x, nothing) # x is a Multiset
Bag(b::SortRef) = Bag(b::SortRef, nothing, nothing) # multiset: one of each element of the basis sort.

sortref(b::Bag) = b.basis
basis(b::Bag) = b.basis
expr_sortref(b::Bag, _net) = sortref(b)::SortRef # also basis

function toexpr(b::Bag, varsub::NamedTuple, net)
    #@show b varsub Expr(:parameters, Expr(:kw,:net, net))
    #^ Warning: b.element can be: `PnmlMultiset`, `tuple`
    #^ tuples are elements of a `ProductSort`
    Expr(:call, pnmlmultiset,
        Expr(:parameters, Expr(:kw, :net, net)), # keyword arguments
        b.basis,
        toexpr(b.element, varsub, net),
        toexpr(b.multi, varsub, net))
end

function Base.show(io::IO, x::Bag)
    print(io, "Bag(",x.basis, ", ", x.element, ", ", x.multi,")"  )
end

###################################################################################
"""
    NumberEx

    TermInterface expression for a `<numberconstant>`.
"""
NumberEx # Need to avoid @matchable to have docstring
@matchable struct NumberEx{T<:Number} <: PnmlExpr
    basis::SortRef # Wraps a sort REFID.
    element::T #
end

toexpr(b::NumberEx{T}, _var::NamedTuple, _net) where {T<:Number} = b.element

basis(x::NumberEx) = x.basis
sortref(x::NumberEx) = x.basis
expr_sortref(x::NumberEx, _net) = basis(x)::SortRef

function Base.show(io::IO, x::NumberEx)
    print(io, "NumberEx(", x.basis, ", ", x.element,")")
end

"""
    BooleanEx

TermInterface expression for a BooleanConstant.
"""
BooleanEx # Need to avoid @matchable to have docstring
@matchable struct BooleanEx <: AbstractBoolExpr
    element::BooleanConstant
end

function toexpr(b::BooleanEx, var::NamedTuple, net)
    if b.element isa BooleanConstant
        QuoteNode(value(b.element))
    else
        toexpr(b.element, var::NamedTuple, net)
    end
end

function Base.show(io::IO, x::BooleanEx)
    print(io, "BooleanEx(", x.element,")")
end

"""
    DotConstantEx

TermInterface expression for a DotSort element.
"""
DotConstantEx # Need to avoid @matchable to have docstring
@matchable struct DotConstantEx <: PnmlExpr
end

basis(::DotConstantEx) = UserSortRef(:dot)
sortref(::DotConstantEx) = UserSortRef(:dot)
expr_sortref(x::DotConstantEx, _net) = basis(x)::SortRef

function toexpr(::DotConstantEx, _var::NamedTuple, _net)
    QuoteNode(DotConstant())
end

function Base.show(io::IO, ::DotConstantEx)
    print(io, "DotConstantEx()")
end

###################################################################################
#& Multiset Operator
# struct All  <: PnmlExpr# #! :all is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end
# struct Empty  <: PnmlExpr #! :empty is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end

#"Multiset add: Bag × Bag -> PnmlMultiset"
@matchable struct Add <: PnmlExpr #^ multiset add uses `+` operator.
    args::Vector{Bag} # >=2 =
end

basis(a::Add) = basis(first(a.args))
sortref(a::Add) = sortref(first(a.args))
expr_sortref(a::Add, net) = expr_sortref(first(a.args), net)::SortRef

function toexpr(op::Add, varsub::NamedTuple, net)
    @assert length(op.args) >= 2
    # Expr(:call, sum, [eval(toexpr(arg, varsub, net)) for arg in op.args])
    :(sum(eval(toexpr(arg, $varsub, $net)) for arg in $(op.args))) # creates PnmlMultiset
end

function Base.show(io::IO, x::Add)
    print(io, "Add(", join(x.args, ", "), ")" )
end

#"Multiset subtract: Bag × Bag -> PnmlMultiset"
@matchable struct Subtract <: PnmlExpr #^ multiset subtract uses `-` operator.
    lhs::Bag
    rhs::Bag
end

basis(a::Subtract) = basis(a.lhs)
sortref(a::Subtract) = sortref(a.lhs)
expr_sortref(a::Subtract, net) = expr_sortref(a.lhs, net)::SortRef

function toexpr(op::Subtract, var::NamedTuple, net)
    Expr(:call, :(-), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Subtract)
    print(io, "Subtract(", x.lhs, ", ", x.rhs, ")" )
end

#"Multiset integer scalar product: ℕ x Bag -> PnmlMultiset"
@matchable struct ScalarProduct <: PnmlExpr #^ multiset scalar multiply uses `*` operator.
    n::Any #! Expression evaluating to integer, use Any to allow `Symbolic` someday.
    bag::Bag #! Expression
end

basis(a::ScalarProduct) = basis(a.bag)
sortref(a::ScalarProduct) = sortref(a.bag)
expr_sortref(a::ScalarProduct, net) = expr_sortref(a.bag, net)::SortRef

function toexpr(op::ScalarProduct, var::NamedTuple, net)
    Expr(:call, PnmlMultiset, basis(op.bag)::SortRef,
        Expr(:call, :(*), toexpr(op.n, var, net), toexpr(op.bag, var, net)))
end

function Base.show(io::IO, x::ScalarProduct)
    print(io, "ScalarProduct(", x.n, ", ", x.bag, ")" )
end

@matchable struct Cardinality <: PnmlExpr #^ multiset cardinality uses `length`.
    bag::Bag # multiset expression
end

basis(::Cardinality) = UserSortRef(:natural)
sortref(::Cardinality) = UserSortRef(:natural)
expr_sortref(a::Cardinality, _net) = sortref(a)::SortRef

function toexpr(op::Cardinality, var::NamedTuple, net)
    Expr(:call, :cardinality, toexpr(op.bag, var, net))
end

function Base.show(io::IO, x::Cardinality)
    print(io, "Cardinality(", x.bag, ")" )
end

@matchable struct CardinalityOf <: PnmlExpr #^ cardinalityof accesses multiset.
    ms::Bag # multiset expression
    refid::Symbol # element of basis sort
end

function toexpr(op::CardinalityOf, var::NamedTuple, net)
    Expr(:call, :multiplicity, toexpr(op.ms, var, net), op.refid)
end

function Base.show(io::IO, x::CardinalityOf)
    print(io, "(CardinalityOf", x.ms, ", ", repr(x.refid), ")" )
end

#"Bag -> Bool"
@matchable struct Contains <: AbstractBoolExpr #^ multiset contains access multiset.
    lhs::Bag # multiset expression #TODO Union{Bag, VariableEx}
    rhs::Bag # multiset expression
end

function toexpr(op::Contains, var::NamedTuple, net)
    Expr(:call, :mcontains, toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Contains)
    print(io, "Contains(", x.lhs, ", ", x.rhs, ")" )
end

#& Boolean Operators
@matchable struct Or <: AbstractBoolExpr #^ Uses `any`.
    args::Vector{AbstractBoolExpr} # >=2 in ISO 15909, but some =1 exist.
end

function toexpr(op::Or, vars::NamedTuple, net)
    :(any(eval(toexpr(arg, $vars, $net)) for arg in $(op.args)))
end

function Base.show(io::IO, x::Or)
    print(io, "Or(", join(x.args, ", "), ")" )
end

@matchable struct And <: AbstractBoolExpr #^ Uses `all`.
    args::Vector{AbstractBoolExpr} # >=2
end

function toexpr(op::And, vars::NamedTuple, net)
    #@show [eval(toexpr(arg, vars, net)) for arg in op.args]
    :(all(eval(toexpr(arg, $vars, $net)) for arg in $(op.args)))
end

function Base.show(io::IO, x::And)
    print(io, "And(", join(x.args, ", "), ")" )
end

@matchable struct Not <: AbstractBoolExpr #^ Uses `!` operator.
    args::Vector{AbstractBoolExpr}
end

# Return true if none of the args are true.
function toexpr(op::Not, vars::NamedTuple, net)
    :(!any(eval(toexpr(arg, $vars, $net)) for arg in $(op.args)))
    #:(!eval(toexpr(first(op.args), $vars, $net)))
end

function Base.show(io::IO, x::Not)
    print(io, "Not(", x.args, ")" )
end

@matchable struct Imply <: AbstractBoolExpr #^ Uses `!` and `||` operators.
    lhs::Any # AbstractBoolExpr
    rhs::Any # AbstractBoolExpr
end

function toexpr(op::Imply, var::NamedTuple, net)
    Expr(:call, :(||), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Imply)
    print(io, "Imply(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Equality <: AbstractBoolExpr #^ Uses `==` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end

function toexpr(op::Equality, var::NamedTuple, net)
    Expr(:call, :(==), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Equality)
    print(io, "Equality(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Inequality <: AbstractBoolExpr #^ Uses `!=` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end

function toexpr(op::Inequality, var::NamedTuple, net)
    Expr(:call, :(!=), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Inequality)
    print(io, "Inequality(", x.lhs, ", ", x.rhs, ")" )
end


#& Cyclic Enumeration Operators
@matchable struct Successor <: PnmlExpr
    arg::Any
end

toexpr(op::Successor, var::NamedTuple, net) = error("implement me arg ", repr(op.arg))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
#! Expr(:call, toexpr(c, m.head), toexpr.(Ref(c), m.args)...)

function Base.show(io::IO, x::Successor)
    print(io, "Successor(", x.arg, ")" )
end

@matchable struct Predecessor <: PnmlExpr
    arg::Any
end

toexpr(op::Predecessor, var::NamedTuple, net) = error("implement me arg ", repr(op.arg))

function Base.show(io::IO, x::Predecessor)
    print(io, "Predecessor(", x.arg, ")" )
end


#& FiniteIntRange Operators work on integrs in spec, we extend to Number

#! Use the Integer version. The difference is how the number is accessed!
# struct LessThan{T <: Number} <: PnmlExpr #! Use the Integer version.
# struct LessThanOrEqual{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThan{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThanOrEqual{T} <: PnmlExpr #! Use the Integer version.


#& Integer in standard # we extend to `Number`, really anything that supports the + operator used:)
@matchable struct Addition <: PnmlExpr #? Use `+` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Addition, net) = expr_sortref(a.lhs, net)::SortRef

function toexpr(op::Addition, var::NamedTuple, net)
    Expr(:call, :(+), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Addition)
    print(io, "Addition(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Subtraction <: PnmlExpr #? Use `-` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Subtraction, net) = expr_sortref(a.lhs, net)::SortRef

function toexpr(op::Subtraction, var::NamedTuple, net)
    Expr(:call, :(-), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Subtraction)
    print(io, "Subtraction(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Multiplication <: PnmlExpr #? Use `*` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Multiplication, net) = expr_sortref(a.lhs, net)::SortRef

function toexpr(op::Multiplication, var::NamedTuple, net)
    Expr(:call, :(*), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Multiplication)
    print(io, "Multiplication(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Division <: PnmlExpr #? Use `div` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Division, net) = expr_sortref(a.lhs, net)::SortRef

function toexpr(op::Division, var::NamedTuple, net)
    Expr(:call, :div, toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Division)
    print(io, "Division(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThan <: AbstractBoolExpr #? Use `>` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::GreaterThan, var::NamedTuple, net)
    Expr(:call, :(>), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::GreaterThan)
    print(io, "GreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThanOrEqual <: AbstractBoolExpr #? Use `>=` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::GreaterThanOrEqual, var::NamedTuple, net)
    Expr(:call, :(>=), toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::GreaterThanOrEqual)
    print(io, "GreaterThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThan <: AbstractBoolExpr #? Use `<` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::LessThan, var::NamedTuple, net)
    Expr(:call, :(<), toexpr(op.lhs, var, net), toexpr(op.rhs, var), net)
end

function Base.show(io::IO, x::LessThan)
    print(io, "LessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThanOrEqual <: AbstractBoolExpr #? Use `<=` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::LessThanOrEqual, var::NamedTuple, net)
    Expr(:call, :(<=), toexpr(op.lhs, var, net), toexpr(op.rhs, var), net)
end

function Base.show(io::IO, x::LessThanOrEqual)
    print(io, "LessThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Modulo <: PnmlExpr #? Use `mod` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Modulo, net) = sortref(a.lhs)::SortRef

function toexpr(op::Modulo, var::NamedTuple, net)
    Expr(:call, :mod, toexpr(op.lhs, var, net), toexpr(op.rhs, var, net))
end

function Base.show(io::IO, x::Modulo)
    print(io, "Modulo(", x.lhs, ", ", x.rhs, ")" )
end


#& Partition
# PartitionElement is an operator declaration. Is this a literal? See PartitionElementOf.
@matchable struct PartitionElementOp <: AbstractOpExpr #! Same as PartitionElement, for term rerwite?
    id::Symbol
    name::Union{String,SubString{String}}
    refs::Vector{Symbol} # to FEConstant
    partition::Symbol
end

expr_sortref(a::PartitionElementOp, net) = sortref(partitionsort(net, a.partition))::SortRef

toexpr(op::PartitionElementOp, var::NamedTuple, net) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionElementOp)
    print(io, "PartitionElementOp(", x.id, ", ", x.name, ", ", x.refs, ")" )
end

#> comparison functions on the partition elements which is based on
#> the order in which they occur in the declaration of the partition
@matchable struct PartitionLessThan <: AbstractBoolExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
end

function ltp_impl(lhs, rhs)
    #@warn "ltp_impl" lhs  rhs
    lhs < rhs
end

toexpr(op::PartitionLessThan, var::NamedTuple, net) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionLessThan)
    print(io, "PartitionLessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct PartitionGreaterThan <: AbstractBoolExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
    # return AbstractBoolExpr
end

function gtp_impl(lhs, rhs)
    #@warn "gtp_impl" lhs  rhs
    lhs > rhs
end

function toexpr(op::PartitionGreaterThan, varsub::NamedTuple, net)
    #@warn "toexpr PartitionGreaterThan" op varsub
    Expr(:call, gtp_impl, toexpr(op.lhs, varsub, net), toexpr(op.rhs, varsub, net))
end
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionGreaterThan)
    print(io, "PartitionGreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

# 0-arity despite the refpartition
@matchable struct PartitionElementOf <: PnmlExpr
    arg::Any # TODO variable that should be a feconstant
    refpartition::Symbol # TODO! wrap in PartitionSortRef
end

expr_sortref(a::PartitionElementOf, net) = sortref(partitionsort(net, a.refpartition))::SortRef

function _peo_impl(fec::FEConstant, refpart, net)
    #@warn "peo_impl" lhs refpart
    p = partitionsort(net, refpart)
    # look for value of fec in findfirst(e -> contains(e, fec()), p.elements)
    findfirst(Fix2(PNML.Declarations.contains, fec()), p.elements)
end

function toexpr(op::PartitionElementOf, varsub::NamedTuple, net)
    #@warn "toexpr PartitionElementOf" op varsub
    Expr(:call, _peo_impl, toexpr(op.arg, varsub, net), QuoteNode(op.refpartition), net)
end
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionElementOf)
    print(io, "PartitionElementOf(", x.arg, ", ", x.refpartition, ")" )
end

#& Strings
@matchable struct Concatenation{T <: AbstractString} <: PnmlExpr
    args::Vector{T} # =2
    # use ?
end

@matchable struct Append{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringLength{T <: AbstractString} <: PnmlExpr
    arg::T
    # use ?
end

@matchable struct StringLessThan{T <: AbstractString} <: AbstractBoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringLessThanOrEqual{T <: AbstractString} <: AbstractBoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThan{T <: AbstractString} <: AbstractBoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThanOrEqual{T <: AbstractString} <: AbstractBoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct SubstringEx{T <: AbstractString} <: PnmlExpr
    str::T
    start::Int
    length::Int
    # use ?
end


#&=========================================================================================
#& Lists

#
@matchable struct ListEx <: PnmlExpr
    basis::SortRef
    els::Vector{Any} #
end

function toexpr(op::ListEx, varsub::NamedTuple, net)
    #@warn "toexpr ListEx" op varsub
    els = [eval(toexpr(arg, varsub, net)) for arg in op.els]
    Expr(:vect, els...)
end

function Base.show(io::IO, x::ListEx)
    print(io, "ListEx(", x.basis, ", ", x.els, ")" )
end



@matchable struct ListLength <: PnmlExpr
end

@matchable struct ListConcatenation <: PnmlExpr
end

@matchable struct Sublist <: PnmlExpr
end

@matchable struct ListAppend <: PnmlExpr
end

@matchable struct MemberAtIndex <: PnmlExpr
end

#--------------------------------------------------------------
"""
    PnmlTupleEx(args::Vector)

`PnmlTupleEx` `TermInterface` expression object wraps an ordered collection of `PnmlExpr` objects.
There is a related `ProductSort`: an ordered collection of sorts.
Each tuple element will have the same sort as the corresponding product sort.

NB: ISO 15909 Standard considers Tuple to be an Operator.
"""
PnmlTupleEx

@matchable struct PnmlTupleEx <: PnmlExpr #{N, T<:PnmlExpr}
    args::Vector{Any} # >=2 subterms
end

# <tuple> is an operator.
# The sort of a tuple is a tuple of its element's sorts (a.k.a ProductSort).
# Find the ProductSortRef
function expr_sortref(tup::PnmlTupleEx, net)
    exsort = ProductSort(tuple(expr_sortref.(tup.args, Ref(net))...), net)
    for (sortid,ps) in pairs(PNML.productsorts(net))
        #!@show ps
        if length(exsort) == length(ps) && PNML.Sorts.equalSorts(net, exsort, ps)
            return ProductSortRef(sortid)
        end
    end
    error("no productsort for tuple expression $(tup)")
end

function toexpr(op::PnmlTupleEx, varsub::NamedTuple, net)
    @assert length(op.args) >= 2
    # @warn("toexpr PnmlTupleEx", op.args, varsub,
    #         toexpr.(op.args, Ref(varsub)),
    #         (eval ∘ toexpr).(op.args, Ref(varsub)),)
    #~ Must allow for mixed constant (0-ary operator) and variable expressions.
    #? Do input arc inscriptions ever have constant expressions?
    #* Defaults for example.
    #! Start by assuming tuples are either all constants or all variables.
    # foreach(Fix2(getproperty, :refid), op.args)
    # Extract tuple of sort REFIDs from expressions.  Map to ProductSort

    # @show psorts = tuple((expr_sortref.(op.args, net))...)
    # args = if all(Fix2(isa, Symbol), op.args)
    #     map(vexp -> feconstant(vexp.refid), op.args)

    args = op.args
    # if all(Fix2(isa, VariableEx), op.args)
    #     # toexpr is to QuoteNode holding REFID.
    #     map(vexp -> feconstant(vexp.refid), op.args)
    # else
    #     op.args
    # end
    # @show args
    # PnmlTuple{psorts}(x...)
    Expr(:call, tuple, toexpr.(args, Ref(varsub), Ref(net))...)
end

# #? Would this be a candidate for rewriting?
# _deref_variable(v::Any) = identity(v) # Bet that it is an operator  expression -> FEConstant!
# _deref_variable(vexp::VariableEx) = feconstant(net, vexp.refid)

function Base.show(io::IO, x::PnmlTupleEx)
    print(io, "PnmlTuplEx(", x.args, ")" )
end



##########################################################################################
# LiteralExpr from SymbolicUtils code.jl. Used by
# ModelingToolkit src/structural_transformation/codegen.jl and Symbolics.
# The "Literal" here is a reference to being non-Symbolic.
#
# Any term rewriting should be done before toexpr is called.
# For `st` we use variable substitution dictionary (or NamedTuple)
#
# ModelingToolkit has a Differential Equation focus,
# supports Real, Complex, (and maybe Quarterions, Octoions).
# And Linear Algebra.
# PNML is doing high-level petri nets with a multi-sorted algebra and a XML markup language.
#
# code.jl also uses @matchable, calling toexpr on the likes of
#   Assignment, Let, Func, MakeArray, etc.
#
##########################################################################################

"""
    LiteralExpr(ex)

Literally `ex`, an `Expr`. `toexpr` on `LiteralExpr` recursively calls
`toexpr` on any interpolated symbolic expressions.
"""
struct LiteralExpr
    ex
end
toexpr(exp::LiteralExpr, varsub::NamedTuple, net) = recurse_expr(exp.ex, varsub, net)

"""
    substitute(expr, dict)

Recursivly substitute a VariableEx with its the value from `var`.
The values in `var` will be ground terms of a place's sorttype.
These values are from the current marking vector.
```
"""
function substitute(expr::PnmlExpr, var::NamedTuple)
    expr isa VariableEx && return var[expr.refid]

    if iscall(expr) # all @matchable structs
        #~ Always substitute operation and arguments.
        op = substitute(operation(expr), var) #? is operation ever an expression?
        args = map(x->substitute(x, var), arguments(expr))

        #~ Rewrite term after substitutions
        maketerm(typeof(expr), op, args, metadata(expr))
    else
        expr #~ not a call, leave it alone
    end
end
# maketerm(typeof(expr), operation(expr), map(x->recurse_expr(x, dict), arguments(expr)), metadata(expr))
end # module Expressons
