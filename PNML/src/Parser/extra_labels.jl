"""
    unexpected_label!(extralabels, child, tag, net; parentid)

Apply a labelparser to `child` if one matches `tag`, otherwise call [`xmldict`](@ref).
Add to `extralabels`.
"""
function unexpected_label!(extralabels::AbstractDict, child::XMLNode, tag::Symbol, net; parentid::Symbol)
    #println("unexpected_label! $tag")
    if haskey(net.labelparser, tag)
        #@error "labelparser[$(repr(tag))] " net.labelparser[tag] #! bring-up
        extralabels[tag] = net.labelparser[tag](child, net, parentid)
    else
        xd = xmldict(child)
        xd isa AbstractString &&
            error("PNML Labels must have XML structure, not just text content, found $xd")
        extra = PnmlLabel(tag, xd, net)
        @info "add PnmlLabel $(repr(tag)) to $(repr(parentid))" extra #! bring-up/logginng
        extralabels[tag] = extra
    end
    return nothing
end
