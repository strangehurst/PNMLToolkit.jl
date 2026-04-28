
"""
    struct DeclDict

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Each keyed by REFID symbols.
"""
@kwdef struct DeclDict{V,NS,AS,PAS,MS,PRS,NO,AO,PO,FE,UO} <: AbstractDeclarationDicts
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
    partitionops::Dict{Symbol, PO}
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, FE}

    # SortDeclaration or OperatorDeclaration.
    #! 2025-07-14 moving to SortRefImpl to wrap a REFID and retain type information.
    #! 2025-09-27 moving to Moshi ADT.
    #! 2025-10-12 Remove UserSort. Use NamedSortRef where proper, UserSortRef when needed.

    useroperators::Dict{Symbol, UO}
end  #= struct DeclDict =#

function DeclDict(net::APN)
    N = typeof(net)
    DeclDict(;
               arbitraryoperators = Dict{Symbol, ArbitraryOperator{N}}(),
               arbitrarysorts = Dict{Symbol, ArbitrarySort{N}}(),
               feconstants = Dict{Symbol, Any}(),
               multisetsorts = Dict{Symbol, MultisetSort}(),
               namedoperators = Dict{Symbol, NamedOperator{N}}(),
               namedsorts = Dict{Symbol, NamedSort{N}}(),
               partitionops = Dict{Symbol, Any}(), #TODO value type TBD
               partitionsorts = Dict{Symbol, PartitionSort{N}}(),
               productsorts = Dict{Symbol, ProductSort{N}}(),
               useroperators = Dict{Symbol, UserOperator{N}}(),
               variabledecls = Dict{Symbol, VariableDeclaration{N}}(),)
end

# Explicit propeties allows ignoring metadata.
__dd_fields(dd) = Iterators.map(Fix1(getproperty, dd),
                                (:arbitraryoperators, :arbitrarysorts, :feconstants,
                                 :multisetsorts,  :namedoperators, :namedsorts,
                                 :partitionops, :partitionsorts, :productsorts,
                                 :variabledecls, :useroperators,))

#!Base.isempty(dd::DeclDict{N}) where {N <: APN} = all(isempty, __dd_fields(dd))
Base.isempty(dd::ADDicts) = all(isempty, __dd_fields(dd))
Base.length(dd::ADDicts)  = sum(length,  __dd_fields(dd))

useroperators(dd::ADDicts)  = dd.useroperators
variabledecls(dd::ADDicts)  = dd.variabledecls
namedsorts(dd::ADDicts)     = dd.namedsorts
arbitrarysorts(dd::ADDicts) = dd.arbitrarysorts
partitionsorts(dd::ADDicts) = dd.partitionsorts
namedoperators(dd::ADDicts) = dd.namedoperators
arbitraryops(dd::ADDicts)   = dd.arbitraryoperators
partitionops(dd::ADDicts)   = dd.partitionops
feconstants(dd::ADDicts)    = dd.feconstants
multisetsorts(dd::ADDicts)  = dd.multisetsorts
productsorts(dd::ADDicts)   = dd.productsorts #! put in namedsorts like FiniteItRangeSort

"""
    declarations(dd::ADDicts) -> Iterator

Return an iterator over all the declaration dictionaries' values.
"""
function declarations(dd::ADDicts)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(multisetsorts(dd)),
        values(productsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),
        values(useroperators(dd)),
    ])
end

has_key(dd::ADDicts, dict, key::Symbol)   = haskey(dict(dd),key)

has_variabledecl(dd::ADDicts, id::Symbol)   = has_key(dd, variabledecls, id)
has_namedsort(dd::ADDicts, id::Symbol)      = has_key(dd, namedsorts, id)
has_arbitrarysort(dd::ADDicts, id::Symbol)  = has_key(dd, arbitrarysorts, id)
has_partitionsort(dd::ADDicts, id::Symbol)  = has_key(dd, partitionsorts, id)
has_multisetsort(dd::ADDicts, id::Symbol)   = has_key(dd, multisetsorts, id)
has_productsort(dd::ADDicts, id::Symbol)    = has_key(dd, productsorts, id)
has_namedop(dd::ADDicts, id::Symbol)        = has_key(dd, namedoperators, id)
has_arbitraryop(dd::ADDicts, id::Symbol)    = has_key(dd, arbitraryops, id)
has_partitionop(dd::ADDicts, id::Symbol)    = has_key(dd, partitionops, id)
has_feconstant(dd::ADDicts, id::Symbol)     = has_key(dd, feconstants, id)
has_useroperator(dd::ADDicts, id::Symbol)   = has_key(dd, useroperators, id)

variabledecl(dd::ADDicts, id::Symbol)  = variabledecls(dd)[id]
namedsort(dd::ADDicts, id::Symbol)     = namedsorts(dd)[id]
arbitrarysort(dd::ADDicts, id::Symbol) = arbitrarysorts(dd)[id]
partitionsort(dd::ADDicts, id::Symbol) = partitionsorts(dd)[id]
multisetsort(dd::ADDicts, id::Symbol)  = multisetsorts(dd)[id]
productsort(dd::ADDicts, id::Symbol)   = productsorts(dd)[id]
namedop(dd::ADDicts, id::Symbol)       = namedoperators(dd)[id]
arbitraryop(dd::ADDicts, id::Symbol)   = arbitraryops(dd)[id]
partitionop(dd::ADDicts, id::Symbol)   = partitionops(dd)[id]
feconstant(dd::ADDicts, id::Symbol)    = feconstants(dd)[id]
useroperator(dd::ADDicts, id::Symbol)  = useroperators(dd)[id]

"Return tuple of operator dictionary fields in the Declaration Dictionaries."
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
"Return iterator over operator dictionaries of Declaration Dictionaries."
_ops(dd) = Iterators.map(Fix1(getfield, dd), _op_dictionaries())

"Return tuple of sort dictionary fields in the Declaration Dictionaries."
_sort_dictionaries() = (:namedsorts, :partitionsorts,
                        :arbitrarysorts, :multisetsorts, :productsorts)
"Return iterator over sort dictionaries of Declaration Dictionaries."
_sorts(dd) = Iterators.map(Fix1(getfield, dd), _sort_dictionaries())

"""
    operators(dd::ADDicts)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::ADDicts) = Iterators.flatten(Iterators.map(keys, _ops(dd)))

has_operator(dd::ADDicts, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

"""
    operator(dd::ADDicts, id::Symbol) -> AbstractOperator

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
function operator(dd::ADDicts, opid::Symbol)
    #println("operator($id)")
    for dict in _ops(dd) # Look through all the dictionaries.
        if haskey(dict, opid)
            #@show dict[opid]
            return dict[opid] #! not type stable because each dict holds different type.
        end
    end
    return nothing
end

"""
    verify(dd::ADDicts, verbose::Bool, net::APN) -> Bool
"""
function verify(dd::ADDicts, verbose::Bool, net::APN)
    errors = String[]
    verify!(errors, dd, verbose, net)
    isempty(errors) ||
        error("verify(::ADDicts) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, dd::ADDicts, verbose::Bool, net::APN)
    verbose && println("## verify $(typeof(dd))")
    for k in Iterators.flatten([keys(variabledecls(dd)),
                            keys(namedsorts(dd)),
                            keys(arbitrarysorts(dd)),
                            keys(partitionsorts(dd)),
                            keys(multisetsorts(dd)),
                            keys(productsorts(dd)),
                            keys(partitionops(dd)),
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


function show_sorts(dd::ADDicts)
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

"Look for matching value `x` in dictionary `d`, return key symbol or nothing."
function find_valuekey(d::AbstractDict, x, func=identity)
    id = nothing
    for (k,v) in pairs(skipmissing(d))
        if func(v) == x # Apply `func` to each value, looking for a match.
            id = k
            @warn("found existing $id for $x")
            break
        end
    end
    return id #  Key of matched value or nothing.
end

"""
If `a` is a `NamedSortRef` return its `sortdefinition`, otherwise return `a`.
"""
unwrap_namedsort(a, net) = is_namedsort(a) ? sortdefinition(namedsort(net, a)) : a
