using PNML, Test, JET

include("TestUtils.jl")
using .TestUtils

@testset "Show" begin
    xnode = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
          <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
          <name> <text>P/T Net with one place</text> </name>
            <page id="page0">
              <name> <text>page name</text> </name>
              <graphics><offset x="0" y="0"/></graphics>
              <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
              <place id="place1">
                <name> <text>Some place</text> </name>
                <initialMarking> <text>100</text> </initialMarking>
              </place>
              <transition id="transition1">
                <name> <text>Some transition </text> </name>
              </transition>
              <arc id="arc1" source="transition1" target="place1">
                <inscription> <text> 12 </text> </inscription>
              </arc>
              <arc id="arc2" source="place1" target="transition1">
                <inscription> <text> 13 </text> </inscription>
              </arc>
            </page>
          </net>(1)
        </pnml>
        """
    m = pnmlmodel(xnode;
                  tp=(("org.pnml.tool", "1.0", Parser.tokengraphics_content),
                      ("nupn", "1.2", Parser.nupn_content),
                      ("nupn", "1.1", Parser.nupn_content),), # toolinfo parser
                  lp=(tuple(:arctype, Parser.parse_arctype),), # label parser
                  ef=(tuple(:priority, PNML.enable_filter_priority),),
                ) # enabled filter
    @test m isa PnmlModel
    net = PNML.firstnet(m)
    foreach(println, pairs(net.toolparser)) # ::XMLNode, ::APN
    foreach(println, pairs(net.labelparser)) # ::XMLNode, ::APN; Symbol
    foreach(println, pairs(net.enabled_filters)) # ::Dict, ::Dict, ::APN, ::Symbol
end

@testset "pnmlmodel(empty_page)" begin
    empty_page = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="empty_page" type="pnmlcore">
                <page id="page"/>
            </net>
        </pnml>
    """
    @test_logs(match_mode=:all, pnmlmodel(empty_page))
 end

@testset "pnmlmodel(empty_net)" begin
    println("pnmlmodel(empty_net)")
    empty_net = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="empty_net" type="pnmlcore" />
        </pnml>
    """
    @test_logs(match_mode=:all, pnmlmodel(empty_net))
 end

@testset "pnmlmodel(empty_pnml)" begin
    println("pnmlmodel(empty_pnml)")
    empty_pnml = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        </pnml>
    """
    @test_throws("MalformedException: <pnml> does not have any <net> elements", pnmlmodel(empty_pnml))
 end

#^ Pattern to use? https://discourse.julialang.org/t/specializing-on-keyword-arguments/78263/3
# _f(a; b = default_b, c = default_c) = some code
# f(a; kwargs...) = isempty(kwargs) ? _f(a; c = c_specialized_for_default_b) : _f(a; kwargs...)

@testset "multiple empty net types" begin
    model = @test_logs(match_mode=:all, pnmlmodel(xml"""
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet">
        <name><text>net1</text></name>
        <page id="page1"/>
      </net>
      <net id="net2" type="pnmlcore"> <name><text>net2</text></name> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <name><text>net3</text></name> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <name><text>net4</text></name> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <name><text>net5</text></name> <page id="page5"/> </net>
    </pnml>
    """))

    @test PNML.namespace(model) == "http://www.pnml.org/version-2009/grammar/pnml"

    Base.redirect_stdio(stdout=devnull, stderr=devnull) do
        @show model
    end

    modelnets = nets(model)
    @test length(model.nets) == 5
    @test all(registry_of(n) isa IDRegistry for n in modelnets)

    for net in modelnets
        @test_opt pntd(net)
        ntup = PNML.find_nets(model, pntd(net))
        t = PNML.nettype(net)
        @test name(net) == string(pid(net)) # true by special construction
        for n in ntup
            @test t === PNML.nettype(n)
        end
    end

    @testset "model net $pntdsym" for pntdsym in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng,
                                                    :hlnet, :symmetric, :continuous]

        @test_opt pnmltype(pntdsym)
        #@test_opt  PNML.find_nets(model, pntdsym) #! Why will it be run-time dispatch to iterate?
        @test_call PNML.find_nets(model, pntdsym)

        for (l,m,r) in zip(PNML.find_nets(model, pntdsym),
                            PNML.find_nets(model, pnmltype(pntdsym)),
                            PNML.find_nets(model, string(pntdsym)))
            @test l === m === r
            @test l.type === m.type ===  r.type === pnmltype(pntdsym)
        end
    end

    # First use is here, so test mechanism here.
    @test PNML.ispid(:net1)(:net1)

    @test PNML.find_net(model, :net1) isa PnmlNet
    @test PNML.find_net(model, :net2) isa PnmlNet
    @test PNML.find_net(model, :net3) isa PnmlNet
    @test PNML.find_net(model, :net4) isa PnmlNet
    @test PNML.find_net(model, :net5) isa PnmlNet
    @test PNML.find_net(model, :XXXX) === nothing

    @test_call PNML.find_net(model, :net1)
    @test_opt  PNML.find_net(model, :net1)
end

@testset "node level traversal" begin
    pnmldoc = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
            <name> <text>P/T Net with one place</text> </name>
            <page id="page0">
            <place id="place1">
                <name> <text>Some place</text> </name>
                <initialMarking> <text>100</text> </initialMarking>
            </place>
            <transition id="transition1">
                <name> <text>Some transition </text> </name>
            </transition>
            <arc source="transition1" target="place1" id="arc1">
                <inscription> <text>12 </text> </inscription>
            </arc>
            <arc source="place1" target="transition1" id="arc2">
            </arc>
            </page>
        </net>
        </pnml>
        """
    for net in nets(pnmlmodel(pnmldoc)::PnmlModel)
        @test net isa PnmlNet
        # we harvest all declarations as one thing

        @test !isempty(collect(PNML.declarations(net)))

        for h in [PNML.has_variabledecl,
                    PNML.has_namedsort,
                    PNML.has_arbitrarysort,
                    PNML.has_partitionsort,
                    PNML.has_multisetsort,
                    PNML.has_productsort,
                    PNML.has_namedop,
                    PNML.has_arbitraryop,
                    PNML.has_partitionop,
                    PNML.has_feconstant,
                    PNML.has_useroperator]
            @test PNML.has_useroperator(net, :nosuch) == false
        end

        for d in [PNML.variabledecl,
                    PNML.namedsort,
                    PNML.arbitrarysort,
                    PNML.partitionsort,
                    PNML.multisetsort,
                    PNML.productsort,
                    PNML.namedop,
                    PNML.arbitraryop,
                    PNML.partitionop,
                    PNML.feconstant,
                    PNML.useroperator]
            @test_throws KeyError d(net, :nosuch)
        end

        @test PNML.has_operator(net, :nosuch) == false
        @test isempty(collect(PNML.operators(net)))
        @test PNML.operator(net, :nosuch) === nothing

        @test PNML.get_label(net, :nosuch) === nothing

        for page in pages(net)
            @test page isa Page
            @test @inferred(pid(page)) isa Symbol
            @test PNML.get_label(page, :XYZ) === nothing
            for p in places(page)
                @test p isa Place
                @test PNML.get_label(p, :XYZ) === nothing
                placeid = pid(p)::Symbol
                @test has_place(page, placeid)
                @test pid(place(page, placeid)) === placeid
                @test initial_marking(net, pid(p)) == initial_marking(p)
            end
            for transition in transitions(page)
                @test transition isa Transition
                @test pid(transition) isa Symbol
                @test PNML.get_label(transition, :XYZ) === nothing
                @test condition(net, pid(transition)) == condition(transition)
            end
            for arc in arcs(page)
                @test arc isa Arc
                @test pid(arc) isa Symbol
                @test PNML.get_label(arc, :XYZ) === nothing
                @test inscription(net, pid(arc)) == inscription(arc)
            end
        end
    end
end

println("\n-----------------------------------------")
println("AirplaneLD-col-0010.pnml")
println("-----------------------------------------")
@testset let testfile=joinpath(@__DIR__, "data", "AirplaneLD-col-0010.pnml")
    #println(testfile); flush(stdout)
    model = pnmlmodel(testfile)::PnmlModel
    #model = @test_logs(match_mode=:all, pnmlmodel(testfile)

    netvec = nets(model) # iterator
    @test length(netvec) == 1

    net = first(netvec)::PnmlNet{<:SymmetricNet}

    @test PNML.verify(net, false)

    @test pages(net) isa Base.Iterators.Filter
    @test only(allpages(net)) == only(pages(net))
    #todo compare pages(net) == allpages(net)
    @test firstpage(net)::Page == first(pages(net))::Page
    @test PNML.npages(net) == 1

    @test !isempty(arcs(firstpage(net)))
    @test PNML.narcs(net) >= 0

    @test !isempty(places(firstpage(net)))
    @test PNML.nplaces(net) >= 0

    @test !isempty(transitions(firstpage(net)))
    @test PNML.ntransitions(net) >= 0
    @test transitions(firstpage(net)) == transitions(first(pages(net)))

    @test PNML.nreftransitions(net) == 0
    @test isempty(PNML.reftransitions(net))

    @test PNML.nrefplaces(net) == 0
    @test isempty(PNML.refplaces(net))

    #!@test_call broken=false target_modules=t_modules pnmlmodel(testfile)
    @test_call nets(model)

    @test !isempty(repr(PNML.netdata(net)))
    @test !isempty(repr(PNML.netsets(firstpage(net))))
    @test_throws ArgumentError PNML.netsets(net)

    summary(stdout, PNML.netsets(firstpage(net)))

    #TODO apply metagraph toolinfos
end
