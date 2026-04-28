"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(tag::Symbol, node::XMLNode)
    return AnyElement(tag, xmldict(node)::Union{XmlDictType, String, SubString{String}})
end

"""
    xmldict(node::XMLNode) -> Union{XmlDictType, String, SubString{String}}

Return well formed XML as parsed by `XMLDict.xml_dict`.
Symbols for attribute key, strings for element/child keys and strings for value of leaf.

See: [`anyelement`](@ref),
[`AnyElement`](@ref),[`PnmlLabel`](@ref)
"""
function xmldict(node::XMLNode)
    xd = XMLDict.xml_dict(node, XmlDictType; strip_text=true)
    return xd #!::Union{XmlDictType, String, SubString{String}}
    # empty dictionarys are a valid thing.
end

#= function xml_dict(x::EzXML.Node, dict_type::Type=OrderedDict; strip_text=false)
    for a in eachattribute(x)
        r[Symbol(nodename(a))] = nodecontent(a)
    end
    # Check for non-empty text nodes under this element...
    # Check for non-contiguous repetition of sub-element tags...

    # The empty-string key holds a vector of sub-elements.
    # This is necessary when grouping sub-elements would alter ordering...

    for c in eachnode(x) #! is roughly

        if iselement(c)
           # Get name and sub-dict for sub-element...
            n = nodename(c)
            v = xml_dict(c, dict_type; strip_text=strip_text)

            if haskey(r, "") #! Put sub-dicts in a vector, they may be non-continuous
                # If this is a text element, embed sub-dict in text vector...
                # "The <b>bold</b> tag" == ["The", Dict("b" => "bold"), "tag"]
                push!(r[""], dict_type(n => v))
            elseif haskey(r, n) #! already seen key,
                # Collect sub-elements with same tag into a vector...
                # "<item>foo</item><item>bar</item>" == "item" => ["foo", "bar"]
                a = isa(r[n], Array) ? r[n] : Any[r[n]] #! create Vector for 1st repeat.
                push!(a, v) #! append to vector
                r[n] = a
            else
                r[n] = v #! first time `n` seen.
            end #! first time,
        elseif is_text(c) && haskey(r, "")
            push!(r[""], nodecontent(c))
        end
    end
    # Collapse leaf-node vectors containing only text...
            # If "r" contains no other keys, collapse the "" key...
            if length(r) == 1
                r = r[""]
            end

    return r

=#
