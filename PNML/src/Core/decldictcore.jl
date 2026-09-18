"""
$(TYPEDEF)
"""
abstract type AbstractDeclarationDicts end
"""
Alias for AbstractDeclarationDicts.
"""
const ADDicts = AbstractDeclarationDicts

"""
    struct DeclDicts

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Each keyed by REFID symbols.
"""
@kwdef struct DeclDicts{V,NS,AS,PAS,MS,PRS,NO,AO,FE,UO} <: AbstractDeclarationDicts
    """
        Holds [`VariableDeclaration`](@ref).
        A [`Variable`](@ref) is used to locate the declaration's name and sort.
    """
    variabledecls::Dict{Symbol, V}

    # Built-in sorts live in named sorts. A sort declaration.
    namedsorts::Dict{Symbol, NS}
    arbitrarysorts::Dict{Symbol, AS}
    partitionsorts::Dict{Symbol, PAS}

    multisetsorts::Dict{Symbol, MS}
    productsorts::Dict{Symbol, PRS}

    # OperatorDecls
    # namedoperators are also used to access built-in operators.

    namedoperators::Dict{Symbol, NO}
    arbitraryoperators::Dict{Symbol, AO}
    # PartitionElement is an operator, there are other built-in operators
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, FE}

    useroperators::Dict{Symbol, UO}
end  #= struct DeclDicts =#

function decldicts(net::AbstractPnmlNet)
    N = typeof(net)
    DeclDicts(;
               arbitraryoperators = Dict{Symbol, ArbitraryOperator{N}}(),
               arbitrarysorts = Dict{Symbol, ArbitrarySort{N}}(),
               feconstants = Dict{Symbol, FEConstant}(),
               multisetsorts = Dict{Symbol, MultisetSort}(),
               namedoperators = Dict{Symbol, NamedOperator{N}}(),
               namedsorts = Dict{Symbol, NamedSort{N}}(),
               partitionsorts = Dict{Symbol, PartitionSort{N}}(),
               productsorts = Dict{Symbol, ProductSort{N}}(),
               useroperators = Dict{Symbol, UserOperator{N}}(),
               variabledecls = Dict{Symbol, VariableDeclaration{N}}(),)
end

# Explicit propeties allows ignoring metadata.
__dd_fields(dd) = Iterators.map(Fix1(getproperty, dd),
                                (:arbitraryoperators, :arbitrarysorts, :feconstants,
                                 :multisetsorts,  :namedoperators, :namedsorts,
                                 :partitionsorts, :productsorts,
                                 :variabledecls, :useroperators,))

Base.isempty(dd::DeclDicts) = all(isempty, __dd_fields(dd))
Base.length(dd::DeclDicts)  = sum(length,  __dd_fields(dd))

useroperators(dd::DeclDicts)  = dd.useroperators
variabledecls(dd::DeclDicts)  = dd.variabledecls
namedsorts(dd::DeclDicts)     = dd.namedsorts
arbitrarysorts(dd::DeclDicts) = dd.arbitrarysorts
partitionsorts(dd::DeclDicts) = dd.partitionsorts
namedoperators(dd::DeclDicts) = dd.namedoperators
arbitraryops(dd::DeclDicts)   = dd.arbitraryoperators
feconstants(dd::DeclDicts)    = dd.feconstants
multisetsorts(dd::DeclDicts)  = dd.multisetsorts
productsorts(dd::DeclDicts)   = dd.productsorts #! put in namedsorts like FiniteItRangeSort

"""
    declarations(dd::DeclDicts) -> Iterator

Return an iterator over all the declaration dictionaries' values.
"""
function declarations(dd::DeclDicts)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(multisetsorts(dd)),
        values(productsorts(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),
        values(useroperators(dd)),
    ])
end

has_key(dd::DeclDicts, dict, key::Symbol)   = haskey(dict(dd), key)::Bool

has_variabledecl(dd::DeclDicts, id::Symbol)   = has_key(dd, variabledecls, id)
has_namedsort(dd::DeclDicts, id::Symbol)      = has_key(dd, namedsorts, id)
has_arbitrarysort(dd::DeclDicts, id::Symbol)  = has_key(dd, arbitrarysorts, id)
has_partitionsort(dd::DeclDicts, id::Symbol)  = has_key(dd, partitionsorts, id)
has_multisetsort(dd::DeclDicts, id::Symbol)   = has_key(dd, multisetsorts, id)
has_productsort(dd::DeclDicts, id::Symbol)    = has_key(dd, productsorts, id)
has_namedop(dd::DeclDicts, id::Symbol)        = has_key(dd, namedoperators, id)
has_arbitraryop(dd::DeclDicts, id::Symbol)    = has_key(dd, arbitraryops, id)
has_feconstant(dd::DeclDicts, id::Symbol)     = has_key(dd, feconstants, id)
has_useroperator(dd::DeclDicts, id::Symbol)   = has_key(dd, useroperators, id)

variabledecl(dd::DeclDicts, id::Symbol)  = variabledecls(dd)[id]
namedsort(dd::DeclDicts, id::Symbol)     = namedsorts(dd)[id]
arbitrarysort(dd::DeclDicts, id::Symbol) = arbitrarysorts(dd)[id]
partitionsort(dd::DeclDicts, id::Symbol) = partitionsorts(dd)[id]
multisetsort(dd::DeclDicts, id::Symbol)  = multisetsorts(dd)[id]
productsort(dd::DeclDicts, id::Symbol)   = productsorts(dd)[id]
namedop(dd::DeclDicts, id::Symbol)       = namedoperators(dd)[id]
arbitraryop(dd::DeclDicts, id::Symbol)   = arbitraryops(dd)[id]
feconstant(dd::DeclDicts, id::Symbol)    = feconstants(dd)[id]
useroperator(dd::DeclDicts, id::Symbol)  = useroperators(dd)[id]

"Return tuple of operator dictionary fields in the Declaration Dictionaries."
_op_dictionaries() = (:namedoperators, :feconstants, :arbitraryoperators)
"Return iterator over operator dictionaries of Declaration Dictionaries."
_ops(dd) = Iterators.map(Fix1(getfield, dd), _op_dictionaries())

"Return tuple of sort dictionary fields in the Declaration Dictionaries."
_sort_dictionaries() = (:namedsorts, :partitionsorts,
                        :arbitrarysorts, :multisetsorts, :productsorts)
"Return iterator over sort dictionaries of Declaration Dictionaries."
_sorts(dd) = Iterators.map(Fix1(getfield, dd), _sort_dictionaries())

"""
    operators(dd::DeclDicts)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDicts) = Iterators.flatten(Iterators.map(keys, _ops(dd)))

has_operator(dd::DeclDicts, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

"""
    operator(dd::DeclDicts, id::Symbol) -> AbstractOperator

Return operator TermInterface expression for `id`.
    `toexpr(::AbstractOpExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

Operator Declarations include:
:namedoperator, :feconstant, :partitionelement, :arbitraryoperator
with types
`NamedOperator`, `FEConstant`, `PartitionElement`, `ArbitraryOperator`.
These define operators of different types that are placed into separate dictionaries.


#! AbstractDeclarations and AbstractTerms are "parallel" semi-overlapping hierarchies
#! in the UML, with AbstractTerms divided into AbstractOperators and AbstractVariables.

#! AbstractTerms overlap with OperatorDeclaration and VariableDeclaration .
#! AbstractSorts overlap with SortDeclaration.

#! Consider OperatorDeclaration, SortDeclaration to be generators of concrete subtypes of
#! AbstractOperator, AbstractSort.
#! Without multiple inheritance, this cannot be expressed in a Julia type hiearchy.

#! What the 'parse_*' of these <declaration> XML elements produce is
#! a concrete AbstractOperator, AbstractSort.

#! VariableDeclaration and Variable are not hiearchies.
#! A `Varaible` is a reference to a `VariableDeclaration`,
#! The variable declaration is a id, name, sort triplet.
#! Where the sort is a SortRefImpl or a sort declaration.

useroperator(REFID) is used to locate the operator definition,
when it is found in `feconstants()`, is a callable returning a `FEConstant` literal.

    `toexpr(::FEConstantEx, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

The FEConstant operators defined by the declaration do not have a distinct type name in the standard.
Note that a FEConstant's value in the standard is its identity.
We could use `objectid(::FEConstant)`, `REFID` or `name` for output value.
Output sort of op is FEConstant.

Other `OperatorDeclaration` dictionarys also hold `TermInterface` expressions accessed by

    `toexpr(::PnmlExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

where `PnmlExpr` is the `TermInterface` to match `OperatorDeclaration`.
With output sort to match `OperatorDeclaration` .

#TODO named operator input variables and their sorts

#TODO partition element

#TODO arbitrary opearator

#TODO built-in operators
"""
function operator(dd::DeclDicts, opid::Symbol)
    for dict in _ops(dd) # Look through all the dictionaries.
        if haskey(dict, opid)
            return dict[opid] #! not type stable because each dict holds different type.
        end
    end
    return nothing
end

"""
    verify(dd::DeclDicts, verbose::Bool, net::AbstractPnmlNet) -> Bool
"""
function verify(dd::DeclDicts, verbose::Bool, net::AbstractPnmlNet)
    errors = String[]
    verify!(errors, dd, verbose, net)
    isempty(errors) ||
        error("verify(::DeclDicts) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, dd::DeclDicts, verbose::Bool, net::AbstractPnmlNet)
    verbose && println("## verify $(typeof(dd))")
    for k in Iterators.flatten([keys(variabledecls(dd)),
                            keys(namedsorts(dd)),
                            keys(arbitrarysorts(dd)),
                            keys(partitionsorts(dd)),
                            keys(multisetsorts(dd)),
                            keys(productsorts(dd)),
                            keys(namedoperators(dd)),
                            keys(arbitraryops(dd)),
                            keys(feconstants(dd)),
                            keys(useroperators(dd))])
        isregistered(registry_of(net), k) ||
            push!(errors, string("unregisrered id $k"))
    end
    for v in values(partitionsorts(dd))
        #@show v
        verify!(errors, v, verbose, net)
    end
    return errors
end

function show_sorts(dd::DeclDicts)
    println("show_sorts")
    #@show _sort_dictionaries()
    foreach(_sort_dictionaries()) do s
        println("# ", s, ", length = ", length(getfield(dd, s)))
        foreach(getfield(dd, s)) do d
            println(repr(d.first), " => ", d.second)
        end
    end
    println()
end
