# ToolParser
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Holds a parser callable for a `<toolspecific>` tag's well-formed contents invoked as:

    `(tp::ToolParser)(node::XMLNode, pntd::APNTD)`

Will be in an iteratable collection that maps tool name & version to a parser callable.
See `toolspecific_content_fallback`.
"""
@auto_hash_equals struct ToolParser{T}
    toolname::String
    version::String
    func::T # arguments (::XMLNODE, ::PnmlNet{T}) where {T}
end

tag(tp::ToolParser) = name(tp::ToolParser)
name(tp::ToolParser) = tp.toolname
version(tp::ToolParser) = tp.version

"Return callable parser of XML into `ToolInfo`."
func(tp::ToolParser) = tp.func

# Invoke `<toolspecific>` parser callable `func` in `tp`.
function (tp::ToolParser)(node, net)
    tp.func(node, net)
end
