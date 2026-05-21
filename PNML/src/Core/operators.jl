#=


getSubterm -> list term
getOutput -> sort
getInput -> list sort

getDeclaration

useroperator -> operator declaration -> builtin operator
Let AbstractOpExpr <: PnmlExpr

finite element constant is 0-ary operator expressed as useroperator wrapping an REFID

`:(feconstant(REFID)())`
locates the FEConstant element in the DeclDict and return its value/id/name(TBD).
there are 4 kinds of operator declarations:
    feconstant, nameoperator, arbitraryoperator, partitionelement
each have different types.
See decldictcore.jl

#~sortdefinition(outsort) isa FEConstant, inexprs, insorts are empty.


eval(::FEXEx)
=#
"""
PNML Operator as Functor

tag maps to func, a functor/function callable. Its arity is same as length of inexprs and insorts
"""
struct Operator{N <: APN} <: AbstractOperator
    tag::Symbol
    func::Union{Function, Type} # Apply `func` to `inexprs`:
    inexprs::Vector{AbstractTerm} #! TermInterface expressions some may be variables (not just ground terms).
    insorts::Vector{UserSortRef} # typeof(inexprs[i]) == eltype(insorts[i])
    outsort::SortRef # wraps REFID Symbol
    metadata::Any
    net::N
    # TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    # TODO all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
end

Operator(t, f, inex, ins, outs; metadata=nothing, net) = Operator(t, f, inex, ins, outs, metadata, net)

tag(op::Operator)     = op.tag # PNML XML tag
inputs(op::Operator)  = op.inexprs #! when should these be eval(toexpr)'ed)
sortref(op::Operator) = identity(op.outsort)::SortRef # output sort of operator. feconstants sort is enclosing enumeration
metadata(op::Operator) = op.metadata
value(op::Operator)   = op(#= parameters? =#)

#? Possible to pass variables at this point? Pass marking vector?
function (op::Operator)(#= parameters? =#)
    #println("\nOperator functor $(tag(op)) arity $(arity(op))") #! debug
    input = map(term -> term(), inputs(op)) #^ evaluate each operator or variable

    @assert all((in,so) -> typeof(in) == eltype(so), zip(input, op.insorts))
    out = op.func(input) #^ apply func to evaluated +/-inputs
    #!@assert isa(out, eltype(x_sortof(op)))
    return out
end

# Like Metatheory.@matchable
TermInterface.isexpr(op::Operator)    = true
TermInterface.iscall(op::Operator)    = true
TermInterface.head(op::Operator)      = Operator #! A constructor
TermInterface.operation(op::Operator) = TermInterface.head(op)
TermInterface.children(op::Operator)  = nothing #getfield.((op,), ($(QuoteNode.(fields)...),))
TermInterface.arguments(op::Operator) = TermInterface.children(op)
TermInterface.arity(op::Operator)     = length(inputs(op))
TermInterface.metadata(op::Operator)  = metadata(op)

# maketerm is used to rewrite terms of the inexprs.
function TermInterface.maketerm(::Type{Operator}, head, children, metadata)
    head(children...)
end


#=
TermInterface.isexpr(op::Operator)    = true
TermInterface.iscall(op::Operator)    = true # users promise that this is only called if isexpr is true.
TermInterface.head(op::Operator)      = tag(op)
TermInterface.children(op::Operator)  = inputs(op)
TermInterface.operation(op::Operator) = op.func
TermInterface.arguments(op::Operator) = inputs(op)
TermInterface.arity(op::Operator)     = length(inputs(op))
TermInterface.metadata(op::Operator)  = nothing

function TermInterface.maketerm(::Type{Operator}, operation, arguments, metadata)
    Operator(iscall, operation, arguments...; metadata)
end
=#

function Base.show(io::IO, t::Operator)
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    show(io, inputs(t))
    print(io, ")")
end

##############################################################
##############################################################

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
boolean_operators = (:or,
                     :and,
                     :not,
                     :imply,
                     :equality,
                     :inequality,
                    )
is_booleanoperator(tag::Symbol) = tag in boolean_operators
# boolean constants true, false


#for sorts: integer, natural, positive
integer_operators = (:addition, # "Addition",
                     :subtraction, # "Subtraction",
                     :mult, # "Multiplication",
                     :div, # "Division",
                     :mod, # "Modulo",
                     :gt, # "GreaterThan",
                     :geq, # "GreaterThanOrEqual",
                     :lt, # "LessThan",
                     :leq, # "LessThanOrEqual",)
                    )
is_integeroperator(tag::Symbol) = tag in integer_operators
#integer_constants = (:one = one(Int), :zero = zero(Int))

multiset_operators = (:add,
                      :all,
                      :numberof,
                      :subtract,
                      :scalarproduct,
                      :empty,
                      :cardnality,
                      :cardnalitiyof,
                      :contains,
                      )
is_multisetoperator(tag::Symbol) = tag in multiset_operators

finite_operators()  = (:lessthan,
                     :lessthanorequal,
                     :greaterthan,
                     :greaterthanorequal,
                     :finiteintrangeconstant,
                     )
"""
    is_finiteoperator(::Symbol) -> Bool

Is tag in `finite_operators()`?
"""
is_finiteoperator(tag::Symbol) = (tag in finite_operators())
partition_operators = (:ltp, :gtp, :partitionelementof)
is_partitionoperator(tag::Symbol) = tag in partition_operators

# these constants are operators
builtin_constants() = Set([:numberconstant, :dotconstant, :booleanconstant])

"""
    is_builtinoperator(::Symbol) -> Bool

Is tag in `builtin_operators()`?
"""
is_builtinoperator(tag::Symbol) = (tag in builtin_constants()) #todo whrat are these?

# boolean_constants = (:true, :false)
"""
    is_operator(tag::Symbol) -> Bool

Predicate to identify operators in the high-level pntd's many-sorted algebra abstract syntaxt tree.

Note: It is not the same as Meta.isoperator. Both work on Symbols. Not expecting any conflict.

  - integer
  - multiset
  - boolean
  - tuple
  - builtin constant
  - useroperator
"""
is_operator(tag::Symbol) = is_integeroperator(tag) ||
                           is_multisetoperator(tag) ||
                           is_booleanoperator(tag) ||
                           is_finiteoperator(tag) ||
                           is_partitionoperator(tag) ||
                           tag in builtin_constants() ||
                           tag === :tuple ||
                           tag === :useroperator


#===============================================================#
#===============================================================#


"Dummy function"
function null_function(inputs)#::Vector{AbstractTerm})
    println("NULL_FUNCTION: ", inputs)
    return nothing
end

"""
    pnml_hl_operator(tag::Symbol) -> callable

Return callable with a single argument, a vector of inputs.
"""
function pnml_hl_operator(tag::Symbol)
    # if haskey(hl_operators, tag)
    #     return hl_operators[tag]
    # else
    #     @error "$tag is not a known hl_operator, return null_function"
    #     return null_function
    # end
    return null_function
end

"""
    pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSortRef}) -> SortRef

Return sort that operator `tag` returns.
"""
function pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSortRef})
    outref = if is_booleanoperator(tag) # 0-arity function is a constant
        UserSortRef(:bool) # BoolSort()
    elseif is_integeroperator(tag) # 0-arity function is a constant
        UserSortRef(:integer) # IntegerSort()
    elseif is_multisetoperator(tag)
        if tag in (:add,)
            length(insorts) >= 2 ||
                @error "pnml_hl_outsort length(insorts) < 2" tag insorts
            last(insorts) # is it always last?
            #todo assert is multiset
        elseif tag in(:all, :numberof, :subtract, :scalarproduct)
            length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
            last(insorts) # is it always last?
        elseif tag === :empty # a "constant" that needs a basis sort
            length(insorts) == 1 || @error "pnml_hl_outsort length(insorts) != 1" tag insorts
            first(insorts)
        elseif tag === :cardnality
            UserSortRef(:natural) # NaturalSort()
        elseif tag === :cardnalitiyof
            UserSortRef(:natural) # NaturalSort()
        elseif tag === :contains
            UserSortRef(:bool) # BoolSort()
        else
            error("$tag not a known multiset operator")
        end
    elseif is_finiteoperator(tag)
        #:lessthan, :lessthanorequal, :greaterthan, :greaterthanorequal, :finiteintrangeconstant
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        @error("enumeration sort needs content")
        first(insorts)
        #todo assert is finite enumeration
        #
    elseif is_partitionoperator(tag)
        #:ltp, :gtp, :partitionelementof
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        first(insorts)
        #todo assert is PartitionSort #! pnml_hl_outsort will need content
    elseif tag === :tuple
        @warn "pnml_hl_outsort does not handle tuple yet"
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        first(insorts)
    elseif tag === :numberconstant
        UserSortRef(:integer)
    elseif tag === :dotconstant
        UserSortRef(:dot)
    elseif tag === :booleanconstant
        UserSortRef(:bool)
    else
         @error "$tag is not a known to pnml_hl_outsort, return NullSort()"
         UserSortRef(:null)
    end
    @warn outref
end

#===============================================================#
#===============================================================#
#===============================================================#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operator wraps a [`REFID`](@ref) to a [`OperatorDeclaration`](@ref).
"""
struct UserOperator{N <: APN} <: AbstractOperator
    declaration::REFID # of a NamedOperator, AbstractOperator.
    net::N
end

# Forward to the NamedOperator or AbstractOperator declaration in the DeclDict.
function (uo::UserOperator)(parameters) # TODO add variables
    if has_operator(decldict(uo.net), uo.declaration)
        op = operator(uo.net, uo.declaration) # Lookup operator in DeclDict.
        r = op(parameters) # Operator objects are functors.
        @warn "found operator for $(uo.declaration)" op r
        return r
    end
    error("found NO operator $(repr(uo.declaration))")
end

basis(uo::UserOperator)  = basis(operator(uo.net, uo.declaration))

function Base.show(io::IO, uo::UserOperator)
    print(io, nameof(typeof(uo)), "(", repr(uo.declaration), ")")
end
