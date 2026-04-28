using PNML, Test, JET, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

@testset "type $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
    # Add usersort, namedsort duo as test context.
    net = make_net(pntd, :sorttype_net)
    PNML.namedsorts(net)[:N2] = PNML.NamedSort(:N2, "N2", DotSort(), net)

    n1 = xml"""
<type>
    <text>N2</text>
    <structure> <usersort declaration="N2"/> </structure>
</type>
    """
    typ = PNML.Parser.parse_sorttype(n1, net; parentid=:foobar)::SortType
    @test text(typ) == "N2"
    @test PNML.sortref(typ) isa PNML.SortRef # wrapping DotSort
    #! @test PNML.sortof(typ) == DotSort() #! does the name of a sort affect equal Sorts?
    @test PNML.has_graphics(typ) == false
    @test !occursin("Graphics", sprint(show, typ))
end
