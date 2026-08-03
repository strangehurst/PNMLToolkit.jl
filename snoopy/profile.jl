using EzXML, PNML
prosetup() = EzXML.root(EzXML.readxml("/home/jeff/Jules/PNML/snoopy/test1.pnml"))
x = prosetup()
using Profile

# #-----------------------------------------------------
# # r = PNML.PNMLIDRegistry()
# # VSCodeServer.@profview parse_pnml(x, r)
# # PNML.reset_reg!(r) # need to empty the registry
# # VSCodeServer.@profview parse_pnml(x, r) # ignore 1st run

# #-----------------------------------------------------
# node = xml"""
# <place id="place1">
#   <name> <text>with text</text> </name>
#   <initialMarking> <text>100</text> </initialMarking>
# </place>
# """
# tfx() = for i in 1:1000
#     PNML.parse_place(node, PNML.PnmlCoreNet(), PNML.registry())
# end
# # VSCodeServer.@profview tfx()


# #-----------------------------------------------------
# using EzXML, PNML
# fx() = for i in 1:1000
#     PNML.SimpleNet("""<?xml version="1.0"?>
# <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
#   <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
#     <name> <text>P/T Net with one place</text> </name>
#     <page id="page1">
#       <place id="place1">
# 	    <initialMarking> <text>100</text> </initialMarking>
#       </place>
#       <transition id="transition1">
#         <name><text>Some transition</text></name>
#       </transition>
#       <arc source="transition1" target="place1" id="arc1">
#         <inscription><text>12</text></inscription>
#       </arc>
#     </page>
#   </net>
# </pnml>""")
# end
# # VSCodeServer.@profview fx()

#-----------------------------------------------------
using EzXML, PNML

node = EzXML.root(EzXML.readxml("/home/jeff/Jules/PNML/snoopy/test1.pnml"))
node = EzXML.root(EzXML.readxml("/home/jeff/PetriNet/PNML/pnml-parser-tests/place.pnml"))
node = EzXML.root(EzXML.readxml("/home/jeff/PetriNet/PNML/MCC2023/StigmergyCommit-PT-02a/model.pnml"))
node = EzXML.root(EzXML.readxml("/home/jeff/PetriNet/PNML/MCC2023/StigmergyCommit-PT-11a/model.pnml"))

# fx() = for i in 1:1000
#     PNML.SimpleNet(node)
# end

# m = PNML.parse_pnml(node);
# n1 = PNML.first_net(m);
# PNML.flatten_pages!(n1);
# PNML.SimpleNet(n1)

# @code_warntype PNML.first_net(m) # from type-unstable Tuple{Vararg{PnmlNet}}
# @code_warntype PNML.flatten_pages!(n1)
# @code_warntype PNML.SimpleNet(n1)
# @code_warntype

# fx() = for i in 1:100000
#     PNML.SimpleNet(n1)
# end
# VSCodeServer.@profview fx()

# VSCodeServer.@profview PNML.SimpleNet(n2)

# VSCodeServer.@profview PNML.SimpleNet(node)

# using EzXML, PNML
# GC.enable_logging(true)
# node = EzXML.root(EzXML.readxml("/home/jeff/Jules/PNML/snoopy/test1.pnml"))
# PNML.SimpleNet(node)

# using EzXML, PNML
# node = EzXML.root(EzXML.readxml("/home/jeff/PetriNet/PNML/MCC2023/StigmergyCommit-PT-09b/model.pnml"))
# PNML.SimpleNet(node)

# #-----------------------------------------------------
# using EzXML, PNML
# arcnode = xmlroot("""<arc source="transition1" target="place1" id="arc1">
# </arc>""")
# placenode = xml"""<place id="place1">
# </place>"""
# transitionnode = xml"""<transition id ="t5">
# </transition>"""

# PNML.registry()
# PNML.parse_arc(arcnode, PNML.PnmlCoreNet(), PNML.registry())

# fx() = for i in 1:1000
#     PNML.arc(arcnode, PNML.PnmlCoreNet(), PNML.registry())
# end

# #-----------------------------------------------------
# @code_warntype PNML.parse_arc(arcnode, PNML.PnmlCoreNet(), PNML.registry())
# @code_warntype PNML.parse_arc(placenode, PNML.PnmlCoreNet(), PNML.registry())
# @code_warntype PNML.parse_arc(transitionnode, PNML.PnmlCoreNet(), PNML.registry())

# #-----------------------------------------------------

# #-----------------------------------------------------
# using EzXML, PNML


# PNML.CONFIG[].verbose = true;

# PNML.CONFIG[].warn_on_unclaimed = true;     # Customize some defaults

# n = PNML.SimpleNet("""<?xml version="1.0"?>
# <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
#   <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
#     <name> <text>P/T Net with one place</text> </name>
#     <page id="page1">
#       <place id="place1">
# 	    <initialMarking> <text>100</text> </initialMarking>
#       </place>
#       <transition id="transition1">
#         <name><text>Some transition</text></name>
#       </transition>
#       <arc source="transition1" target="place1" id="arc1">
#         <inscription><text>12</text></inscription>
#       </arc>
#     </page>
#   </net>
# </pnml>""");


# #-----------------------------------------------------
# julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl");
# const netxml = first(PNML.allchildren(x, "net"));
# @report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
