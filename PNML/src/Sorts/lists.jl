"""
$(TYPEDEF)
"""
@auto_hash_equals struct ListSort{T<:SortRef} <: AbstractSort
    basis::T
end

equal(a::ListSort, b::ListSort) = a.basis == b.basis

function Base.show(io::IO, s::ListSort)
    print(io, "ListSort(", basis, ")")
end
