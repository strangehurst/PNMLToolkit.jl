"""
    PnmlGraphics holds CSS-like data. Can be attached to 'AbstractPnmlObject`s and
`Annotation` label parts of `PnmlNet`s.
"""
module PnmlGraphics

#import AutoHashEquals: @auto_hash_equals
import Base: eltype
import StructEquality: @struct_hash_equal

using DocStringExtensions
using PNML: Coordinate

export AnnotationGraphics, ArcGraphics, Graphics, NodeGraphics #, Line, Fill, Font

#-------------------
"""
Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Fill
    color::String = "black"
    image::String = ""
    gradient_color::String = ""
    gradient_rotation::String = ""
   function Fill(color::String, image::String, gradient_color::String, gradient_rotation::String)
        new(color, image, gradient_color, gradient_rotation)
    end
end

function Base.show(io::IO, fill::Fill)
    print(io, "Fill(")
    show(io, fill.color); print(io, ", ")
    show(io, fill.image); print(io, ", ")
    show(io, fill.gradient_color); print(io, ", ")
    show(io, fill.gradient_rotation);
    print(io, ")")
end


#-------------------
"""
Font attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Font
    family    ::String = ""
    style     ::String = ""
    weight    ::String = "black"
    size      ::String = ""
    align     ::String = ""
    rotation  ::String = ""
    decoration::String = ""
    function Font(family::String, style::String, weight::String, size::String, align::String, rotation::String, decoration::String)
        new(family, style, weight, size, align, rotation, decoration)
    end
end

function Base.show(io::IO, font::Font)
    print(io, "Font(")
    show(io, font.family); print(io, ", ")
    show(io, font.style); print(io, ", ")
    show(io, font.weight); print(io, ", ")
    show(io, font.size); print(io, ", ")
    show(io, font.rotation); print(io, ", ")
    show(io, font.decoration);
    print(io, ")")
end

#-------------------
"""
Line attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Line
    color::String = "black"
    shape::String = ""
    style::String = ""
    width::String = ""
    function Line(color::String, shape::String, style::String, width::String)
        new(color, shape, style, width)
    end
end

function Base.show(io::IO, line::Line)
    print(io, "Font(")
    show(io, line.color); print(io, ", ")
    show(io, line.shape); print(io, ", ")
    show(io, line.style); print(io, ", ")
    show(io, line.width);
    print(io, ")")
end

#---------------------------------------------------------
#---------------------------------------------------------
"""
PNML Graphics can be attached to 'AbstractPnmlObject`s and `Annotation` label parts
of Pnml models.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Graphics
    dimension::Coordinate = Coordinate(one(eltype(Coordinate)), one(eltype(Coordinate)))
    fill::Fill = Fill()
    font::Font = Font()
    line::Line = Line()
    offset::Coordinate = Coordinate(zero(eltype(Coordinate)), zero(eltype(Coordinate)))
    positions::Vector{Coordinate} = Vector{Coordinate}[] # ordered collection
end

function Base.show(io::IO, g::Graphics)
    print(io, "Graphics(")
    show(io, g.dimension); print(io, ", ")
    show(io, g.fill); print(io, ", ")
    show(io, g.font); print(io, ", ")
    show(io, g.line); print(io, ", ")
    show(io, g.offset); print(io, ", ")
    show(io, g.positions);
    print(io, ")")
end


@kwdef struct ArcGraphics
    line::Line = Line()
    positions::Vector{Coordinate} = Vector{Coordinate}[] # ordered collection
end

@kwdef struct NodeGraphics
    postion::Coordinate = Coordinate(zero(eltype(Coordinate)), zero(eltype(Coordinate)))
    dimension::Coordinate = Coordinate(one(eltype(Coordinate)), one(eltype(Coordinate)))
    line::Line = Line()
    fill::Fill = Fill()
end

@kwdef struct AnnotationGraphics
    fill::Fill = Fill()
    offset::Coordinate = Coordinate(zero(eltype(Coordinate)), zero(eltype(Coordinate)))
    line::Line = Line()
    font::Font = Font()
end
end # module PnmlGraphics
