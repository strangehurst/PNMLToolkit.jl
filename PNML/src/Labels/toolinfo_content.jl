"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content. Will be attached to a `ToolInfo` that
also holds the tool name and version.
Combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics
    positions::Vector{Coordinate}
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics() = TokenGraphics(Coordinate[])

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "TokenGraphics(", tg.positions, ")")
end

###############################################################################
"""
$(TYPEDEF)
$(TYPEDFIELDS)

TestTool is <toolspecific> content. Will be attached to a `ToolInfo`.
Wraps an [`AnyElement`](@ref).
"""
struct TestTool{T}
    info::AnyElement{T}
end

function Base.show(io::IO, u::TestTool)
    print(io, "TestTool(", u.info, ")")
end

###############################################################################

struct NupnUnit
    id::Symbol # unit identifier
    places::Vector{Symbol}
    subunits::Vector{Symbol}
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

NupnTool is <toolspecific> content. Will be attached to a `ToolInfo`.
Wraps an [`AnyElement`](@ref).
"""
@kwdef struct NupnTool
    nplaces::Int # We provide as `nplaces(net)`.
    ntransitions::Int # We provide as `ntransitions`
    narcs::Int # We provide as `narcs`
    nunits::Int
    root::Symbol # unit identifier
    safe::Bool
    units::Vector{NupnUnit}
end

# function Base.show(io::IO, u::NupnTool)
#     print(io, "NupnTool(", u.info, ")")
# end
