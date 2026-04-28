"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: Annotation
    text::String
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
end
