# LabelParser
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Maps a `Symbol` to a callable for parsing an XML label `<tag>`'s well-formed contents.
The parser will be called as func(node, net) and return a label object.

See [`fill_builtin_labelparsers!`](@ref) for some built-in label parsers.
"""
@auto_hash_equals struct LabelParser
    tag::Symbol
    func::Any # callable
end

tag(lp::LabelParser) = lp.tag

"LabelParser callable: func(lp)(::XMLNode, ::AbstractPnmlType)) -> PnmlLabel"
func(lp::LabelParser) = lp.func
