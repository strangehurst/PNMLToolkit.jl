using PNML, Test, JET

include("TestUtils.jl")
using .TestUtils

println("FLATTEN")
@testset "flatten" begin
    model = pnmlmodel(xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="net0" type="pnmlcore">
                <page id="page1">
                    <place id="p1"/>
                    <transition id ="t1"/>
                    <arc id="a1" source="p1" target="t1"/>
                    <arc id="a12" source="t1" target="rp1"/>
                    <referencePlace id="rp1" ref="p2"/>
                </page>
                <page id="page2">
                    <place id="p2"/>
                    <transition id ="t2"/>
                    <arc id="a2" source="t2" target="p2"/>
                    <arc id="a22" source="t2" target="rp2"/>
                    <arc id="a23" source="rt2" target="p2"/>
                    <referencePlace id="rp2" ref="p3"/>
                    <referenceTransition id="rt2" ref="t3"/>
                </page>
                <page id="page3">
                    <place id="p3"/>
                    <transition id ="t3"/>
                    <arc id="a3" source="t3" target="p3"/>
                </page>
            </net>
        </pnml>
    """)
    net = @inferred PnmlNet first(nets(model))
    @test_call first(nets(model))
    @test length(allpages(net)) == length(allpages(net)) == 3
    flatten_pages!(net)
    @test_call broken=false flatten_pages!(net)
    @test length(allpages(net)) == length(allpages(net)) == 1

    @test PNML.has_arc(net, :a1)
    @test PNML.has_arc(net, :a12)
    @test PNML.has_arc(net, :a2)
    @test PNML.has_arc(net, :a22)
    @test PNML.has_arc(net, :a23)
    @test PNML.has_arc(net, :a3)
    @test PNML.has_place(net, :p1)
    @test PNML.has_place(net, :p2)
    @test PNML.has_place(net, :p3)
    @test PNML.has_transition(net, :t1)
    @test PNML.has_transition(net, :t2)
    @test PNML.has_transition(net, :t3)

    @test target(arc(net, :a12)) === :p2
    @test target(arc(net, :a22)) === :p3
    @test source(arc(net, :a23)) === :t3

    @test PNML.post_flatten_verify(net, true)===nothing
    #@show PNML.vertex_codes(net)
    #@show PNML.vertex_labels(net)
end
