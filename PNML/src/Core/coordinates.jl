"""
$(TYPEDEF)
$(TYPEDFIELDS)

Cartesian Coordinate are positive decimals. Ranges from 0 to 999.9.
"""
struct Coordinate #! is decimal 0 to 999.9 in Schema
    x_::Float32
    y_::Float32
end

"""
Construct a Coordinate from mixed Int, Float64.
"""
function Coordinate(x::T1, y::T2) where {T1 <: Number, T2 <: Number}
    Coordinate(convert(value_type(Coordinate), x),
               convert(value_type(Coordinate), y))
end

coordinate_type(::APNTD) = Coordinate

Base.eltype(::Coordinate) = Float32
Base.eltype(::Type{Coordinate}) = Float32
value_type(::Type{Coordinate}, ::APNTD) = eltype(Coordinate)
value_type(::Type{Coordinate}) = eltype(Coordinate)

x(c::Coordinate) = c.x_
y(c::Coordinate) = c.y_
Base.:(==)(l::Coordinate, r::Coordinate) = x(l) == x(r) && y(l) == y(r)

function Base.show(io::IO, c::Coordinate)
    #compact = get(io, :compact, false)::Bool
    print(io, "Coordinate(", x(c), ", ", y(c), ")")
end
