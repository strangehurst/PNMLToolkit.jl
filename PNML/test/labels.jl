using PNML, JET, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

@testset "text $pntd" for pntd in PnmlTypes.core_nettypes()
    @test parse_text(xml"<text>ready</text>", pntd) == "ready"
end

"Return PnmlLabel, AnyElement"
function test_unclaimed(pntd, xmlstring::String)
    net = make_net(pntd, :test_unclaimed_net)
    node = xmlnode(xmlstring)::XMLNode
    reg1 = IDRegistry()# 2 registries to ensure any ids do not collide.
    reg2 = IDRegistry()

    nodeid = Symbol(EzXML.nodename(node))
    u = Parser.xmldict(node)::LittleDict
    l = PnmlLabel(nodeid, u, net)
    a = anyelement(nodeid, node)

    @test u isa PNML.XmlDictType
    @test l isa PnmlLabel
    @test a isa AnyElement

    @test_opt target_modules=t_modules Parser.xmldict(node)
    @test_opt target_modules=t_modules function_filter=pff PnmlLabel(nodeid, u, net)

    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) Parser.xmldict(node)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) PnmlLabel(nodeid, u, net)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) Parser.anyelement(nodeid, node)

    nn = Symbol(EzXML.nodename(node))
    @test tag(l) isa Symbol && tag(l) === nn || tag(l) == string(nn)
    @test tag(a) isa Symbol && tag(a) === nn || tag(a) == string(nn)

    @test u isa XmlDictType
    @test l.elements isa XmlDictType
    @test a.elements isa LittleDict
    #! unclaimed id is not registered
    x = get(u, :id, nothing)
    !isnothing(x) &&
        @test !isregistered(net.idregistry, Symbol(x))
    return l, a
end

@testset "unclaimed $pntd" for pntd in PnmlTypes.core_nettypes()
    # Even though they are "claimed" by having a parser, they still may be treated as unclaimed.
    # For example <declarations>.
    net = make_net(pntd, :unclaimed_net)

    ctrl = [ # Vector of tuples of XML string, expected result from `XMLDict.xml_dict`.
        ("""<declarations> </declarations>""",
            "declarations" => XmlDictType()),

        ("""<declarations atag="atag1"> </declarations>""",
            "declarations" => XmlDictType(:atag =>"atag1")),

        ("""<foo><declarations> </declarations></foo>""",
            "foo" => XmlDictType("declarations" => XmlDictType())),

        # no content, no attribute maybe results in empty tuple.
        ("""<null></null>""",
            "null" => XmlDictType()),
        ("""<null2/>""",
            "null2" => XmlDictType()),
        # no content, with attribute
        ("""<null at="null"></null>""",
            "null" => XmlDictType(:at => "null")),
        ("""<null2 at="null2" />""",
            "null2" => XmlDictType(:at => "null2")),
        # empty content, no attribute
        ("""<empty> </empty>""",
            "empty" => XmlDictType()),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""",
            "empty" => XmlDictType(:at => "empty")),
        # unclaimed do not register id
        ("""<foo id="testid1" />""",
            "foo" => XmlDictType(:id => "testid1")),
        ("""<foo id="testid2"/>""",
            "foo" => XmlDictType(:id => "testid2")),

        ("""<foo id="repeats">
                <one>ONE</one>
                <one>TWO</one>
                <one>TRI</one>
            </foo>""",
            "foo" => XmlDictType(:id => "repeats",
                            "one" => Any["ONE", "TWO", "TRI"])),

        ("""<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo">
                    <value/>
                    <value tag3="tagthree"/>
                </something2>
            </declarations>""",
            "declarations"=> XmlDictType(:atag => "atag2",
                        "something" => Any["some content", "other stuff"],
                        "something2" =>
                            XmlDictType(:tag2 => "tagtwo",
                                "value" => Any[XmlDictType(), XmlDictType(:tag3 => "tagthree")]))),
    ]
    # expected is a pair to construct a PnmlLabel
    for (s, expected) in ctrl
        lab, anye = test_unclaimed(pntd, s)
        # TODO Add equality test, skip xml node.
        expected_label = PnmlLabel(Symbol(expected.first), expected.second, net)
        @test tag(lab) == tag(expected_label)
        @test length(elements(lab)) == length(elements(expected_label))
        # TODO recursive compare
        expected_any = AnyElement(Symbol(expected.first), expected.second)
        @test tag(anye) == tag(expected_any)
        @test length(elements(anye)) == length(elements(expected_any))
        # TODO recursive compare
    end
end
