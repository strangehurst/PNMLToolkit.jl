
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Parsed by `net.toolparser[tool][version]` or [`toolspecific_content_fallback`](@ref)
"""
function parse_toolspecific(node, net::APN)
    check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    isempty(tool) && error("<toolspecific> tool attribute cannot be empty string")
    isempty(version) && error("<toolspecific> version attribute cannot be empty string")

    # Find parser for tool, version.
    tool_parser = if haskey(net.toolparser, tool) &&
                     haskey(net.toolparser[tool], version)
        net.toolparser[tool][version]
    else
        toolspecific_content_fallback
    end
    #@show tool, version, tool_parser
    content = tool_parser(node, net) # Run ToolParser callable.
    return Labels.ToolInfo(tool, version, content, net)
end

"""
    toolspecific_content_fallback(node::XMLNode, net::APN) -> AnyElement
Content of a `<toolspecific> `node` as parsed by `xmldict`.
The `net` argument is present to conform to the _toolparser interface_.
Some users may do net-specific parsing.
"""
function toolspecific_content_fallback(node::XMLNode, net::APN)
    anyelement(Symbol(EzXML.nodename(node)), node)
end

#-------------------------------------------------------------------
"""
    tokengraphics_content(node::XMLNode, pntd::APNTD) -> TokenGraphics

Parse `ToolInfo` content that is expected to be `<tokengraphics>`.
"""
function tokengraphics_content(node::XMLNode, net::APN)
    parse_tokengraphics(EzXML.firstelement(node), pntd(net))
end

"""
$(TYPEDSIGNATURES)

Parse place-transition net's (PTNet) toolspecific structure defined for token graphics.
See [`Labels.TokenGraphics`](@ref) and [`parse_tokenposition`](@ref).
"""
function parse_tokengraphics(node::XMLNode, pntd::APNTD)
    nn = check_nodename(node, "tokengraphics")
    tpos = coordinate_type(pntd)[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "tokenposition"
            push!(tpos, parse_tokenposition(child, pntd))
        else
            @warn "ignoring unexpected child of <tokengraphics>: '$tag'"
        end
    end
    if isempty(tpos)
        @warn "tokengraphics does not have any <tokenposition> elements"
    end
    Labels.TokenGraphics(tpos)
end

#-------------------------------------------------------------------
"""
    nupn_content(node::XMLNode, pntd::APNTD) -> NupnTool
    nupn_content(node::XMLNode, net::APN) -> NupnTool

Parse `ToolInfo` content. Example:
```
<toolspecific tool="nupn" version="1.1">
    <size places="P" transitions="T" arcs="A"/>
    <structure units="U" root="R" safe="S">
        <unit id="I">
            <places>PL</places>
            <subunits>UL</subunits>
        </unit>
    </structure>
    </toolspecific>
```
"""
function nupn_content end
nupn_content(node::XMLNode, net::APN) = nupn_content(node, pntd(net))
function nupn_content(node::XMLNode, pntd::APNTD)
    nupn = anyelement(Symbol(EzXML.nodename(node)), node)
    #@show nupn
    e = elements(nupn)
    @assert e[:tool] == "nupn"
    @assert e[:version] == "1.1"
    units = Labels.NupnUnit[]
    for u in e["unit"]
        # nothing | whitespace-separated list of place identifiers
        places = isempty(u["places"]) ? Symbol[] : Symbol.(split(u["places"]))
        # nothing | whitespace-separated list of unit identifiers
        subunits = isempty(u["subunits"]) ? Symbol[] : Symbol.(split(u["subunits"]))
        push!(units, Labels.NupnUnit(Symbol(u[:id]), places, subunits))
    end
    Labels.NupnTool(; nplaces = parse(Int, e["size"][:places]),
                      ntransitions = parse(Int, e["size"][:transitions]),
                      narcs = parse(Int, e["size"][:arcs]),
                      nunits = parse(Int, e["structure"][:units]),
                      root = Symbol(e["structure"][:root]),
                      safe = parse(Bool, e["structure"][:safe]),
                      units
                    )
end
