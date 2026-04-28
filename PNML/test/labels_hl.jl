using PNML, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

# @testset "structure $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
#     node = xml"""
#      <structure>
#         <tuple>
#             <subterm><all><usersort declaration="N1"/></all></subterm>
#             <subterm><all><usersort declaration="N2"/></all></subterm>
#         </tuple>
#      </structure>
#     """

#     tup = axn["tuple"]
#     sub = tup["subterm"]
#     #--------
#     all1 = sub[1]["all"]
#     usr1 = all1["usersort"]
#     @test value(usr1) == "N1"
#     @test value(axn["tuple"]["subterm"][1]["all"]["usersort"]) == "N1"
#     #--------
#     all2 = sub[2]["all"]
#     usr2 = all2["usersort"]
#     @test value(usr2) == "N2"
#     @test value(axn["tuple"]["subterm"][2]["all"]["usersort"]) == "N2"
# end
