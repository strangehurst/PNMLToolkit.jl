using EzXML, AbstractTrees, NamedTupleTools, Preferences
using PNML
#using PNML: MalformedException, PnmlModel, XMLNode, allchildren, check_nodename, parse_net

"Test input file."
const fname = "test1.pnml"

const x = EzXML.root(EzXML.readxml(fname));
const r = PNML.IDRegistry();
const m = PNML.pnmlmodel(x; idregistry=r);

function pnml_ff(@nospecialize(ft))
    #@show ft
    if ft === typeof(PNML.EzXML.nodename) ||
        ft === typeof(PNML.NamedTupleTools.merge) ||
        ft === typeof(PNML.merge) ||
        ft === #typeof(PNML._harvest_any) ||
        ft === typeof(PNML.register_id!) ||
        false
        return false
    end
    return true
end

#=
julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl"); const netxml = first(allchildren("net", x)); @report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
=#
# function top_net(x::XMLNode)
#     netxml = first(allchildren(x, "net"))
#     #@report_opt target_modules=(PNML,) function_filter=pnml_ff PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry(); ids=(:foo,))
# end

# function timed_parse(node::XMLNode)
#     #! DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
#     # Bypass part of PNML flow by decending into the XML tree. #! This is exploratory (surgery?).
#     #
#     nn = check_nodename(node, "pnml") # Top of the pnml model.
#     nets = allchildren("net", node) # That can have one or more nets of any pnml net definition types.
#     isempty(nets) && throw(MalformedException("$nn does not have any <net> elements"))

#     reg = registry()
#     # Call parse_net directly.
#     net_vec = parse_net.(nets, Ref(reg))
#     net_tup = tuple(net_vec...)
#     PnmlModel(net_tup, pnml_ns) #! pnml_ns
# end


#=

julia> @report_opt function_filter=pnml_ff EzXML.root(EzXML.readxml(fname))
julia> @report_opt function_filter=pnml_ff registry()
julia> @report_opt function_filter=pnml_ff parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,) parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,) parse_pnml(x, r)

julia> @report_opt target_modules = (PNML,) parse_top_net(x,1)

julia> @code_warntype parse_pnml(x, r)

julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time include("setup.jl")

julia> top_net(x)

@show pid.(nets(m))
@show nettype.(nets(m))

@show typeof(nets(m)[1])
=#

"usage: showtree.(nets(m))"
function showtree(n)
    println()
    AbstractTrees.print_tree(n)
end
#include("defaults_types.jl")
