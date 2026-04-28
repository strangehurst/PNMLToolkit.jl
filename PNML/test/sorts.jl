using PNML, Test, JET, InteractiveUtils, Printf

include("TestUtils.jl")
using .TestUtils
using PNML: fill_sort_tag!, fill_builtin_sorts!, fill_builtin_labelparsers!

@testset "parser_context" begin
    println("parser_context")
    pntd = PnmlCoreNet()
    net = make_net(pntd, :parser_context_net)

    @test_call target_modules=t_modules NamedSort(:X, "X", PositiveSort(), net)
    @test_opt target_modules=t_modules function_filter=pff NamedSort(:X, "X", PositiveSort(), net)

    @test_call target_modules=t_modules fill_sort_tag!(net, :X, NamedSort(:X, "X", PositiveSort(), net))
    @test_opt broken=true target_modules=t_modules function_filter=pff fill_sort_tag!(net, :X, NamedSort(:X, "X", PositiveSort(), net))
    builtin_sorts = ((:integer, "Integer", Sorts.IntegerSort()),
                    (:natural, "Natural", Sorts.NaturalSort()),
                    (:positive, "Positive", Sorts.PositiveSort()),
                    (:real, "Real", Sorts.RealSort()),
                    (:bool, "AbstractSortRefBool", Sorts.BoolSort()),
                    (:null, "Null", Sorts.NullSort()),
                    (:dot, "Dot", Sorts.DotSort())
                    )
    for (tag, name, sort) in builtin_sorts
        nsort = NamedSort(tag, name, sort, net)
        @test_call target_modules=t_modules fill_sort_tag!(net, tag, nsort)
        @test_opt broken=true target_modules=t_modules function_filter=pff fill_sort_tag!(net, tag, nsort)
    end

    @test_call target_modules=t_modules  fill_builtin_sorts!(net)
    @test_call target_modules=t_modules  fill_builtin_labelparsers!(net)
    @test_opt broken=true target_modules=t_modules function_filter=pff fill_builtin_sorts!(net)
    @test_opt broken=false target_modules=t_modules function_filter=pff fill_builtin_labelparsers!(net)
end

@testset "parse_sort $pntd" for pntd in PnmlTypes.core_nettypes()
    net = make_net(pntd, :parse_sort_net)
    #println("\nparse_sort $pntd")

    IDRegistrys.reset_reg!(net.idregistry)
    @inferred fill_sort_tag!(net, :X2, NamedSort(:X2, "X2", PositiveSort(), net))
    sortref = @inferred SortRef parse_sort(xml"<usersort declaration=\"X2\"/>", net)
    ts = @inferred NamedSort to_sort(sortref, net)
    sort = @inferred sortdefinition(ts)
    @test sort === @inferred PositiveSort()
    @test occursin(r"^PositiveSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<dot/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === DotSort() # not a built-in
    @test occursin(r"^DotSort", sprint(show, sort))
    @test eltype(sort) == Bool

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<bool/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === BoolSort()
    @test occursin(r"^BoolSort", sprint(show, sort))
    @test eltype(sort) == Bool

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<integer/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === IntegerSort()
    @test occursin(r"^IntegerSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<natural/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === NaturalSort()
    @test occursin(r"^NaturalSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<positive/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === PositiveSort()
    @test occursin(r"^PositiveSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<real/>", net)
    sort = to_sort(sortref, net)::NamedSort |> sortdefinition
    @test sort === RealSort()
    @test occursin(r"RealSort", sprint(show, sort))
    @test eltype(sort) == Float64

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                            </cyclicenumeration>""", net, :testenum1)
    sort = to_sort(sortref, net)::NamedSort
    #@test occursin(r"^CyclicEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                        </finiteenumeration>""", net, :testenum2)

    sort = to_sort(sortref, net)::NamedSort
    #@test occursin(r"^FiniteEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", net, :testfiniteintrange)

    sort = to_sort(sortref, net)::NamedSort
    #@test occursin(r"^FiniteIntRangeSort", sprint(show, sort))
    @test eltype(sort) == Int64

    # productsort is expected to be enclosed in a namedsort
    @test_logs(match_mode=:any, (:warn, r"^ISO 15909 Standard allows.*"),
               parse_sort(xml"""<productsort/>""", net, :emptyproduct, "emptyproduct"))

    IDRegistrys.reset_reg!(net.idregistry)
    sortref = parse_sort(xml"""<productsort>
                                <integer/>
                                <integer/>
                        </productsort>""", net, :redundant, "redundant")
    sort = to_sort(sortref, net)::ProductSort
    @test occursin(r"^ProductSort", sprint(show, sort))
    @test eltype(sort) == Tuple{Int64,Int64} #! TODO XXX

    IDRegistrys.reset_reg!(net.idregistry)
    fill_sort_tag!(net, :speed, NamedSort(:speed, "speed", PositiveSort(), net))
    fill_sort_tag!(net, :distance, NamedSort(:distance, "dictance", NaturalSort(), net))
    sortref= parse_sort(xml"""<productsort>
                        <usersort declaration="speed"/>
                        <usersort declaration="distance"/>
                        </productsort>""", net, :someproduct, "someproduct")
    sort = to_sort(sortref, net)::ProductSort
    @test sort isa ProductSort
    @test occursin(r"^ProductSort", sprint(show, sort))
    @test eltype(sort) == Tuple{Int64,Int64} #! TODO XXX

    # IDRegistrys.reset_reg!(ctx.idregistry)
    # sort = parse_sort(xml"""<productsort>
    #                            <usersort declaration="id1"/>
    #                            <natural/>
    #                         </productsort>""", pntd)::ProductSort
    #  @test_logs sprint(show, sort)
    # @test_logs eltype(sort)

    IDRegistrys.reset_reg!(net.idregistry)
    fill_sort_tag!(net, :duck, NamedSort(:duck, "duck", PositiveSort(), net))

    sortref = parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", net)
    sort = to_sort(sortref, net)#::MultisetSort
    fill_sort_tag!(net, :amultiset, sort) #~ test of method needed here
    @test occursin(r"^MultisetSort", sprint(show, sort))
    @test eltype(sort) == Any

    #^ ArbitrarySort

    IDRegistrys.reset_reg!(net.idregistry)
    sort = ArbitrarySort(:arbsort, "ArbSort", net)
    fill_sort_tag!(net, :arbsort, sort) #~ test of method needed here
    #!@test occursin(r"^ArbitrarySort", sprint(show, sort))
    #!@show @test_logs eltype(sort)
    #!@show decldict(net)

    #^ String

    IDRegistrys.reset_reg!(net.idregistry)
    #println()
    #@show net typeof(decldict(net))
    sortref = parse_sort(xml"<string/>", net)
    sort = to_sort(sortref, net)::NamedSort
    @test sortelements(sort, net) == ("",)
    #@test occursin(r"^StringSort", sprint(show, sort))
    @test eltype(sort) == String
    @test first(sortelements(sort, net)) == ""

    #TODO PartitionSort tests here
end
