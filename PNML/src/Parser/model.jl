"""
    pnmlmodel([filename::AbstractString|node::XMLNode]; kwargs...)

Build a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref) from either:

   - a file containing XML that is parsed into a XMLNode,
   - a XMLNode,
   - if no source, use an empty net.

XMLNode is an alias for EzXML.Node.

# Arguments

"""
function pnmlmodel end

function pnmlmodel(; kwargs...)
    D()&& println("\n## pnmlmodel with 1 empty pnmlcore net")
    empty_model = xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="empty_net" type="pnmlcore" />
        </pnml>
    """
    pnmlmodel(empty_model; kwargs...)
end

function pnmlmodel(filename::AbstractString; kwargs...)
    D()&& println("\n## pnmlmodel filename $filename")
    isempty(filename) && throw(ArgumentError("must have a non-empty file name argument"))
    pnmlmodel(EzXML.root(EzXML.readxml(filename)); kwargs...)
end

function pnmlmodel(node::XMLNode; kwargs...)
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node)
    nets = LittleDict{Symbol,Any}()
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "net"
            net = parse_net(child; kwargs...)::PnmlNet # Fully formed
            nets[pid(net)] = net
        else
            @error "<model> has unexpected child $tag"
        end
    end
    length(nets) > 0 || throw(MalformedException("<pnml> does not have any <net> elements"))
    return PnmlModel(freeze(nets), namespace)
end

"""
    plugins!(dict::AbstractDict, kwargs, plugintag)

Fill `dict` if `kwargs[plugintag]` exists & has a collection of tuples.
The first tuple element being a key of `dict` and the last entry the callable.
Intermediate elements are dictionary keys for nested dictionaries.
"""
function plugins!(dict::AbstractDict, kwargs, plugintag)
    if haskey(kwargs, plugintag) &&
            !isnothing(kwargs[plugintag]) && !isempty(kwargs[plugintag])
        @info "add $(length(kwargs[plugintag])) $plugintag plugin(s)" #kwargs[plugintag] dict
        for plugin in kwargs[plugintag]
            #! todo sanity check labelparser
            @show plugin #! bring-up
            if length(plugin) >= 2
                push!(dict, recurse_plugin(plugin, 1, length(plugin)))
            else
                error("plugin $plugin size wrong: $(length(plugin) )")
           end
        end
    end
end #= function plugins! =#

function recurse_plugin(plugin, i, n)
    if i < n - 1
        return plugin[i] => LittleDict(plugin[i+1] => recurse_plugin(plugin, i+1, n))
    else
        return plugin[i] => plugin[n]
    end
end

"""
    parse_net(node::XMLNode[; options...]) -> PnmlNet

[`PnmlNet`](@ref) created from an `<net>` `XMLNode`.

# Options
 - pntd_override::Maybe{AbstractPnmlType}
 - lp: optional label parser plugins, a collection of (Symbol, callable) tuples
 - tp: optional toolspecific parser plugins, a collection of(String, String, callable) tuples
 - ef: optional enabled filter plugins, a collection of (Symbol, callable) tuples
"""
function parse_net(net_node::XMLNode; pntd_override::Maybe{String} = nothing, kwargs...)
    idregistry = IDRegistry() # empty
    netid = register_idof!(idregistry, net_node)

    # Parse the pnml net type attribute. Not the place sort `<type>` label.
    typestr = attribute(net_node, "type")
    if !isnothing(pntd_override)
        # Override of the Petri Net Type Definition (PNTD) value for fun & games.
        @info "net $netid pntd set to $pntd_override, overrides $typestr"
        typestr = pntd_override
    end
    pntd = pnmltype(typestr)
    D()&& println("\n## parse_net ", netid, " of type ", pntd)

    #----------------------------------------------------------------
    # Create net with empty data containers to be filled during parsing.
    # We already used `idregistry` and `pagedict` needs to be type stable.
    # `ddict` is a RefValue so that the types of values in its dictonaries
    # can be determined at runtime.
    #-------------------------------------------------------------------------------------
    net = PnmlNet(; type=pntd, id=netid, idregistry,
                    pagedict = OrderedDict{Symbol, Page{PnmlNet{typeof(pntd)}}}(), #! abstract Page
                    )
    net.ddict[] = DeclDict(net) # Create with empty dictionaries of net specific values.

    #^ Label Parsers
    fill_builtin_labelparsers!(net.labelparser)
    @assert !isempty(net.labelparser) "There are expected to be built-in label parsers."
    plugins!(net.labelparser, kwargs, :lp)

    #^ Tool Parsers
    fill_builtin_toolparsers!(net.toolparser)
    plugins!(net.toolparser, kwargs, :tp)

    #^ Sorts
    fill_builtin_sorts!(net)
    # TODO? net.sortparser plugins?

    #^ Enabled Filters
    fill_builtin_enabled_filters!(net.enabled_filters)
    plugins!(net.enabled_filters, kwargs, :ef)

    # Parse *ALL* Declarations here. Including any Declarations attached to Pages.
    # Place any/all declarations in single net-level DeclDict.
    # It is like we are flattening only the declarations.
    # Only the first <declaration> label's text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the standard).
    net.declaration = parse_declarations!(net, net_node)::Declaration

    let n = firstchild(net_node, "name")
        if !isnothing(n)
            net.namelabel = net.labelparser[:name](n, net; parentid=netid)::Name
        end
    end

    # Collect all the toolspecinfos at net level for use in later parsing.
    find_toolinfos!(net.toolspecinfos, net_node, net)
    validate_toolinfos(net.toolspecinfos)

    #--------------------------------------------------------------------
    # Fill `net`
    #--------------------------------------------------------------------
    for child in EzXML.eachelement(net_node)
        tag = EzXML.nodename(child)
        if tag == "page"
            # There is always at least one page. A forest of multiple page trees is allowd.
            parse_page!(net, net.page_idset, child)
        elseif tag in ["declaration", "name", "toolspecific"]
            # println("NOOP: already parsed ", tag)
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: <graphics>"
        else
            unexpected_label!(net.extralabels, child, Symbol(tag), net; parentid=netid)
        end
    end
    verify(net, false) # CONFIG.verbose)

    #~ --------------------------------------------------------------
    #~ At this point the XML has been processed into PnmlExpr terms.
    #~ --------------------------------------------------------------

    #^ Ground terms used to set initial markings can be rewritten and evaluated here.
    #? Rewrite inscription and condition terms with variable substitution.
    #? 0-arity operator means empty variable substitution, i.e. constant.
    #TODO create API for using ToolInfo in expressions

    # Create "color functions" that process variables using TermInterface expressions.
    # Pre-caculate as much as is practical.

    #~ Evaluate expressions to create a mutable vector of markings.
    #^ Marking vector is used in enabling and firing rules.
    #m₀ = PNML.PNet.initial_markings(net)
    #PNML.enabledXXX(net, m₀) # enabling rule?

    return net
end #= function parse_net =#


"""
    parse_page!(net, page_idset, page_node) -> Nothing

Call `_parse_page!` to create a page with its own `netsets`.
Add created page to parent's `page_idset` and `pagedict(net)`.
"""
function parse_page!(net::PnmlNet, page_idset, page_node::XMLNode)
    check_nodename(page_node, "page")
    pageid = register_idof!(registry_of(net), page_node)
    push!(page_idset, pageid) # Record id before decending.
    pg = __parse_page!(net, page_node, pageid)
    @assert pageid === pid(pg)
    pagedict(net)[pageid] = pg
    return nothing
end

"""
    __parse_page!(net, page_node, pntd, pageid) -> Page

Return `Page`. `pageid` already parsed from `page_node`.
"""
function __parse_page!(net::PnmlNet{T}, page_node::XMLNode, pageid::Symbol) where {T<:APNTD}
    D()&& println("## parse_page ", pageid)
    #---------------------------------------------------------
    # Create "empty" page. Will have `toolinfos` parsed.
    #---------------------------------------------------------
    page = Page{typeof(net)}(; net, id = pageid,
                netsets = PnmlNetKeys(),
                toolspecinfos = find_toolinfos!(nothing, page_node, net)::Maybe{Vector{ToolInfo}})

    validate_toolinfos(toolinfos(page))

    #---------------------------------------------------------
    # Fill page with graph nodes & arcs.
    #---------------------------------------------------------
    for child in EzXML.eachelement(page_node)
        nname = Symbol(EzXML.nodename(child))
        if nname == :place
            parse_place!(netsets(page), netdata(net), child, net)
        elseif nname == :referencePlace
            parse_refPlace!(netsets(page), netdata(net), child, net)
        elseif nname == :transition
            parse_transition!(netsets(page), netdata(net), child,  net)
        elseif nname == :referenceTransition
            parse_refTransition!(netsets(page), netdata(net), child,  net)
        elseif nname == :arc
            parse_arc!(netsets(page), netdata(net), child, net)
        elseif nname in [:declaration, :toolspecific]
             # NOOP already parsed
        elseif nname == :page
            #---------------------------------------------------------------------------
            # Subpage stored at net-level with key in page's id set (until flattened).
            #---------------------------------------------------------------------------
            parse_page!(net, page_idset(page), child)
        elseif nname == :name
            page.namelabel = net.labelparser[nname](child, net; parentid=pageid)
        elseif nname == :graphics
            page.graphics = parse_graphics(child, pntd(net))
        else
            unexpected_label!(page.extralabels, child, nname, net; parentid=pageid)
        end
    end #= for child in EzXML.eachelement(page_node) =#

    return page
end #= function __parse_page! =#

"""
    find_toolinfos!(toolspecinfos, node, pntd, net) -> toolinfos

Calls `add_toolinfo(toolspecinfos, info_node, net)` for each info found.
See [`Labels.get_toolinfos`](@ref) for accessing `ToolInfo`s.
"""
function find_toolinfos!(toolspecinfos::Maybe{Vector{ToolInfo}}, node, net)
    for info in allchildren(node, "toolspecific")
        toolspecinfos = add_toolinfo(toolspecinfos, info, net) # nets and pages
    end
    return toolspecinfos
end
