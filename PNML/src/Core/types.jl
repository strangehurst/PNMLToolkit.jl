# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

"""
Alias for Symbol that refers to something with an ID Symbol.
"""
const REFID = Symbol

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)
"""
abstract type AbstractPnmlNet end
"""
Alias for AbstractPnmlNet.
"""
const APN = AbstractPnmlNet

"""
$(TYPEDEF)
"""
abstract type AbstractDeclarationDicts end
"""
Alias for AbstractDeclarationDicts.
"""
const ADDicts = AbstractDeclarationDicts

"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.

Expected interface is for every concrete object to have at least these fields:
    - id
    - namelabel
    - graphics
    - extralabels
    - toolspecinfos
"""
abstract type AbstractPnmlObject end

"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).

Expected interface is for every concrete label to have at least these fields:
    - text
    - graphics
    - toolspecinfos
    - net
"""
abstract type AbstractLabel end

"""
$(TYPEDEF)
Label that may be displayed.
Differs from an Attribute Label by possibly having a [`Graphics`](@ref) field.
We do not implement a separate Attribute type since `graphics` is optional.
"""
abstract type Annotation <: AbstractLabel end

"""
$(TYPEDEF)
Annotation label that adds <structure>.
"""
abstract type HLAnnotation <: AbstractLabel end

#--------------------------------------------------------------------
# AbstractPnmlObject
#--------------------------------------------------------------------

function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
    prop_name === :id   && return getfield(o, :id)::Symbol
#     prop_name === :pntd && return getfield(o, :pntd)::APNTD #! abstract
    prop_name === :namelabel && return getfield(o, :namelabel)::Maybe{Name}
    prop_name === :graphics  && return getfield(o, :graphics)::Maybe{Graphics}
    prop_name === :extralabels && return getfield(o, :extralabels)::LittleDict{Symbol,Any}
    prop_name === :toolnfos  && return getfield(o, :toolspecinfos)::Maybe{Vector{ToolInfo}}

    return getfield(o, prop_name)
end

#! 2026-01-09 change pid, name from ::AbstractPnmlObject to ::Any
pid(x) = x.id::Symbol

"""
    name(x) -> String

If `x` has a `namelabel`,return its `text`,
else return any `name` field. Default to `string()`
"""
function name(x)
    if hasproperty(x, :namelabel) && !isnothing(x.namelabel)
        text(x.namelabel)
    elseif hasproperty(x, :name)
        x.name
    else
        string()
    end
end

"Return `text` property or empty string."
function text(x)
    if hasproperty(x, :text)
        x.text
    else
        string()
    end
end

labels(o) = hasproperty(o, :extralabels) ? o.extralabels : nothing

has_tools(o::AbstractPnmlObject) = hasproperty(o, :toolspecinfos) && !isnothing(o.toolspecinfos)
toolinfos(o::AbstractPnmlObject) = hasproperty(o, :toolspecinfos) ? o.toolspecinfos : nothing

has_graphics(o::AbstractPnmlObject) = hasproperty(o, :graphics) && !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics

"""
    get_label(x, tag) -> Maybe{AbstractLabel}

`x` is anyting that supports 'labels'.
`tag` is the tag of the xml label element.
"""
function get_label(x, tag::Union{Symbol, String, SubString{String}})
    isnothing(x) && throw(ArgumentError("argument 'x' is nothing"))
    l = labels(x)::AbstractDict
    return if haskey(l, tag)
        @inbounds(l[tag])
    else
        nothing
    end
end

#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type AbstractPnmlNode <: AbstractPnmlObject end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode <: AbstractPnmlObject end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    name === :ref && return getfield(rn, :ref)::Symbol
    return getfield(rn, name)
end

refid(r::ReferenceNode) = r.ref


#--------------------------------------------
# Terms & Sorts
#--------------------------------------------
"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

Concrete terms are `Variable` and `Operator` found within the <structure> element of a label.
They are parsed into `PnmlExpr` as `TermInterface` expressions thar are evaluated during
the enabling and firing rule.

Notably, a `Term` is not a `PnmlLabel` (or a PNML Label).

# References
See also [`Declaration`](@ref), [`Labels.SortType`](@ref), [`AbstractDeclaration`](@ref).

[Term_(logic)](https://en.wikipedia.org/wiki/Term_(logic)):
> A first-order term is recursively constructed from constant symbols, variables and function symbols.

> Besides in logic, terms play important roles in universal algebra, and rewriting systems.

> more convenient to think of a term as a tree.

> A term that doesn't contain any variables is called a ground term

> When the domain of discourse contains elements of basically different kinds,
> it is useful to split the set of all terms accordingly.
> To this end, a sort (sometimes also called type) is assigned to each variable and each constant symbol,
> and a declaration...of domain sorts and range sort to each function symbol....

[Type_theory](https://en.wikipedia.org/wiki/Type_theory)
> term in logic is recursively defined as a constant symbol, variable, or a function application, where a term is applied to another term

> if t is a term of type σ → τ, and s is a term of type σ, then the application of t to s, often written (t s), has type τ.

[Lambda terms](https://en.wikipedia.org/wiki/Lambda_calculus#Lambda_terms):
> The term redex, short for reducible expression, refers to subterms that can be reduced by one of the reduction rules.

See [Metatheory](https://github.com/JuliaSymbolics/Metatheory.jl)
and [SymbolicUtils](https://github.com/JuliaSymbolics/SymbolicUtils.jl)

"""
abstract type AbstractTerm end

"""
$(TYPEDEF)
Variables are part of the high-level pnml many-sorted algebra.
"""
abstract type AbstractVariable <: AbstractTerm end

"""
$(TYPEDEF)
Operators are part of the high-level pnml many-sorted algebra.

> ...can be a built-in constant or a built-in operator, a multiset operator which among others
> can construct a multiset from an enumeration of its elements, or a tuple operator.
> Each operator has a sequence of sorts as its input sorts, and exactly one output sort,
> which defines its signature.

See [`NamedOperator`](@ref) and [`ArbitraryOperator`](@ref).
"""
abstract type AbstractOperator <: AbstractTerm end

# Expect each operator instance to have fields:
# - expression (PnmlExpr <: TermInterfce) that evaluates to an instance of output sort.
# - ordered sequence of zero or more input sorts
# - ordered sequence of zero or more subterms
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a 0-ary operator is a constant.


####################################################################
# """
#     SubstitutionDict = OrderderDict{REFID, Multiset}

# Variable ID used to access marking value. One for each variable of a transition.

# A higher level will produce candidate consistent substitution dictionaries,
# filtering them by one or more guards. `Condition` callable object guards are part of
# selecting enabled transition => subsitution dictionary firing pairs.
# The firing rule selects one of the firing pairs, using the substitution dictionary to
# construct postset marking updates.
# """
# const SubstitutionDict = OrderedDict{REFID, Multiset}

"""
    AbstractSort
"""
abstract type AbstractSort end

abstract type AbstractDeclDict end

"""
    $(TYPEDEF)

An EnumX.jl enum used to distinguish arc types.
"""
@enumx ArcTypeEnum Normal Inhibitor Read Reset

"""
    toexpr(ex::PnmlExpr, varsubs::NamedTuple{Symbol,Any}, net) -> Expr

Return `Expr` constructed from `ex`. Calls `toexpr` on any contained terms.
`varsubs` used to replace variables in expressions with values from current marking vector.
"""
function toexpr end
