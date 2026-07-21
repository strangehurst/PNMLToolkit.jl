
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Parsed by `net.toolparser[tool][version]` or [`toolspecific_content_fallback`](@ref)
"""
function parse_toolspecific(node, net::AbstractPnmlNet)
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
    content = tool_parser(node, net) # Parse node.
    #@show typeof(content) content typeof(content.elements)
    return Labels.ToolInfo(tool, version, content, net)
end

"""
    toolspecific_content_fallback(node::XMLNode, net::AbstractPnmlNet) -> AnyElement
Content of a `<toolspecific> `node` as parsed by `xmldict`.
The `net` argument is present to conform to the _toolparser interface_.
Some users may do net-specific parsing.
"""
function toolspecific_content_fallback(node::XMLNode, net::AbstractPnmlNet)
    anyelement(Symbol(EzXML.nodename(node)), node)
end

#-------------------------------------------------------------------
"""
    tokengraphics_content(node::XMLNode, pntd::AbstractPNTD) -> TokenGraphics

Example: ```<toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
        <tokenposition x="6" y="9"/>
    </tokengraphics>
</toolspecific>````

Parse `ToolInfo` content that is expected to be `<tokengraphics>`.
"""
function tokengraphics_content(node::XMLNode, net::AbstractPnmlNet)
    parse_tokengraphics(EzXML.firstelement(node), pntd_of(net))
end

"""
$(TYPEDSIGNATURES)

Parse place-transition net's (PTNet) toolspecific structure defined for token graphics.

See [`Labels.TokenGraphics`](@ref) and [`parse_tokenposition`](@ref).
"""
function parse_tokengraphics(node::XMLNode, pntd::AbstractPNTD)
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
    nupn_content(node::XMLNode, pntd::AbstractPNTD) -> NupnTool
    nupn_content(node::XMLNode, net::AbstractPnmlNet) -> NupnTool

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
nupn_content(node::XMLNode, net::AbstractPnmlNet) = nupn_content(node, pntd_of(net))
function nupn_content(node::XMLNode, pntd::AbstractPNTD)
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

"""
    toolkit_options(node, net|pntd) -> Labels.ToolkitOptions

Parse `ToolInfo` content for Pnml Toolkit options. Example:
```
<toolspecific tool="PNMLToolkit.jl" version="1.1">
    <filters>
        <filter>inhibit</filter>
        <filter>reset</filter>
        <filter>read</filter>
        <filter>capacity</filter>
        <filter>priority</filter>
        <filter>tpn</filter>
    </filters>
</toolspecific>
```
"""
function toolkit_options end
toolkit_options(node::XMLNode, net::AbstractPnmlNet) = toolkit_options(node, pntd_of(net))
function toolkit_options(node::XMLNode, pntd::AbstractPNTD)
    tk_options = anyelement(Symbol(EzXML.nodename(node)), node)
    @show tk_options
    e = elements(tk_options)
    @assert e[:tool] == "PNMLToolkit.jl"
    version = VersionNumber(e[:version])
    @assert version >= v"1.0"
    Labels.ToolkitOptions(map(Symbol, e["filters"]["filter"]))
end
