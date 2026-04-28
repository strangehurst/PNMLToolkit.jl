"""
$(TYPEDEF)
Declarations define objects/names that are used for high-level terms
in conditions, inscriptions, markings. The definitions are attached to
PNML nets and/or pages using a PNML Label defined in a <declarations> tag.

- id
- name
- net
"""
abstract type AbstractDeclaration end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = decl.name

function Base.show(io::IO, declare::AbstractDeclaration)
    print(io, nameof(typeof(declare)), "(")
    show(io, pid(declare)); print(io, ", ")
    show(io, name(declare)); print(io, ", ")
    print(io, ")")
end

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct UnknownDeclaration{N <: APN, T <: AnyElement}  <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    nodename::Union{String,SubString{String}}
    content::T
    net::N
end

function Base.show(io::IO, x::UnknownDeclaration)
    print(io, nameof(typeof(x)), "(", repr(x.id), ", ", repr(x.name), ", ",
            repr(x.nodename), x.content, ")")
end

"""
$(TYPEDEF)

See [`Declarations.NamedSort`](@ref), [`Declarations.PartitionSort`](@ref) and
[`Declarations.ArbitrarySort`] as concrete subtypes.
"""
abstract type SortDeclaration <: AbstractSort end #!<: AbstractDeclaration end

"""
$(TYPEDEF)

[`NamedOperator`](@ref). `FEConstant`, [`PartitionElement`](@ref) and
[`ArbitraryOperator`](@ref) are all referenced by `UserOperator`.

`UserOperator` wraps REFID used to access `DeclDict`.
"""
abstract type OperatorDeclaration <: AbstractSort end #!<: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable declaration `<variabledecl>` adds a name string and sort to the `id`
shared with `<variable>` terms in non-ground terms.

EXAMPLE

variabledecls[id] = VariableDeclaration(id, "human name", sort)
"""
struct VariableDeclaration{N <: APN} <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::SortRef
    net::N

    #! Inline Sorts allowed, also <usersort> indirection.
    # Example:
    # <variabledecl id="id12" name="x">
    #     <productsort>
    #       <integer/>
    #       <integer/>
    #     </productsort>
    # </variabledecl>

    #! Sorts serve a similar role as Juia Types.
    #! Sorts are static, Distinct variabledecls may have the same product sort inlined.
end

    # Implementation of variables use a reference to a marking paired with a variable declaration REFID
    # where the sort of the mark matches the VariableDeclaration sort.

    #! If the place sorttype is a product sort
    #   variable's sort will be one of the product member sorts or same product sort
    #   If part of a product sort,
    #       other variables or multiples of this one must combine to form a multiset element.
    # else
    #   variable's sort will be sorttype

    # There will be a value of `sort`
    #   removed from input marking(s) and/or added to output marking(s)
    #   is possible that only one action happens for a variable

    # How to match marking element?
    # A place has one marking, a multiset, with sorttype(place) as basis sort.
    # if sorttype(place) isa productsort
    #   if variable isa productsort
    #       add/remove tuple, with cost
    #   else
    #       need an index into the product to add/remove (Ref(mark,i))
    # else
    #   add/remove sort

    # Find index in tuple? The inscription will be pnml-tuple-valued as will the relevant marking.
    # When parsing a <variable>, identify its enclosing tuple & index #TODO

    # Will PnmlTuple ever have fields mutated? No, marking vectors are not mutated!
    # They evolve and are possibly preserved as part of reachability graph.
    # PnmlTuple fields will be read as part of enabling function (inscription,condition) and firing function.

sortref(vd::VariableDeclaration) = vd.sort::SortRef
#TODO also do `partitionsort`, `arbitrarysort` that function like `namedsort` to add `id` and `name` to something.

function Base.show(io::IO, declare::VariableDeclaration)
    print(io, nameof(typeof(declare)), "(")
    show(io, pid(declare)); print(io, ", ")
    show(io, name(declare)); print(io, ", ")
    show(io, sortref(declare))
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Declaration of a `NamedSort` gives an `id` and `name` to
a concrete instance of a built-in `AbstractSort`.
The sort defined in the XML file may be shared with other named sorts.

See [`MultisetSort`](@ref), [`PartitionSort`](@ref), [`PartitionSort`](@ref).
These are all `Declaration` subtypes in the UML2/RelaxNG parts of ISO 15909-2:2011 which has
a strong _Java_ bias. The text on the standard states they are also sort-like.
We use a different type system.
"""
@auto_hash_equals struct NamedSort{N <: APN, S <: AbstractSort} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S  #! This remains where the concrete sort lives.
    # An instance of: ArbitrarySort, MultisetSort, ProductSort, or BUILT-IN sort!
    net::N

    function NamedSort(id_::Symbol, name_, def_::AbstractSort, net_::APN)
        if isa(def_, NamedSort)
            throw(ArgumentError("NamedSort wraps NamedSort: $id_ $name_ $def_"))
            yield()
        end
        new{typeof(net_), typeof(def_)}(id_, name_, def_, net_)
    end
end

function sortdefinition(namedsort::NamedSort)
    namedsort.def # Instance of concrete sort.
end

sortelements(namedsort::NamedSort, net::APN) = sortelements(sortdefinition(namedsort), net)

Base.eltype(::Type{NamedSort{N, S}}) where {N <: APN, S <: AbstractSort} = eltype(S)

function Base.show(io::IO, nsort::NamedSort)
    print(io, "NamedSort(")
    show(io, pid(nsort)); print(io, ", ")
    show(io, name(nsort)); print(io, ", ")
    io = inc_indent(io)
    show(io, sortdefinition(nsort));
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

See `UserOperator`.

Vector of `VariableDeclaration` for parameters (ordered),
and duck-typed `AbstractTerm` for its body.
"""
struct NamedOperator{N <: APN, T} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    parameter::Vector{VariableDeclaration{N}} # constants,variables with inferred sorts #TODO XXX
    def::T # expression  terms (with inferred output sort) #TODO! XXX how to infer from expression ===
    net::N
end

# Empty parameter vector. Default to return sort of dots.
NamedOperator(id::Symbol, str::AbstractString, net::APN) =
    NamedOperator(id, str, VariableDeclaration{typeof(net)}[], DotConstant(), net)

#operator(no::NamedOperator) = operator(no.net, no.def) #! XXX def is an expression
parameters(no::NamedOperator) = no.parameter
(no::NamedOperator)(vars) = eval(toexpr(no.def, vars, no.net))(parameters(no))

function Base.show(io::IO, op::NamedOperator)
    print(io, nameof(typeof(op)), "(", repr(op.id), ", ", repr(op.name), ", ",
            op.parameter, ", ", op.def,  ")")
end
