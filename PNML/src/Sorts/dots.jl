"""
    DotSort
Built-in sort whose `eltype` is `Bool`, the smallest Integer subtype that can represent one.
"""
@auto_hash_equals struct DotSort <: AbstractSort
end

Base.eltype(::Type{<:DotSort}) = Bool # What would be iterated over. See `sortelements`.
sortelements(::DotSort, ::AbstractPnmlNet) = tuple(DotConstant()) # DotConstant is an AbstractOperator

function Base.show(io::IO, sort::DotSort)
    print(io, nameof(typeof(sort)), "()")
end
