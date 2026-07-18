"""
$(TYPEDEF)

"""
@struct_hash_equal struct StringSort <: AbstractSort
end
Base.eltype(::Type{<:StringSort}) = String
sortelements(::StringSort, :: AbstractPnmlNet) = tuple("") # default element is empty string
