"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef mutable struct Arc{N <: APN, T <: PnmlExpr} <: AbstractPnmlNode #Object
    id::Symbol
    source::RefValue{Symbol} # IDREF
    target::RefValue{Symbol} # IDREF
    inscription::Inscription{N,T} #! expression label
    type_label::ArcType
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    net::N
end

"""
    inscription(arc::Arc) -> Inscription

Access inscription label of arc.
"""
function inscription(arc::Arc)
    arc.inscription # label
end

#TODO ====================================================================
#TODO Move extensions/enhancements to ISO 150909-1:2004 (1st ED.) to own file.

"""
    type_label(arc::Arc) -> ArcType

Access arctype label of arc.
"""
function type_label(arc::Arc)
    arc.type_label # label
end

is_normal(arc::Arc)    = is_normal(type_label(arc))
is_inhibitor(arc::Arc) = is_inhibitor(type_label(arc))
is_read(arc::Arc)      = is_read(type_label(arc))
is_reset(arc::Arc)     = is_reset(type_label(arc))

is_normal(label::ArcType)    = is_normal(arctype(label))
is_inhibitor(label::ArcType) = is_inhibitor(arctype(label))
is_read(label::ArcType)      = is_read(arctype(label))
is_reset(label::ArcType)     = is_reset(arctype(label))

is_normal(e::ArcTypeEnum.T)    = e == ArcTypeEnum.Normal
is_inhibitor(e::ArcTypeEnum.T) = e == ArcTypeEnum.Inhibitor
is_read(e::ArcTypeEnum.T)      = e == ArcTypeEnum.Read
is_reset(e::ArcTypeEnum.T)     = e == ArcTypeEnum.Reset

source(arc::Arc)::Symbol = arc.source[]
target(arc::Arc)::Symbol = arc.target[]

function Base.show(io::IO, arc::Arc)
    print(io, nameof(typeof(arc)), "(", repr(pid(arc)),
          ", ", repr(name(arc)),
          ", ", repr(source(arc)),
          ", ", repr(target(arc)),
          ", ", repr(inscription(arc)),
          ", ", repr(type_label(arc)))
    print(io, ")")
end

function verify!(errors, a::Arc, verbose::Bool , net::APN)
    verbose && println("## verify Transition $(pid(a))")
    !isregistered(registry_of(net), pid(a)) &&
        push!(errors, string("arc ", repr(pid(a)), " not registered")::String)

    # TODO verify arc

     return errors
end
