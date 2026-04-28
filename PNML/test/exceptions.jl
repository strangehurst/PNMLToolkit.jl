using PNML, Test, JET
using OrderedCollections

include("TestUtils.jl")
using .TestUtils

println("EXCEPTIONS")

@testset "showerr" begin
    e1 = PNML.MissingIDException("test showerr")::PNML.PnmlException
    e2 = PNML.MalformedException("test showerr")::PNML.PnmlException
    @test sprint(showerror,e1) != sprint(showerror,e2)
    Base.redirect_stdio(stdout=devnull, stderr=devnull) do
        @test_logs showerror(stdout,e1)
        @test_logs showerror(stdout,e2)
        @test_logs showerror(stderr,e1)
        @test_logs showerror(stderr,e2)
    end
end
# println("E 1")

@testset "missing namespace $pntd" for pntd in PnmlTypes.core_nettypes()
    @test_logs(match_mode=:any, (:warn, r"missing namespace"),
        pnmlmodel(xml"""<pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))

    @test_logs(match_mode=:any, (:warn, "pnml missing namespace"),
        pnmlmodel(xml"""<?xml version="1.0" encoding="UTF-8"?>
                        <pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))
end

#println("pntd_override")
@test_logs((:info,"net 4712 pntd set to reallygood, overrides test"),
            parse_net(xml"""<net id="4712" type="test">
              </net>"""; net=make_net(PnmlCoreNet(), :pntd_override_net),
                         pntd_override="reallygood"))


# println("E 2")
@testset "malformed $pntd" for pntd in PnmlTypes.core_nettypes()
    # println("malformed $pntd")
    # println("-- 1")
    @test_throws("MalformedException: <pnml> does not have any <net> elements",
        pnmlmodel(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml" />"""))

    # println("-- 2")
    @test_throws("MalformedException: attribute tool missing",
        pnmlmodel(xml"""
            <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net type="http://www.pnml.org/version-2009/grammar/pnmlcore" id="n1">
                <toolspecific/>
                <page id="pg1"/>
            </net>
            </pnml>
            """))

    @test_throws("MalformedException: attribute tool missing",
        pnmlmodel(xml"""
            <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net type="http://www.pnml.org/version-2009/grammar/pnmlcore" id="n1">
                <page id="pg1">
                    <toolspecific/>
                </page>
            </net>
            </pnml>
            """))

    # println("-- 3")
    @test_throws("MalformedException: attribute type missing",
        pnmlmodel(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                        <net id="4712"/>"""))


    @test_throws("MalformedException: attribute type missing",
        pnmlmodel(xml"""
            <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="4712">
                <page id="3">
                <place id="p2">
                    <toolspecific/>
                </place>
                <arc id="a3" source="p2" target="t3"/>
                <transition id="t3"/>
                </page>
            </net>
            </pnml>
            """))

    # println("-- 4")
    @test_throws("MalformedException: attribute type missing",
        parse_net(xml"""<net id="4712"> </net>""";
             net=make_net(PnmlCoreNet(), :missing_type_net)))
end

@test_logs((:warn,"ignoring unexpected child of <net>: <graphics>"),
    pnmlmodel(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                <net id="4712" type='test'>
                    <graphics/>
                </net>
                </pnml>""";
            net=make_net(PnmlCoreNet(), :unexpected_child_net)))

@test_logs((:info, r"^add PnmlLabel :unexpected.*"),
    pnmlmodel(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                <net id="4712" type='test'>
                    <unexpected/>
                </net>
                </pnml>""";
            net=make_net(PnmlCoreNet(), :label_named_unexpected)))

@test_logs((:info, r"^add PnmlLabel :unexpected.*"),
    pnmlmodel(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                <net id="4712" type='test'>
                    <page id="3">
                        <unexpected/>
                    </page>
                </net>
                </pnml>""";
            net=make_net(PnmlCoreNet(), :label_named_unexpected2)))


# println("E 3")
@testset "missing id $pntd" for pntd in PnmlTypes.core_nettypes()
    net = make_net(pntd, :missing_id_net)
    @test_throws("MissingIDException: net",
            parse_net(xml"<net type='test'></net>"; net))

    pagedict = OrderedDict{Symbol, PNML.Page{typeof(net)}}()
    netdata = PNML.PnmlNetData()
    netsets = PNML.PnmlNetKeys()
    #todo add net to parse_page!
    @test_throws(r"^MissingIDException: page",
        PNML.Parser.parse_page!(net, page_idset(netsets), xml"<page></page>"))
    @test_throws(r"^MissingIDException: place",
        PNML.Parser.parse_place(xml"<place></place>", net))
    @test_throws(r"^MissingIDException: transition",
        PNML.Parser.parse_transition(xml"<transition></transition>", net))
    @test_throws(r"^MissingIDException: arc",
        PNML.Parser.parse_arc(xml"<arc></arc>", net))
    @test_throws(r"^MissingIDException: referencePlace",
        PNML.Parser.parse_refPlace(xml"<referencePlace></referencePlace>", net))
    @test_throws(r"^MissingIDException: referenceTransition",
        PNML.Parser.parse_refTransition(xml"<referenceTransition></referenceTransition>", net))
end

# println("E 4")
@testset "check_nodename" begin
    @test_throws("ArgumentError: element name wrong, expected bar, got foo",
        PNML.Parser.check_nodename(xml"<foo></foo>", "bar"))
end
