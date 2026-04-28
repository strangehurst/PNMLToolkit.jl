#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
#! Extension point. user supplied parser -> Annotation.
# Could do conversion from xmldict.
#! 2 collections, one for PnmlLabels other for other Annotations?

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
    add_toolinfo!(collection, node, net) -> collection

Parse and add [`ToolInfo`](@ref) to `infos` collection, return `infos`.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(infos::Vector{ToolInfo}, node, net)
    return push!(infos, parse_toolspecific(node, net))
end

"""
    add_toolinfo(infos::Maybe{collection}, node::XMLNode, net) -> collection

Allocate storage for `infos` on first use. Then add to `infos`.
"""
function add_toolinfo(infos::Maybe{Vector{ToolInfo}}, node::XMLNode, net)
    i = isnothing(infos) ? ToolInfo[] : infos
    return add_toolinfo!(i, node, net)
end
