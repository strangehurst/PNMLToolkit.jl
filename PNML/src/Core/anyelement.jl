#--------------------------------------------
# AnyElement and XmlDictType
#--------------------------------------------

"Dictionary passed to `XMLDict.xml_dict` as `dict_type`. See `xmldict`."
const XmlDictType = LittleDict{Union{Symbol,String}, Any} #Union{XmlDictType, String, SubString{String}}}

tag(d::XmlDictType) = first(keys(d)) # String or Symbol

"""
    _attribute(xd::AbstractDict, key::Symbol) -> AbstractString

XMLDict uses symbols as dictionary keys for XML attributes. Value returned is a string.
"""
function _attribute(@nospecialize(xd::AbstractDict), key::Symbol)
    x = get(xd, key, nothing)
    isnothing(x) && throw(ArgumentError("missing $key value"))
    isa(x, AbstractString) || throw(ArgumentError("expected AbstractString got $x"))
    return x
end

#-------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold AbstractDict holding zero or more well-formed XML elments.

Creates a tree where the root is `tag`,
leaf node values are `Union{String, SubString{String}}`, and
interior nodes values are `Union{XmlDictType, Vector{XmlDictType}}`

See [`XmlDictType`](@ref).
"""
@struct_hash_equal struct AnyElement{T}
    # Tag of enclosing node (or any symbol-owning thing).
    tag::Symbol
    # LittleDict{Union{Symbol,String}, Any}  returned by `xmldict`.
    elements::T
end

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements::LittleDict # label elements

function Base.show(io::IO, ae::AnyElement)
    print(io, "AnyElement(", repr(tag(ae)), ", ")
    print(inc_indent(io), elements(ae)) # what XMLDict produced
    print(io, ")")
    return nothing
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x)

Internal helper for things that contain `XmlDictType`.
"""
function dict_show end

# Called by show AnyElement
function dict_show(io::IO, d::XmlDictType)
    iio = inc_indent(io)
    for (i, kv) in enumerate(pairs(d))
        i > 1 && print(iio, indent(iio))
        print(iio, "d[$(repr(kv.first))] = ")
        dict_show(iio, kv.second)
        length(keys(d)) > 1 && i < length(keys(d)) && println(io)
    end
end

function dict_show(io::IO, d::Vector)
    iio = inc_indent(io)
    print(iio, "[")
    for (i,el) in enumerate(d)
        dict_show(iio, el)
        length(keys(d)) > 1 && i < length(keys(d)) && print(iio, ", ")
    end
    print(iio, "]")
end

dict_show(io::IO, s::SubString{String}) = show(io, s)
dict_show(io::IO, s::AbstractString)    = show(io, s)
# dict_show(io::IO, p::Pair)   = show(io, p)
# dict_show(io::IO, p::Number) = show(io, p)
# dict_show(io::IO, p::Nothing) = print(io, repr(p))

function Base.show(io::IO, ::MIME"text/plain", d::XmlDictType)
    show(io, d)
end

function Base.show(io::IO, d::XmlDictType)
    dict_show(io, d)
end
