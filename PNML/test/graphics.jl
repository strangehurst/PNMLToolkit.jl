using PNML, Test, JET

include("TestUtils.jl")
using .TestUtils

@testset "coordinate" begin
    Coordinate(1, 2)
    Coordinate(1.1, 2.2)
    @test_opt Coordinate(1, 2)
    @test_call Coordinate(1, 2)
    @test_opt Coordinate(1.1, 2.2)
    @test_call Coordinate(1.1, 2.2)
    #TODO more tests

    @test_opt value_type(Coordinate)
    @test_call value_type(Coordinate)
end

@testset "graphics $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <graphics>
        <offset x="1.0" y="2.0" />
        <line  color="linecolor" shape="line" style="solid" width="1.0"/>
        <position  x="1.0" y="2" />
        <position  x="3.0" y="4" />
        <dimension x="5.0" y="6" />
        <offset    x="7.0" y="8" /><!-- override first offset -->
        <fill  color="fillcolor" gradient-color="none" gradient-rotation="horizontal"/>
        <font align="center" family="Dialog" rotation="0.0"  size="11.5"
            style="normal" weight="normal" />
        <unexpected/>
    </graphics>
    """
    n = @test_logs(
            (:warn, r"^ignoring unexpected child of <graphics>: 'unexpected'"),
             parse_graphics(node, pntd))

    @test PNML.coordinate_type(pntd) == Coordinate

    # There can only be one offset, last tag parsed wins.
    @test PNML.x(n.offset) == 7.0 && PNML.y(n.offset) == 8.0
    @test n.offset == Coordinate(7.0, 8.0)
    @test n.offset == Coordinate(7, 8.0)
    @test n.offset == Coordinate(7, 8)
    @test n.dimension == Coordinate(5.0, 6.0)
    @test n.offset isa Coordinate
    @test n.dimension isa Coordinate
    @test n.positions isa Vector{Coordinate}
    @test length(n.positions) == 2
    @test n.positions == [Coordinate(1.0, 2.0), Coordinate(3.0, 4.0)]

    @test eltype(Coordinate) == Float32
    @test value_type(Coordinate) == Float32
    @test value_type(Coordinate, pntd) == Float32

    @test n.line isa PnmlGraphics.Line
    @test n.line.color == "linecolor"
    @test n.line.shape == "line"
    @test n.line.style == "solid"
    @test n.line.width == "1.0"

    @test n.fill isa PnmlGraphics.Fill
    @test n.fill.color == "fillcolor"
    @test isempty(n.fill.image) # === nothing
    @test n.fill.gradient_color == "none"
    @test n.fill.gradient_rotation == "horizontal"

    @test n.font isa PnmlGraphics.Font
    @test n.font.family == "Dialog"
    @test n.font.style == "normal"
    @test n.font.weight == "normal"
    @test n.font.size == "11.5"
    @test isempty(n.font.decoration) # === nothing
    @test n.font.align == "center"
    @test n.font.rotation == "0.0"
end

@testset "graphics exception $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""<bogus x="1" y="2" />"""
    @test_throws r"^ArgumentError" PNML.Parser.parse_graphics_coordinate(node, pntd)
end

# part of toolinfo
# @testset "tokengraphics $pntd" for pntd in PnmlTypes.core_nettypes()
#     node0 = xml"""<tokengraphics></tokengraphics>"""
#     n = @test_logs(match_mode=:all,
#         (:warn,"tokengraphics does not have any <tokenposition> elements"),
#         parse_tokengraphics(node0, pntd))
#     @test n isa TokenGraphics
#     @test length(n.positions) == 0

#     node1 = xml"""<tokengraphics>
#                 <tokenposition x="-9" y="-2"/>
#                 <unexpected/>
#             </tokengraphics>"""
#     n = @test_logs(match_mode=:all,
#         (:warn, "ignoring unexpected child of <tokengraphics>: 'unexpected'"),
#         parse_tokengraphics(node1, pntd))
#     @test n isa TokenGraphics
#     @test length(n.positions) == 1

#     node2 = xml"""<tokengraphics>
#                 <tokenposition x="-9" y="-2"/>
#                 <tokenposition x="2"  y="3"/>
#             </tokengraphics>"""
#     n = parse_tokengraphics(node2, pntd)
#     @test n isa TokenGraphics
#     @test length(n.positions) == 2

#     node3 = xml"""<tokengraphics>
#                     <tokenposition x="-9.0" y="-2"/>
#                     <tokenposition x="2.0"  y="3"/>
#                     <tokenposition x="-2" y="2"/>
#             </tokengraphics>"""
#     n = parse_tokengraphics(node3, pntd)
#     @test n isa TokenGraphics
#     @test length(n.positions) == 3
#     #TODO test ordering
# end
