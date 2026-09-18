"""
Set of sort IDs that are considered builtin.
"""
builtin_sorts() = Set([:integer, :natural, :positive, :real, :dot, :bool, :null])

function net(n::T) where {T <: AbstractSort}
    hasfield(T, :net) ? getfield(n, :net) : nothing
end
function Base.getproperty(o::AbstractSort, prop_name::Symbol)
    prop_name === :id   && return getfield(o, :id)::Symbol
#     prop_name === :pntd && return getfield(o, :pntd)::AbstractPNTD #! abstract
    return getfield(o, prop_name)
end

"""
    is_builtinsort(::Symbol) -> Bool

Is tag in `builtin_sorts()`.
"""
is_builtinsort(tag::Symbol) = (tag in builtin_sorts())
basis(a::AbstractSort) = sortref(a)::SortRef
sortdefinition(a::AbstractSort) = identity(a)

"""
Built-in sort whose `eltype` is `Bool`

Operators: and, or, not, imply

Functions: equality, inequality
"""
@struct_hash_equal struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool
"Elements of boolean sort"
sortelements(::BoolSort, ::AbstractPnmlNet) = tuple(true, false)
function Base.show(io::IO, sort::BoolSort)
    print(io, nameof(typeof(sort)), "()")
end

#------------------------------------------------------------------------------

"""
$(TYPEDEF)

Wrap a SortRef. Warning: do not cause recursive multiset Sorts.
"""
@struct_hash_equal struct MultisetSort <: AbstractSort
    basis::SortRef

    function MultisetSort(b::SortRef, net::AbstractPnmlNet)
        if is_multisetsort(b) ||
                    (is_namedsort(b) && sortdefinition(namedsort(net, b)) isa MultisetSort)
            throw(PNML.MalformedException("basis cannot be MultisetSort, found $b"))
        end
        new(b)
    end
end

sortref(ms::MultisetSort) = identity(ms.basis)::SortRef
basis(ms::MultisetSort) = ms.basis
# Iterators.product is over tuples of 1 element from each sort of ProductSort
sortelements(s::MultisetSort, net::AbstractPnmlNet) = sortelements(basis(s), net::AbstractPnmlNet)

function Base.show(io::IO, us::MultisetSort)
    print(io, indent(io), "MultisetSort(", repr(basis(us)), ")")
end

"""
$(TYPEDEF)

An ordered collection of sorts. The elements of the sort are tuples of elements of each sort.

ISO 15909-1:2019 Concept 14 (color domain) finite cartesian product of color classes.
Where sorts are the syntax for color classes and ProductSort is the color domain.
"""
@struct_hash_equal struct ProductSort{PN <:AbstractPnmlNet, N} <: AbstractSort
    ae::NTuple{N, SortRef}
    net::PN
end
#
Base.length(ps::ProductSort) = length(ps.ae)
Base.eltype(ps::ProductSort{PN,N}) where {PN <:AbstractPnmlNet, N} =
    Tuple{eltype.(sortdefinition(ps))...}

function sortdefinitions(p::ProductSort)
    Iterators.map(sorts(p)) do s
        sortdefinition(namedsort(p.net, s))
    end
end

# Returns a tuple of concrete sorts
function sortdefinition(p::ProductSort)
    to_sort(p.net).(sorts(p))
end

"""
    sorts(ps::ProductSort) -> Iterator
    sorts(psr::SortRef, net::AbstractPnmlNet) -> Iterator

Return iterator over `SortRef`s to sorts in the product of sorts.
"""
function sorts end
sorts(ps::ProductSort) = values(ps.ae)
sorts(psr::SortRef, net::AbstractPnmlNet) = sorts(productsort(net, psr)::ProductSort)

function sortelements(ref::SortRef, net::AbstractPnmlNet)
    #@show ref
    if PNML.is_productsort(ref)
        @show to_sort(ref, net)
        sortelements(productsort(net, ref)::ProductSort, net)
    else
        sortelements(to_sort(ref, net), net)
    end

end

# Iterators.product is over tuples of 1 element from each sort in ProductSort
function sortelements(ps::ProductSort, net::AbstractPnmlNet)
    Iterators.product(Fix2(sortelements, net).(sorts(ps))...)
end

function Base.show(io::IO, ps::ProductSort)
    print(io, "ProductSort(", ps.ae, ")")
end

# equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b) # Are same sort type.
# equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content, just the types are sufficent.
# Use @struct_hash_equal on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
"""
$(TYPEDSIGNATURES)
For sorts to be the same, first they must have the same type.
Then any contents of the sorts are compared semantically.
"""
function equalSorts end
function equalSorts(a::T, b::T) where {T <: AbstractSort}
    #println("equalSorts AbstractSorts $a $b")
    (a == b)::Bool
end
function equalSorts(a::AbstractSort, b::AbstractSort)
    asort = unwrap_namedsort(a)
    bsort = unwrap_namedsort(b)
    #@show asort bsort
    return if typeof(asort) == typeof(bsort)
        equalSorts(asort, bsort)::Bool
    else
        false
    end
end

function equalSorts(a::ProductSort{PN, N}, b::ProductSort{PN, N},
                    ) where {PN <: AbstractPnmlNet, N <: Integer}
    #println("equalSorts ProductSorts $a $b")
    if length(a) == length(b)
        return all(equalSorts(a.net, x, y) for (x,y) in zip(sorts(a), sorts(b)))
    end
    return false
end

function equalSorts(net::AbstractPnmlNet, a::SortRef, b::SortRef)
    # variant type and refid are the same.
    a == b  && return true
    #@warn "equalSorts $a, $b"

    # namedsort holds concrete sort objects (no nested named sorts allowed by construction).
    # productsort holds sortrefs to named and builtin sorts.

    # asort = if is_namedsort(a)
    #     sortdefinition(namedsort(net, a))
    #     # Not another NamedSort.
    # else
    #     s = to_sort(a, net)
    #     if s isa PNML.Declarations.NamedSort # May be a NamedSort,
    #         sortdefinition(s)
    #     else
    #         s
    #     end
    # end
    # bsort = if is_namedsort(b)
    #     sortdefinition(namedsort(net, b))
    # else
    #     s = to_sort(b, net)
    #     if s isa PNML.Declarations.NamedSort
    #         sortdefinition(s)
    #     else
    #         b
    #     end
    # end
    # Compare concrete sort definitions for structural equality.
    asort = unwrap(net, a)
    bsort = unwrap(net, b)
    #@show asort bsort
    return equalSorts(asort, bsort)
end

function unwrap(net::AbstractPnmlNet, sortref::SortRef)
    if is_namedsort(sortref)
        sortdefinition(namedsort(net, sortref))
    else
        s = to_sort(sortref, net)
        unwrap_namedsort(s)
    end
end

"""
If `a` is a `NamedSortRef` return its `sortdefinition`, otherwise return `a`.
"""
function unwrap_namedsort(a::SortRef, net::AbstractPnmlNet)
    if is_namedsort(a)
        sortdefinition(namedsort(net, a))
    else
        a
    end
end
unwrap_namedsort(net::AbstractPnmlNet) = Fix2(unwrap_namedsort, net)

function unwrap_namedsort(a)
    if a isa PNML.Declarations.NamedSort
        sortdefinition(a)
    else
        a
    end
end
