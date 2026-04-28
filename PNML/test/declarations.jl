using PNML, Test, JET
using InteractiveUtils
using Printf

include("TestUtils.jl")
using .TestUtils

#!
#! TODO add tests for variable declarations
#!

@testset "empty declarations $pntd" for pntd in PnmlTypes.core_nettypes()
    net = make_net(pntd, :empty_declaration)
    decl = @inferred Declaration parse_declarations!(net, xml"""<declaration key="test empty">
            <structure><declarations></declarations></structure>
        </declaration>""")

    @test length(decl.ddict) == 7 # nothing in <declarations>
    @test !isempty(decl.ddict)
    @test @inferred(Maybe{Graphics}, graphics(decl)) === nothing
    @test @inferred(Maybe{ToolInfo}, toolinfos(decl)) === nothing

    @test occursin(r"^Declaration", sprint(show, decl))
    @test_opt graphics(decl)
    @test_opt toolinfos(decl)

    @test_call graphics(decl)
    @test_call toolinfos(decl)
end

@testset "namedsort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="LegalResident" name="LegalResident">
                    <cyclicenumeration>
                        <feconstant id="LegalResident0" name="0"/>
                        <feconstant id="LegalResident1" name="1"/>
                    </cyclicenumeration>
                </namedsort>
                <namedsort id="MICSystem" name="MICSystem">
                    <cyclicenumeration>
                        <feconstant id="MICSystem0" name="0"/>
                        <feconstant id="MICSystem1" name="1"/>
                    </cyclicenumeration>
                </namedsort>
                <namedsort id="CINFORMI" name="CINFORMI">
                    <cyclicenumeration>
                        <feconstant id="CINFORMI0" name="0"/>
                        <feconstant id="CINFORMI1" name="1"/>
                    </cyclicenumeration>
                </namedsort>
                <!-- namedoperator -->
                <!-- arbitrarysort, arbitraryoperator -->
            </declarations>
        </structure>
        <graphics>	<position x="11" y="22" /> </graphics>
        <toolspecific tool="sometool" version="6.6">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknownchild />
    </declaration>
    """
    println()
    net = make_net(pntd, :namedsorts_net)
    @test_call target_modules=t_modules namedsorts(net)
    @test_opt target_modules=t_modules function_filter=pff namedsorts(net)
    #@show namedsorts(net)
    #foreach(println, pairs(namedsorts(net)))
    base_decl_length = length(namedsorts(net))
    #@show decl = parse_declaration!(net, [node])
    #@show decl net.ddict
    decl = @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
            parse_declaration!(net, [node])::Declaration) # Add 3 declarations.

    #println()
    #foreach(println, pairs(namedsorts(net)))
    # declarations in namedsorts twice
    @test length(namedsorts(net)) == base_decl_length + 6

    for nsort in values(namedsorts(net))
        #!@test typeof(nsort) <: NamedSort # is a declaration
        #@show nsort pid(nsort)
        @test isregistered(net.idregistry, pid(nsort))
        #!@test Symbol(name(nsort)) === pid(nsort) # NOT TRUE! name and id are the same.
        #!@test sortof(nsort) isa CyclicEnumerationSort
        #@test elements(sortof(nsort)) isa Vector{FEConstant}

        sortname = name(nsort)
        cesort   = sortdefinition(nsort)
        feconsts = sortelements(cesort, net) # should be iteratable ordered collection
        feconsts isa Vector{FEConstant}
        #!@test length(feconsts) == 2
        # for fec in feconsts
        #     @test fec isa FEConstant
        #     @test fec.id isa Symbol
        #     @test fec.name isa AbstractString
        #     @test isregistered(fec.id)
        #     @test endswith(string(fec.id), fec.name)
        # end
    end
end


@testset "partition declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="pluck" name="PLUCK">
                    <finiteenumeration>
                        <feconstant id="b1" name="b1" />
                        <feconstant id="b2" name="b2" />
                        <feconstant id="b3" name="b3" />
                   </finiteenumeration>
                </namedsort>
                <namedsort id="pluck2" name="PLUCK2">
                    <finiteenumeration>
                        <feconstant id="b4" name="b4" />
                        <feconstant id="b5" name="b5" />
                        <feconstant id="b6" name="b6" />
                   </finiteenumeration>
                </namedsort>

                <partition id="P1" name="P1">
                    <usersort declaration="pluck"/>
                    <partitionelement id="pe1" name="pe1">
                        <useroperator declaration="b1"/>
                        <useroperator declaration="b2"/>
                        <useroperator declaration="b3"/>
                    </partitionelement>tokenposition
                </partition>
                <partition id="P2" name="P2">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="pe2" name="pe2">
                        <useroperator declaration="b4"/>
                    </partitionelement>
                    <partitionelement id="pe3" name="pe3">
                        <useroperator declaration="b5"/>
                        <useroperator declaration="b6"/>
                    </partitionelement>
                </partition>
                <partition id="P3" name="P3">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="pe4" name="pe4">
                        <useroperator declaration="b4"/>
                        <useroperator declaration="b5"/>
                    </partitionelement>
                    <partitionelement id="pe5" name="pe5">
                        <useroperator declaration="b6"/>
                    </partitionelement>
                </partition>
            </declarations>
        </structure>
    </declaration>
    """

    net = make_net(pntd, :declaration_net)
    decl = @inferred Declaration parse_declaration!(net, [node])
    @test typeof(decl) <: Declaration

    # Examine 3 partition sorts
    for psort in values(partitionsorts(decl.ddict))
        # partition -> partition element -> fe constant
        @test typeof(psort) <: PartitionSort # is a declaration
        @test isregistered(net.idregistry, pid(psort))
        psort == partitionsort(net, pid(psort)) #! @inferred
        @test Symbol(name(psort)) === pid(psort) # name and id are the same.
        partname = @inferred Union{SubString{String}, String} name(psort)
        partsort = sortdefinition(psort) #! @inferred
        part_elements = sortelements(psort, net)::Vector{PartitionElement}

        for element in part_elements
            @test isregistered(net.idregistry, pid(element))
            @test Declarations.contains(element, :nosuch) == false
        end
        # println("partition $(repr(pid(psort))) $(repr(name(psort))) ",
        #     collect(Declarations.element_ids(psort)), " ",
        #     collect(Declarations.element_names(psort)))
        @test !isempty(Declarations.element_ids(psort))
        @test !isempty(Declarations.element_names(psort))
        Declarations.verify_partition(psort)
    end
end

@testset "arbitrary sort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <arbitrarysort id="id1" name="AGENT"/>
            </declarations>
        </structure>
    </declaration>
    """

    net = make_net(pntd, :arbitrarysort_net)
    decl = parse_declaration!(net, [node])
    @test typeof(decl) <: Declaration
    #@show arbitrarysort(net, :id1)
    @test name(arbitrarysort(net, :id1)) == "AGENT"
    @test name(arbitrarysorts(net)[:id1]) == "AGENT"
end
@testset "arbitrary sort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="dot2" name="SecondDot"> <dot/> </namedsort>
                <namedsort id="dot2" name="SecondDot"> <dot/> </namedsort>
            </declarations>
        </structure>
    </declaration>
    """
    net = make_net(pntd, :duplicate_id_net)
    @test_throws DuplicateIDException parse_declaration!(net, [node])
end


const nonsimple_sorts = (MultisetSort, ProductSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort)


# function _subtypes(type::Type)
#     out = Any[]
#     _subtypes!(out, type)
# end

function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(Base.Fix1(_subtypes!, out), subtypes(type))
    end
    return out
end
function _sorts()
    out = Any[]
    _subtypes!(out, AbstractSort)
end

@testset "equal sorts" begin
    println("============================")
    println(" TODO equal sorts: $(_sorts())")
    println("============================")
    #TODO PartitionSort is confused - a SortDeclaration
    # for s in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     println(s)
    #     a = s()
    #     b = s()
    #     @test PNML.Sorts.equals(a, a)
    # end

    # for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #         a = sorta()
    #         b = sortb()
    #         #println(repr(a), " == ", repr(b), " --> ", PNML.Sorts.equals(a, b), ", ", (a == b))
    #         sorta != sortb && @test a != b && !PNML.Sorts.equals(a, b)
    #         sorta == sortb && @test PNML.Sorts.equals(a, b)::Bool && (a == b)
    #     end
    # end

    #TODO Add tests for enumerated sorts, et al., with content.
    # MultisetSort
    # println("""

    # for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #         a = .MultisetSort(sorta())
    #         b = MultisetSort(sortb())
    #         sorta != sortb && @test a != b && !PNML.equals(a, b)
    #         sorta == sortb && @test PNML.equals(a, b)::Bool && (a == b)
    #     end
    # end
    # """)
    println("============================")
end
