"""
Set of sort IDs that are considered builtin.
"""
builtin_sorts() = Set([:integer, :natural, :positive, :real, :dot, :bool, :null])

"""
    is_builtinsort(::Symbol) -> Bool

Is tag in `builtin_sorts()`.
"""
is_builtinsort(tag::Symbol) = (tag in builtin_sorts())

# """
# $(TYPEDSIGNATURES)
# For sorts to be the same, first they must have the same type.
# Then any contents of the sorts are compared semantically.
# """
# equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b) # Are same sort type.
# equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically  #! should be the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content, just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(::APN, a::AbstractSort, b::AbstractSort) = a == b

basis(a::AbstractSort) = sortref(a)::SortRef
sortdefinition(a::AbstractSort) = identity(a)

"""
Built-in sort whose `eltype` is `Bool`

Operators: and, or, not, imply

Functions: equality, inequality
"""
@auto_hash_equals struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool
"Elements of boolean sort"
sortelements(::BoolSort, ::APN) = tuple(true, false)

#------------------------------------------------------------------------------

"""
$(TYPEDEF)

Wrap a SortRef. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort <: AbstractSort
    basis::SortRef

    function MultisetSort(b::SortRef, net::APN)
        if is_multisetsort(b) ||
           (is_namedsort(b) &&
                isa(sortdefinition(namedsort(net, b)), MultisetSort))

            throw(PNML.MalformedException("basis cannot be MultisetSort, found $b"))
        end
        new(b)
    end
end

sortref(ms::MultisetSort) = identity(ms.basis)::SortRef
basis(ms::MultisetSort) = ms.basis

function Base.show(io::IO, us::MultisetSort)
    print(io, indent(io), "MultisetSort(", repr(basis(us)), ")")
end

"""
$(TYPEDEF)

An ordered collection of sorts. The elements of the sort are tuples of elements of each sort.

ISO 15909-1:2019 Concept 14 (color domain) finite cartesian product of color classes.
Where sorts are the syntax for color classes and ProductSort is the color domain.
"""
@auto_hash_equals struct ProductSort{PN <:APN, N} <: AbstractSort
    ae::NTuple{N, SortRef}
    net::PN
end
#
Base.length(ps::ProductSort) = length(ps.ae)
Base.eltype(ps::ProductSort) = Tuple{eltype.(sortdefinitions(ps))...}

sortdefinitions(p::ProductSort) = Iterators.map(sorts(p)) do s
    sortdefinition(namedsort(p.net, s))
end

"""
    sorts(ps::ProductSort) -> Iterator
    sorts(psr::SortRef, net::APN) -> Iterator

Return iterator over `SortRef`s to sorts in the product of sorts.
"""
function sorts end
sorts(ps::ProductSort) = values(ps.ae)
sorts(psr::SortRef, net::APN) = sorts(productsort(net, psr)::ProductSort)

function sortelements(ref::SortRef, net::APN)
    sortelements(to_sort(ref, net), net)
end

# Iterators.product is over tuples of 1 element from each sort of ProductSort
function sortelements(ps::ProductSort, net::APN)
    Iterators.product(Fix2(sortelements, net).(sorts(ps))...)
end

function equalSorts(_net::PN, a::ProductSort{PN, N}, b::ProductSort{PN, N},
                    ) where {PN <: APN, N <: Integer}
    if length(a) == length(b) &&
            all(refid(x) == refid(y) for (x,y) in zip(sorts(a), sorts(b)))
        return true
    end
    return false
end

#
function equalSorts( net::APN, a::SortRef, b::SortRef)
    if variant_type(a) == variant_type(b) && refid(a) == refid(b)
        #println("Same type ref and same refid means same sortdefinition.")
        return true
    else
        # Compare sortdefinitions.
        asort = to_sort(unwrap_namedsort(a, net), net)
        bsort = to_sort(unwrap_namedsort(b, net), net)
        return equalSorts(net, asort, bsort)
    end
end

# equalSorts(a::NamedSortRef, b::UserSortRef, net) = equalSorts(a, convert(NamedSortRef, b), net)
# equalSorts(a::UserSortRef, b::NamedSortRef, net) = equalSorts(convert(NamedSortRef, a), b, net)
# equalSorts(a::UserSortRef, b::UserSortRef, net) = equalSorts(convert(NamedSortRef, a), convert(NamedSortRef, b), net)


function Base.show(io::IO, ps::ProductSort)
    print(io, indent(io), "ProductSort(", ps.ae, ")")
end
