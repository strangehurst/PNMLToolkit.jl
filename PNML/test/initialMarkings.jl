using PNML, Test, JET
include("TestUtils.jl")
using .TestUtils, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

#------------------------------------------------
@testset "PT initMarking $pntd" for pntd in (PnmlCoreNet(), ContinuousNet())
    node = xmlnode("""
    <initialMarking>
        <text> $(is_continuous(pntd) ? "123.0" : "123") </text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </initialMarking>
    """)
    #println(str)

    net = make_net(pntd, :pt_initmark)
    @show value_type(Marking, pntd)
    @show sortref(value_type(Marking, pntd))

    placetype = SortType("$pntd initMarking",
        sortref(value_type(Marking, pntd))::SortRef,
        nothing, nothing, net)

    # Parse ignoring unexpected child
    mark = @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
                parse_initialMarking(node, placetype, net; parentid=:xxx)::Marking)
    #@test typeof(value(mark)) <: Union{Int,Float64}
    @test mark()::Union{Int,Float64} == 123

    # Integer
    mark1 = Marking(23, net)
    @test_opt broken=false Marking(23, net)
    @test_call Marking(23, net)
    @test typeof(mark1()) == typeof(23)
    @test mark1() == 23
    @test_opt broken=false mark1()
    @test_call mark1()

    @test graphics(mark1) === nothing
    @test toolinfos(mark1) === nothing || isempty(toolinfos(mark1))

    # Floating point
    mark2 = Marking(3.5, net)
    #@show mark2 mark2()
    @test_opt broken=false Marking(3.5, net)
    @test_call Marking(3.5, net)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()
    @test graphics(mark2) === nothing
    @test toolinfos(mark2) === nothing || isempty(toolinfos(mark2))
end

@testset "HL initMarking" begin
     @testset "3`dot $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        #println("\n3`dot $pntd")
        node = xml"""
        <hlinitialMarking>
            <text>3`dot</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.
        net = make_net(pntd, :dot_net)
        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("XXX", NamedSortRef(:dot), net)

        mark = parse_hlinitialMarking(node, placetype, net; parentid=:bogusid)
        #@show mark
        @test mark isa Marking

        @test term(mark) isa Bag
        @test text(mark) == "3`dot"
        #println(); flush(stdout)

        @test has_graphics(mark) == false # This instance does not have any graphics.
        #@show term(mark) toexpr(term(mark), NamedTuple(), net) #! debug
        @test eval(toexpr(term(mark), NamedTuple(), net)) isa PnmlMultiset
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant()

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype
    end

    # 0-arity operators are constants
    # @testset "useroperator" for pntd in PnmlTypes.all_nettypes(is_highlevel)
    #     println("\nuseroperator $pntd")
    #     node = xml"""
    #     <hlinitialMarking>
    #         <text>useroperator</text>
    #         <structure>
    #             <useroperator declaration="uop"/>
    #         </structure>
    #     </hlinitialMarking>
    #     """
    #     @with idregistry => IDRegistry() begin
    #         namedoperators()[:uop] = NamedOperator(:uop, "uop")
    #         placetype = SortType("YYY", usersort(ddict, :uop))
    #         mark = parse_hlinitialMarking(node, placetype, pntd)
    #         @test mark isa Marking
    #     end
    # end


   @testset "placetype error" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        #println("\nplacetype error")
        node = xml"""
        <hlinitialMarking>
            <text>3`dot</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.
        net = make_net(pntd, :placetype_error_net)
        sort = ArbitrarySort(:foo, "ArbSort", net)
        fill_sort_tag!(net, :foo, sort)

        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        # @show placetype = SortType("XXX", ArbitrarySortRef(:foo), ctx.ddict)

        # mark = parse_hlinitialMarking(node, placetype, net; parentid=:bogusid)
    end

    # add two multisets: another way to express 3 + 2
    @testset "3`dot ++ 2'dot" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        #println("\n\"3'dot ++ 2'dot\" $pntd")
        #~ @show
        node = xml"""
        <hlinitialMarking>
            <text>3'dot ++ 2'dot</text>
            <structure>
                <add>
                    <subterm>
                        <numberof>
                        <subterm><dotconstant/></subterm>
                        <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                    <subterm>
                        <numberof>
                        <subterm><dotconstant/></subterm>
                        <subterm><numberconstant value="2"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                </add>
            </structure>
        </hlinitialMarking>
        """
        net = make_net(pntd, :dot_dot)
        placetype = SortType("dot sorttype", NamedSortRef(:dot), net)
        mark = Parser.parse_hlinitialMarking(node, placetype, net; parentid=:tmp)
        #TODO add tests
    end
    # The constant eight.
    @testset "1`8" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        #println("\n1`8 $pntd")
        #~ @show
        node = xml"""
        <hlinitialMarking>
            <text>1`8</text>
            <structure>
                <numberof>
                <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                <subterm><numberconstant value="8"><positive/></numberconstant></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        net = make_net(pntd, :dot_1)
        placetype = SortType("positive sorttype", NamedSortRef(:positive), net)
        mark = parse_hlinitialMarking(node, placetype, net; parentid=:xxx)
        val = eval(toexpr(term(mark), NamedTuple(), net))::PnmlMultiset
        @test multiplicity(val, NumberConstant(8, NamedSortRef(:positive))()) == 1
        @test NumberConstant(8, NamedSortRef(:positive))() in multiset(val)
     end

    # This is the same as when the element is omitted.
    @testset "x" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        net = make_net(pntd, :empty_hlinitialMarking)
        placetype = SortType("testdot", NamedSortRef(:dot), net)
        @test_throws Exception parse_hlinitialMarking(node, placetype, net; parentid=:xxx)
    end

    #println()
end

@testset "FIFO initMarking" begin

     @testset "FIFO $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
        #println("\n3`dot $pntd")
        node = xml"""
        <fifoinitialMarking>
            <text>FIFO(dot)</text>
            <structure>
                <makelist>
                    <dot/>
                    <subterm><dotconstant/></subterm>
                    <subterm><dotconstant/></subterm>
                    <subterm><dotconstant/></subterm>
                </makelist>
            </structure>
        </fifoinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.

        net = make_net(pntd, :fifi_net)

        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("FIFO", NamedSortRef(:dot), net)

        mark = parse_fifoinitialMarking(node, placetype, net; parentid=:bogusid)
        #@show mark
        @test mark isa Marking

        #@test PNMLterm(mark) isa Bag
        #@test text(mark) == "3`dot"
        #println(); flush(stdout)

        @test has_graphics(mark) == false # This instance does not have any graphics.
        #@show term(mark) toexpr(term(mark), NamedTuple(), net) #! debug
        @test eval(toexpr(term(mark), NamedTuple(), net)) isa Vector{DotConstant}
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant()
    end
end # fifoinitialMarking


# @testset "<All,All>" for pntd in PnmlTypes.all_nettypes(is_highlevel)
#     println("\n<All,All> $pntd")
#     # <All,All> example from Sudoku-COL-A-N01.pnml
#     #~ YES, markings can be tuples, an operator, cries for TermInterface,Metatheory
#     #
#     node = xml"""
#     <hlinitialMarking>
#         <text>&lt;All,All&gt;</text>
#         <structure>
#             <tuple>
#                 <subterm><all><usersort declaration="N1"/></all></subterm>
#                 <subterm><all><usersort declaration="N2"/></all></subterm>
#             </tuple>
#         </structure>
#         <graphics><offset x="0" y="0"/></graphics>
#         <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#     </hlinitialMarking>
#  """

#     dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort())
#     dd.namedsorts[:N1]  = NamedSort(:N1, "N1", DotSort())
#     dd.namedsorts[:N2]  = NamedSort(:N2, "N2", DotSort())

#     mark = parse_hlinitialMarking(node, placetype, pntd)

#     #@test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <hlinitialMarking>: 'unknown'"),
#     @test mark isa AbstractLabel
#     @test mark isa Marking
#     @test has_graphics(mark) == true
#     @test occursin("Graphics", sprint(show, mark))

#     # Following HL text,structure label pattern where structure is a `Term`.
#     @test text(mark) == "<All,All>"
#     markterm = value(mark)
#     #~ @show markterm
#     @test markterm isa AbstractTerm
#     @test markterm isa Operator
#     @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple

#     @test arity(markterm) == 2
#     #~ @show inputs(markterm)[1:1]
#     # # Decend each element of the term.
#     # @test tag(axn) == "subterm"
#     # @test value(axn) isa Vector #!{XmlDictType}

#     # all1 = value(axn)[1]
#     # @test tag(all1) == "all"
#     # @test value(all1) isa XmlDictType
#     # use1 = value(all1)["usersort"]
#     # @test use1 isa XmlDictType
#     # @test use1[:declaration] == "N1"
#     # @test _attribute(use1, :declaration) == "N1"

#     # all2 = value(axn)[2]
#     # @test tag(all2) == "all"
#     # @test value(all2) isa XmlDictType
#     # use2 = value(all2)["usersort"]
#     # @test use2 isa XmlDictType
#     # @test use2[:declaration] == "N2"
#     # @test _attribute(use2, :declaration) == "N2"
# end
