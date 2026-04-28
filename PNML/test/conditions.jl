using PNML, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

# # Conditions are for everybody, but we cannot (feasibily) test high-level
# @testset "condition $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
#     n1 = xml"""
#  <condition>
#     <text>pt==cts||pt==ack</text>
#     <structure>
#         <or>
#             <subterm>
#                 <equality>
#                     <subterm><variable refvariable="pt"/></subterm>
#                     <subterm><useroperator declaration="cts"/></subterm>
#                 </equality>
#             </subterm>
#             <subterm>
#                 <equality>
#                     <subterm><variable refvariable="pt"/></subterm>
#                     <subterm><useroperator declaration="ack"/></subterm>
#                 </equality>
#             </subterm>
#         </or>
#     </structure>
#     <graphics><offset x="0" y="0"/></graphics>
#     <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#     <unknown id="unkn">
#         <name> <text>unknown label</text> </name>
#         <text>content text</text>
#     </unknown>
#  </condition>
#     """
#     @testset for node in [n1]
#         dd = PNML.DeclDict()
#         # dd.variabledecls[:pt] = PNML.VariableDeclaration(:pt, "", DotSort())
#         # dd.namedoperators[:cts] = PNML.NamedOperator(:cts, "")
#         # dd.namedoperators[:ack] = PNML.NamedOperator(:ack, "")

#         cond = @test_logs(match_mode=:all,
#                 (:warn, "ignoring unexpected child of <condition>: 'unknown'"),
#                 PNML.parse_condition(node, net)
#         @show cond
#         @test text(cond) == "pt==cts||pt==ack"
#         # @test value(cond) isa PNML.Operator
#         # @test tag(value(cond)) == :or
#         @test PNML.has_graphics(cond) == true
#     end
# end
