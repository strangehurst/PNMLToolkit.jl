"""
    pnmlmultiset(basis::SortRef, x::T, multi::Int=1) -> PnmlMultiset{T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset{T} wraps a Multisets.Multiset{T} where `T` is the basis sort element type.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants (and 0-arity operators) defined that must be multisets
since HL markings are multisets.

See `Bag` for expression that returns this data structure.

"multi`x" is text representation of the `<numberof>` operator that produces a multiset.
As does `<all>` operator.
"""
@struct_hash_equal struct PnmlMultiset{T, N <: AbstractPnmlNet} <: AbstractPnmlMultiset #! data type
    basis_ref::SortRef # REFID indirection
    mset::Multiset{T}
    net::N #! RefValue{<:Any} # = Ref{Any}()

    # function PnmlMultiset{T}(m::Multiset{T}) where {T}
    #     new{T, typeof(net)}(m, net) #todo assert basis_ref and T match.
    # end
end

"""
    sortelements(ms::PnmlMultiset, net::AbstractPnmlNet) -> iterator

Iterates over elements of the basis sort. __May not be a finite sort!__
"""
sortelements(pms::PnmlMultiset, net::AbstractPnmlNet) = sortelements(basis(pms), net)

"""
    multiset(ms::PnmlMultiset) -> Multiset
Access wrapped multiset.
"""
multiset(ms::PnmlMultiset) = ms.mset

"""
    multiplicity(ms::PnmlMultiset, x) -> Integer
    multiplicity(ms::Number, x) -> Number
"""
multiplicity(ms::PnmlMultiset, x) = multiset(ms)[x]

"""
    cardinality(ms::PnmlMultiset, x) -> Integer
"""
cardinality(ms::PnmlMultiset) = length(multiset(ms))
cardinality(ms::Number) = ms

Base.length(ms::PnmlMultiset) = length(multiset(ms))
Base.keys(ms::PnmlMultiset) = keys(multiset(ms))
Base.values(ms::PnmlMultiset) = values(multiset(ms))
Base.iterate(ms::PnmlMultiset, ss) = iterate(multiset(ms), ss)
Base.iterate(ms::PnmlMultiset) = iterate(multiset(ms))
Base.convert(::Type{Bool}, ::PnmlMultiset{DotConstant}) = true

Base.:(==)(c::PnmlMultiset{DotConstant}, n::Number)  = convert(Bool, c) == n
Base.:(==)( n::Number, c::PnmlMultiset{DotConstant}) = n == convert(Bool, c)

Base.isequal(c::PnmlMultiset{DotConstant}, n::Number)  = isequal(convert(Bool, c), n)
Base.isequal( n::Number, c::PnmlMultiset{DotConstant}) = isequal(n, convert(Bool, c))

Base.isless(c::PnmlMultiset{DotConstant}, n::Number)  = isless(convert(Bool, c), n)
Base.isless( n::Number, c::PnmlMultiset{DotConstant}) = isless(n, convert(Bool, c))

Base.:(<)(c::PnmlMultiset{DotConstant}, n::Number)  = convert(Bool, c)< n
Base.:(<)( n::Number, c::PnmlMultiset{DotConstant}) = n < convert(Bool, c)

"""
    is_singletonmultiset(ms::PnmlMultiset) -> Bool

Singleton multisets have at most one element.
"""
is_singletonmultiset(ms::PnmlMultiset) = cardinality(ms) <= 1

"""
    is_emptymultiset(ms::PnmlMultiset) -> Bool

Empty multisets have no element.
"""
is_emptymultiset(ms::PnmlMultiset) = cardinality(ms) == 0

"""
    basis(ms::PnmlMultiset) -> SortRef

Multiset basis sort is accessed through a SortRef that holds a `REFID` index
into `decldict(net)`. MultisetSorts not allowed here. Nor loops in sort references.
"""
basis(ms::PnmlMultiset) = sortref(ms)::SortRef
sortref(ms::PnmlMultiset) = ms.basis_ref

Base.eltype(::Type{PnmlMultiset{T}}) where {T} = T

function Base.show(io::IO, t::PnmlMultiset)
     print(io, nameof(typeof(t)), "(",basis(t), ", ", multiset(t), ")")
end

# Return empty multiset with matching basis sort, element type.
function Base.zero(pms::PnmlMultiset{T}) where {T}
    b = basis(pms)
    ms = Multiset{T}() #^ empty multiset
    z = PnmlMultiset{T}(b, ms, pms.net[])
    is_emptymultiset(z) ||
        @error "not a empty multiset!: $z"
    return z
end

# Choose an arbitrary value `f` of `pms` to have multiplicity of 1.
function Base.one(pms::PnmlMultiset{T}) where {T}
    b = basis(pms)
    f = first(sortelements(b, pms.net[]))
    o = PnmlMultiset{T}(b, Multiset(f), pms.net)
    is_singletonmultiset(o) ||
        @error "expected a singleton with one element, found: $o"
    return o
end

"""
`A+B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (+)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        PnmlMultiset{T, typeof(a.net)}(basis(a), multiset(a) + multiset(b), a.net)
end

 """
`A-B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (-)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        PnmlMultiset{T, typeof(a.net)}(basis(a), multiset(a) - multiset(b), a.net)
end

"""
`A*B` for PnmlMultisets is forwarded to `Multiset`.
"""
function Base.:*(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        PnmlMultiset{T, typeof(a.net)}(basis(a), multiset(a) * multiset(b), a.net)
end

"""
`n*B` for PnmlMultisets is the scalar multiset product.
"""
function Base.:*(n::Number, a::PnmlMultiset{T}) where {T}
    PnmlMultiset{T, typeof(a.net)}(basis(a), convert(Int, n) * multiset(a), a.net)
end

function Base.:*(a::PnmlMultiset{T}, n::Number) where {T}
    PnmlMultiset{T, typeof(a.net)}(basis(a), convert(Int, n) * multiset(a), a.net)
end

"""
`A<B` for PnmlMultisets is forwarded  to`Multiset`.
"""
function (<)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        multiset(a) < multiset(b)
end

"""
`A>B` for PnmlMultisets is forwarded  to`Multiset`.
"""
function (>)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        multiset(a) > multiset(b)
end

"""
`A<=B` for PnmlMultisets is forwarded to `Multiset`.
"""
function (<=)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        multiset(a) <= multiset(b)
end

"""
`A>=B` for PnmlMultisets is forwarded to `Multiset`.
"""
function (>=)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        multiset(a) >= multiset(b)
end

"""
    mcontains(a::PnmlMultiset, b::PnmlMultiset) -> Bool

Forwarded to `Multiset.issubset(multiset(b), multiset(a))`.
"""
function mcontains(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    basis(a) == basis(b) &&
        Multisets.issubset(multiset(b), multiset(a))
end

"""
    pnmlmultiset(basis::SortRef, x, multi::Int=1; net) -> PnmlMultiset
    pnmlmultiset(basis::SortRef, x::Multisets.Multiset; net) -> PnmlMultiset
    pnmlmultiset(basis::SortRef; net) -> PnmlMultiset

Constructs a [`PnmlMultiset`](@ref) containing a multiset and a sort from either
  - a sortref, one element and a multiplicity, default = 1, denoted "1'x",
  - a sortref and `Multiset`
  - or just a sortref (not a multisetsort), uses all sortelements, each with multiplicity 1.

Are mapping to Multisets.jl implementation:
Create empty Multiset{T}() then fill.
  If we have an element we can use `typeof(x)` to deduce T.
  If we have a basis sort definition we use `eltype(basis)` to deduce T.

Usages
  - ⟨all⟩ wants all sortelements
  - default marking, inscription want one element or zero elements (elements can be tuples),
we always find a sort to use, And use dummy elements for their `typeof` for empty multisets.

Expect to be called from a `@matchable` `Terminterface`, thusly:
  - `eval(toexpr(Bag(basis, x, multi; net), variable_substitutions))`
  - `eval(toexpr(Bag(basis); net), variable_substitutions))`
"""
function pnmlmultiset end

# Constructor call
function pnmlmultiset(basis::SortRef, ms::Multiset, ::Nothing; net::AbstractPnmlNet)
    # z = PnmlMultiset{eltype(ms)}(basis, ms)
    # f = first(sortelements(basis, net))
    # o = PnmlMultiset{eltype(ms)}(basis, Multiset(f))

    PnmlMultiset{eltype(ms), typeof(net)}(basis, ms, net)
end

# Expect `element` and `multi` subterms to have already
# been eval'ed to perform variable substitution.
function pnmlmultiset(basis::SortRef, element, multi::Int=1; net::AbstractPnmlNet)
    # NOTE: This is legal and used.
    # Seem to recall something about singleton-multisets serving as "numbers".
    # Should we test `is_singletonmultiset` here?

    if isa(basis, MultisetSort)
        #^ Where/how is absence of sort loop checked?
        throw(ArgumentError("Cannot be a MultisetSort: found $basis for $element"))
    end
    multi >= 0 || throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    # if !(equal(x_sortof(basis), x_sortof(element)) || (typeof(element) == eltype(basis)))
    #     @warn "!equal" x_sortof(basis) x_sortof(element) typeof(element) eltype(basis)
    # end
    M = Multiset{typeof(element)}()
    M[element] = multi
    PnmlMultiset{eltype(M), typeof(net)}(basis, M, net)
end

# For <all> only the basis is needed.
function pnmlmultiset(basis::SortRef, ::Nothing, ::Nothing; net::AbstractPnmlNet)
    if is_multisetsort(basis)
        throw(ArgumentError("Cannot have MultisetSort basis of $(repr(basis))"))
    end
    #^ Where/how is absence of sort loop checked?
    # Only expect finite sorts here. #! assert isfinitesort(basis)
    s = to_sort(basis, net)
    t = eltype(s)::Type
    M = Multiset{t}()
    for e in sortelements(s, net) # iterator over elements
        push!(M, e)
    end
    PnmlMultiset{t, typeof(net)}(basis, M, net)
end
