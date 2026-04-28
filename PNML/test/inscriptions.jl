using PNML, Test
include("TestUtils.jl")
using .TestUtils
using EzXML: EzXML
using XMLDict: XMLDict

@testset "PT inscription $pntd" for pntd in  (PnmlCoreNet(), ContinuousNet())
    n1 = xml"""<inscription>
        <text> 12 </text>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>unknown content text</text>
        </unknown>
    </inscription>"""
    net = make_net(pntd, :pt_inscription_net)

    inscript = @test_logs(match_mode=:any,
                    (:warn, r"^ignoring unexpected child of <inscription>: 'unknown'"),
                    parse_inscription(n1, :nothing, :nothing, net; parentid=:xxx))
    @test inscript isa PNML.Inscription
    #@test_broken typeof(eval(value(inscript))) <: Union{Int,Float64}
    #@show inscript
    #@test_broken inscript() == 12
    #@test graphics(inscript) !== nothing
    #@test toolinfos(inscript) === nothing || !isempty(toolinfos(inscript))
    #@test_throws MethodError labels(inscript)

    #@test occursin("Graphics", sprint(show, inscript))
end

# @testset "hlinscription $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
#     println("\nhlinscription $pntd")
#     n1 = xml"""
#     <hlinscription>
#         <text>&lt;x,v&gt;</text>
#         <structure>
#             <tuple>
#               <subterm><variable refvariable="x"/></subterm>
#               <subterm><variable refvariable="v"/></subterm>
#             </tuple>
#         </structure>
#         <graphics><offset x="0" y="0"/></graphics>
#         <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#       </hlinscription>
#     """
#     dd.variabledecls[:x] = PNML.VariableDeclaration(:x, "", DotSort())
#     dd.variabledecls[:v] = PNML.VariableDeclaration(:v, "", DotSort())


#     insc = @test_logs(match_mode=:all,
#             (:warn,"ignoring unexpected child of <hlinscription>: 'unknown'"),
#             PNML.Parser.parse_hlinscription(n1, pntd)

#     @test typeof(insc) <: PNML.AbstractLabel
#     @test PNML.has_graphics(insc) == true

#     @test text(insc) isa Union{Nothing,AbstractString}
#     @test text(insc) == "<x,v>"

#     @test occursin("Graphics", sprint(show, insc))

#     #@show value(insc)
#     inscterm = value(insc)
#     @test inscterm isa PNML.AbstractTerm
#     @test tag(inscterm) === :tuple
#     @test arity(inscterm) == 2
#     @test inputs(inscterm)[1] isa PNML.Variable
#     @test inputs(inscterm)[2] isa PNML.Variable
#     @test tag(inputs(inscterm)[1]) == :x
#     @test tag(inputs(inscterm)[2]) == :v
#     #@test value(inputs(inscterm)[1]) Needs DeclDict
#     #@test value(inputs(inscterm)[2]) Needs DeclDict
# end
