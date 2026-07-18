abstract type NumberSort <: AbstractSort end

"""
Built-in sort whose `eltype` is `Int`
"""
@struct_hash_equal struct IntegerSort <: NumberSort end
Base.eltype(::Type{<:IntegerSort}) = Int
(i::IntegerSort)() = 1
sortelements(::IntegerSort, ::AbstractPnmlNet) = Iterators.countfrom(0, 1) #! infinite, expected use is first
refid(::IntegerSort) = :integer

"""
Built-in sort whose `eltype` is `Int`
"""
@struct_hash_equal struct NaturalSort <: NumberSort end
Base.eltype(::Type{<:NaturalSort}) = Int # Uint ?
sortelements(::NaturalSort, ::AbstractPnmlNet) = Iterators.countfrom(0, 1)
refid(::NaturalSort) = :natural

"""
Built-in sort whose `eltype` is `Int`
"""
@struct_hash_equal struct PositiveSort <: NumberSort end
Base.eltype(::Type{<:PositiveSort}) = Int # Uint ?
sortelements(::PositiveSort, ::AbstractPnmlNet) = Iterators.countfrom(1, 1)
refid(::PositiveSort) = :positive

"""
Built-in sort whose `eltype` is `Float64`
"""
@struct_hash_equal struct RealSort <: NumberSort end
Base.eltype(::Type{<:RealSort}) = Float64
sortelements(::RealSort, ::AbstractPnmlNet) = Iterators.map(x->1.0*x, Iterators.countfrom(0, 1))
refid(::RealSort) = :real

"""
Built-in sort whose `eltype` is `Nothing`
"""
@struct_hash_equal struct NullSort <: NumberSort end
Base.eltype(::Type{<:NullSort}) = Nothing
sortelements(::Type{<:NullSort}, ::AbstractPnmlNet) = tuple() # empty
sortelements(::NullSort, ::AbstractPnmlNet) = tuple() # empty
refid(::NullSort) = :null
