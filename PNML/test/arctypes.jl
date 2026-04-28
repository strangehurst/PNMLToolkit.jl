using PNML, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict
# todo parse_arctype

include("TestUtils.jl")
using .TestUtils

using PNML: is_normal, is_inhibitor, is_read, is_reset

@testset "arctypes $arct" for arct in ["normal", "inhibitor", "read", "reset"]
    net = make_net(PnmlCoreNet(), :arctypes_net)

    str = """<arc source="t1" target="p1" id="a1">
        <arctype>
            <text> $arct </text>
            <graphics/>
            <toolspecific tool="tname" version="1"/>
        </arctype>
      </arc>"""
    node = xmlnode(str)

    a = parse_arc(node, net)::Arc
    atl = PNML.arctypelabel(a)
    arct = PNML.Labels.arctype(atl)

    @test length(Base.findall([is_normal(a), is_inhibitor(a), is_read(a), is_reset(a)])) == 1
    @test length(Base.findall([is_normal(atl), is_inhibitor(atl), is_read(atl), is_reset(atl)])) == 1
    @test length(Base.findall([is_normal(arct), is_inhibitor(arct), is_read(arct), is_reset(arct)])) == 1

    @test is_normal(a) == is_normal(atl) == is_normal(arct)
    @test is_inhibitor(a) == is_inhibitor(atl) ==is_inhibitor(arct)
    @test is_read(a) == is_read(atl) == is_read(arct)

    @test pid(a) === :a1
    @test name(a) == ""
    @test inscription(a)(NamedTuple()) == 1
end

@testset "arctypes $arct" for arct in ["normal", "inhibitor", "read", "reset"]
    net = make_net(PnmlCoreNet(), :empty_arctype)
    str = """<arc source="t1" target="p1" id="a1">
        <arctype>
            <!-- empty -->
        </arctype>
      </arc>"""
    node = xmlnode(str)
    @test_throws(ArgumentError, parse_arc(node, net)::Arc)
end
