"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Parse string into EzXML node.

$(TYPEDSIGNATURES)

See [`xmlnode`](@ref).
"""
macro xml_str(s)
    :(xmlnode($s))
end

"""
$(TYPEDSIGNATURES)

Parse XML string `s` into a `XMLNode`.
"""
xmlnode(s::AbstractString) = EzXML.root(EzXML.parsexml(s))::XMLNode

#~ How expensive are these XPath queries?

# https://scrapfly.io/blog/xpath-cheatsheet/
# https://en.wikipedia.org/wiki/XPath#Axis_specifiers
"""
    firstchild(node::XMLNode, tag::AbstractString) -> Maybe{XMLNode}

Return first immediate child of `el` that is a `tag` or nothing.
"""
function firstchild(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    # '.'  is short for self::node(), '/' selects direct child
    EzXML.findfirst("./x:$tag | ./$tag", node, ("x" => namespace,))::Maybe{XMLNode}
    # `("x" => namespace,)` optional prefix defaults to `pnml_ns`.
end

"""
    allchildren(node::XMLNode, tag::AbstractString) -> Vector{XMLNode}

Return vector of `el`'s immediate children with `tag`.
"""
function allchildren(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    # '.' is short for self::node(), '/' selects direct child
    EzXML.findall("./x:$tag | ./$tag", node, ("x" => namespace,))::Vector{XMLNode}
end

"""
    alldecendents(node::XMLNode, tag::AbstractString) -> Vector{XMLNode}

Return vector of node's immediate children and decendents with `tag`.
"""
function alldecendents(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    # '.'  is short for self::node(), '//' selects any decendent
    EzXML.findall(".//x:$tag | .//$tag", node, ("x" => namespace,))::Vector{XMLNode}
end

"""
    check_nodename(node::XMLNode, str::AbstractString)

Throw if `nodename(node)` != `str`, otherwise return `str`.
"""
function check_nodename(node::XMLNode, str::AbstractString)
    if EzXML.nodename(node) != str
        throw(ArgumentError(string("element name wrong, expected ", str,
                                   ", got ", EzXML.nodename(node))::String))
    end
    return str
end

"""
$(TYPEDSIGNATURES)
Return registered symbol from id attribute of node. See [`IDRegistry`](@ref).
"""
function register_idof!(registry::IDRegistry, node::XMLNode)
    EzXML.haskey(node, "id") || throw(MissingIDException(EzXML.nodename(node)))
    return register_id!(registry, Symbol(@inbounds(node["id"])))
end

"""
$(TYPEDSIGNATURES)
Return XML attribute value.
"""
function attribute(node::XMLNode, key::AbstractString, msg::String="attribute $key missing")
    key == "id" && error("'id' attribute not handled here")
    EzXML.haskey(node, key) || throw(MalformedException(msg))
    return @inbounds node[key]
end


"""
    unwrap_subterm(st::XMLNode) -> Symbol, XMLNode

Unwrap a `<subterm>` by returning tuple of child node and child's tag.
"""
function unwrap_subterm(st::XMLNode)
    check_nodename(st, "subterm")
    child = EzXML.firstelement(st)
    return (Symbol(EzXML.nodename(child)), child)
end

#TODO test pnml_namespace
"""
$(TYPEDSIGNATURES)

Return namespace of `node` or default value [`pnml_ns`](@ref) with warning (or error).
"""
function pnml_namespace(node::XMLNode;
                        missing_ns_fatal::Bool=false,
                        default_ns::String=pnml_ns)
    if EzXML.hasnamespace(node)
        return EzXML.namespace(node)
    else
        emsg = "$(EzXML.nodename(node)) missing namespace"
        missing_ns_fatal ? throw(ArgumentError(emsg)) : @warn(emsg)
        return default_ns
    end
end
