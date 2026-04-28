# ToolInfo is not a PNML Label.
# It can be attached to `PnmlNets`, PNML labels, `AbstractPnmlObject`s.
"""
$(TYPEDEF)
$(TYPEDFIELDS)

A <toolspecific> tag holds well formed XML that is parsed into an [`AnyElement`](@ref).
"""
@auto_hash_equals struct ToolInfo{N <: APN, T}
    toolname::String
    version::String
    info::T # content of tool specific info
    net::N
end

"Name of tool for this tool specific information element."
name(ti::ToolInfo) = ti.toolname

version(ti::ToolInfo) = ti.version

"Content of a ToolInfo."
info(ti::ToolInfo)   = ti.info

# function Base.show(io::IO, toolvector::Vector{ToolInfo})
#     print(io, "ToolInfo[")
#     io = inc_indent(io)
#     for (n, anye) in enumerate(toolvector)
#         n > 1 && print(io, indent(io))
#         show(io, anye);
#         length(toolvector) > 1 && n < length(toolvector) && println(io)
#     end
#     print(io, "]")
# end

function Base.show(io::IO, ti::ToolInfo)
    print(io, "ToolInfo(", name(ti), ", ", version(ti), ", [")
    show(io, info(ti))
    print(io, ")")
end

function verify!(errors::Vector{String}, v::Vector{T}, verbose::Bool, net::APN) where {T <: ToolInfo}
    verbose && println("## verify $(typeof(v))")
    foreach(t -> verify!(errors, t, verbose, net),  v)
    return errors
end

function verify!(errors::Vector{String}, t::ToolInfo, verbose::Bool, _net::APN)
    verbose && println("## verify $(typeof(t)) $(repr(name(t))) $(repr(version(t)))")
    isempty(name(t)) &&
        push!(errors, string("ToolInfo must have non-empty name")::String)
    isempty(version(t)) &&
        push!(errors, string("ToolInfo must have non-empty version")::String)

    info(t) isa AnyElement ||
        push!(errors, string("ToolInfo $(repr(name(t))) $(repr(version(t))) ",
                    "$(info(t)) is not a AnyElement")::String)
    return errors
end

###############################################################################

# """
# has_toolinfo(infos, toolname[, version]) -> Bool

# Does any toolinfo in iteratable collection `infos` have a matching `toolname`,
# and a matching `version` (if it is provided).
# `toolname` and `version` will be turned into `Regex`s
# to match against each item in the `infos` collection.
# """
# function has_toolinfo end

# function has_toolinfo(infos, toolname::AbstractString, version::AbstractString)
#     has_toolinfo(infos, Regex(toolname), Regex(version))
# end

# function has_toolinfo(infos, toolname::Regex, version::Regex)
#     has_toolinfo(infos, toolname, version)
# end

"""
    get_toolinfos(infos, toolname[, version]) -> Maybe{ToolInfo}

Return first toolinfo in iteratable collection `infos` having a matching toolname and version.
"""
function get_toolinfos end

"""
    get_toolinfo(infos, toolname[, version]) -> Maybe{ToolInfo}

Call `get_toolinfos`.
"""
get_toolinfo(infos, name, version) = first(get_toolinfos(infos, name, version))

function get_toolinfos(infos, name::AbstractString, version::AbstractString)
    get_toolinfos(infos, Regex(name), Regex(version))
end

function get_toolinfos(infos, name::AbstractString, versionrex::Regex)
    get_toolinfos(infos, Regex(name), versionrex)
end

"""
    get_toolinfos(infos, toolname::Regex, version::Regex) -> Iterator

`infos` may be a `ToolInfo` or collection of `ToolParser`, both have  a name and version.
Return iterator over `infos` matching toolname and version regular expressions.
"""
function get_toolinfos(info, namerex::Regex, versionrex::Regex)
    _match(info, namerex, versionrex)
end

function get_toolinfos(infos::Vector, namerex::Regex, versionrex::Regex)
    Iterators.filter(ti -> _match(ti, namerex, versionrex), infos)
end


"""
    _match(tx, namerex::Regex, versionrex::Regex) -> Bool

Return `true` if both toolname and version match. Default is any version.
Applies to ToolInfo, ToolParser, and other objects with a `name` and `version` method.
"""
function _match(tx::Union{ToolInfo,ToolParser}, namerex::Regex, versionrex::Regex = r"^.*$")
    match_name = match(namerex, name(tx))
    match_version = match(versionrex, version(tx))
    !isnothing(match_name) && !isnothing(match_version)
end


##################################################################
# Validation, Analysis, Reports, Etc.
##################################################################

"""
    validate_toolinfos(infos, dd) -> Bool

Validate each `ToolInfo` in the iterable `infos` collection.

Note that each info will contain an `AbstractDict` representing well-formed XML.
"""
function validate_toolinfos(toolinfos)
    isnothing(toolinfos) && return true
    for tool in toolinfos
        @assert tool isa ToolInfo #todo more tests than this.
    end
    return true
end
function list_toolinfos(toolinfos)
    isnothing(toolinfos) && return true
    for tool in toolinfos
        @show tool
    end
  end
