using Test
include("TestUtils.jl")
using .TestUtils
using EzXML: EzXML
using XMLDict: XMLDict

@testset "name $pntd" for pntd in PnmlTypes.core_nettypes()
    net = make_net(pntd, :name_net)

    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name></name>", net, parentid=:xxx))::PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name>stuff</name>", net, parentid=:xxx))
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.toolspecinfos === nothing || isempty(n.toolspecinfos)

    n = PNML.Parser.parse_name(xml"<name><text>some name</text></name>", net, parentid=:xxx)
    @test n isa PNML.Name
    @test PNML.text(n) == "some name"

    n = PNML.Parser.parse_name(xml"""
        <name>
            <text>some name2</text>
            <graphics/>
        </name>""", net, parentid=:xxx)
    @test PNML.text(n) == "some name2"
    @test has_graphics(n) == true

    #TODO add toolinfo
    n = PNML.Parser.parse_name(xml"""
        <name>
            <text>some name3</text>
            <toolspecific tool="faketool" version="1.2.3" />
        </name>""", net, parentid=:xxx)
    @test PNML.text(n) == "some name3"

    #TODO add toolinfo
    n = @test_logs((:warn, r"^xxx ignoring unexpected child of <name>: 'unknown'"),
            PNML.Parser.parse_name(xml"""
                <name>
                    <text>some name4</text>
                    <unknown/>
                </name>""", net, parentid=:xxx))

    # old_cfg = PNML.CONFIG.text_optional
    # PNML.CONFIG.text_optional = false
    # n = @test_throws(ArgumentError,
    #         PNML.Parser.parse_name(xml"<name>stuff</name>", net, parentid=:xxx))
    # PNML.CONFIG.text_optional =  old_cfg
end
