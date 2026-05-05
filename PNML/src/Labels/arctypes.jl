"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arc type label.
"""
@kwdef struct ArcType <: Annotation
    text::String = ""
    arctype::ArcTypeEnum.T = ArcTypeEnum.Normal
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
end

arctype(at::ArcType) = at.arctype
