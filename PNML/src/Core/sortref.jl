
"""
    SortRefImpl

SortRefImpl is the name of the Module created by Moshi @data to hold an ADT.

Each variant has a `REFID` `Symbol` that indexes one of the dictionaries
in the network's declaration dictionary collection (`DeclDict`).

The `REFID` will be in the network's `IDRegistry`.

`UserSortRef` is created from `<usersort declaration="id" />`.

We use `NamedSortRef` -> `ConcreteSort` to add a name and REFID to built-in
sorts, thus making them accessable. This extends this decoupling (symbols instead of sorts)
to anonymous sorts that are inlined.
"""
Moshi.Data.@data SortRefImpl begin
    struct UserSortRef
        refid::Symbol # Indirection to NamedSortRef, PartitionSortRef or ArbitrarySortRef
    end
    struct NamedSortRef
        refid::Symbol
    end
    struct PartitionSortRef
        refid::Symbol
    end
    struct ProductSortRef
        refid::Symbol
    end
    struct MultisetSortRef
        refid::Symbol
    end
    struct ArbitrarySortRef
        refid::Symbol
    end
end
@assert @isdefined(SortRefImpl) "SortRefImpl should be defined"

@derive SortRefImpl[Show,Hash,Eq]

"""
Alias for `SortRefImpl.Type`.
"""
const SortRef = SortRefImpl.Type

# For access to values that SortRefImpl.Type my have.
using .SortRefImpl: UserSortRef, NamedSortRef, PartitionSortRef,
                    ProductSortRef, MultisetSortRef, ArbitrarySortRef


"""
    $TYPEDSIGNATURES

Check if a value is an `UserSortRef` variant of `SortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `UserSortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `UserSortRef` variant, `false` otherwise.
"""
is_usersort(x::SortRef) = isa_variant(x, SortRefImpl.UserSortRef)

"""
    $TYPEDSIGNATURES

Check if a value is an `NamedSortRef` variant of `SortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `NamedSortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `NamedSortRef` variant, `false` otherwise.
"""
is_namedsort(x::SortRef) = isa_variant(x, SortRefImpl.NamedSortRef)

"""
    $TYPEDSIGNATURES

Check if a value is an `PartitionSortRef` variant of `SortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `PartitionSortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `PartitionSortRef` variant, `false` otherwise.
"""
is_partitionsort(x::SortRef) = isa_variant(x, SortRefImpl.PartitionSortRef)

"""
    $TYPEDSIGNATURES

Check if a value is an `ProductSortRef` variant of `SortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `ProductSortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `ProductSortRef` variant, `false` otherwise.
"""
is_productsort(x::SortRef) = isa_variant(x, SortRefImpl.ProductSortRef)

"""
    $TYPEDSIGNATURES

Check if a value is an `MultisetSortRef` variant of `SortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `MultisetSortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `MultisetSortRef` variant, `false` otherwise.
"""
is_multisetsort(x::SortRef) = isa_variant(x, SortRefImpl.MultisetSortRef)

"""
    $TYPEDSIGNATURES

Check if a value is an `SortRef` variant of `ArbitrarySortRef`.

# Arguments
- `x`: Value to check (for `SortRef` input returns true if `ArbitrarySortRef`, for others returns false).

# Returns
- `true` if `x` is a `SortRef` with `ArbitrarySortRef` variant, `false` otherwise.
"""
is_arbitrarysort(x::SortRef) = isa_variant(x, SortRefImpl.ArbitrarySortRef)

function refid(s::SortRef)
    @match s begin
        SortRefImpl.UserSortRef(; refid) => refid
        SortRefImpl.NamedSortRef(; refid) => refid
        SortRefImpl.PartitionSortRef(; refid) => refid
        SortRefImpl.ProductSortRef(; refid) => refid
        SortRefImpl.MultisetSortRef(; refid) => refid
        SortRefImpl.ArbitrarySortRef( ;refid) => refid
    end
end

"""
    to_sort(sortref::SortRef, net::APN) -> AbstractSort

Return concrete sort from `net` using the `REFID` in `sortref`,
"""
function to_sort(sr::SortRef, net::APN)
    s = @match sr begin
        SortRefImpl.NamedSortRef(refid)     => namedsort(net, refid) # todo unwrap namedsort
        SortRefImpl.ProductSortRef(refid)   => productsort(net, refid) #! named sort
        SortRefImpl.MultisetSortRef(refid)  => multisetsort(net, refid) #! named sort
        SortRefImpl.PartitionSortRef(refid) => partitionsort(net, refid)
        SortRefImpl.ArbitrarySortRef(refid) => arbitrarysort(net, refid)
        _ => error("to_sort SortRefImpl not expected: $sr")
    end
    return s
end
to_sort(s::AbstractSort, ::APN) = s
