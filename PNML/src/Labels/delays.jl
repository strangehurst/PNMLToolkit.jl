# Split from rates.jl by JDH 2025-11-10
# PnmlLabel version
# See [Tina .pnml formt](/tina-3.9.0/doc/man/mann/formats.n)
#> Tools tina, struct and plan accept BasicPNML and TpnPNML natively.
# Is non-standard pnml. The pntd and rng files are not reachable.
# Tina.tedd was part of 2025 MCC.

# ISO 15909-1 concept 30: time Petri net
# TODO clocks for TPN

"""
$(TYPEDSIGNATURES)

Return transition delay label value as interval tuple: ("closure-string", left, right)
Missing delay labels default to ("closed", 0.0, 0.0) a.k.a. zero.

All net types may have a delay. Expected label content copied from MathML.
Only non-negative. ℝ⁺
static transition #TODO define term
Supports
  - ("closed-open", 0.0, ∞)  -> [0.0, ∞)
  - ("open-closed", 2.0, 6.0 -> (2.0, 6.0]
  - ("open", 2.0, 6.0)       -> (2.0, 6.0)
  - ("closed", 2.0, 6.0)     -> [2.0, 6.0]
"""
function delay_value(t;
            tag::Symbol = :delay,
            valtype::Type{<:Number} = Float64,
            content_parser = delay_content_parser,
            default_value = tuple("closed", 0.0, 0.0))
    label = get_label(t, tag)
    d = if isnothing(label)
        default_value
    else
        content_parser(label, valtype)::Tuple
    end
    return d
end

"""
    delay_content_parser(label, value_type) -> Tuple

See [`delay_value`](@ref)
"""
function delay_content_parser(label, value_type)
    @show (tag, interval) = first(elements(label))
    tag == "interval" || error("expected 'interval', found '$(repr(tag))'")
    D()&& @show value_type
    closure = PNML._attribute(interval, :closure)
    D()&& @show closure
    # Expect at least one cn number.
    n = if haskey(interval, "cn")
        let cn = @inbounds interval["cn"]
            (isnothing(cn) || isempty(cn)) &&
                throw(ArgumentError("<interval> <cn> element is $(repr(cn))"))
            if cn isa Vector
                value_type[number_value(value_type, x) for x in cn]
            else
                value_type[number_value(value_type, cn)]
            end
        end
    else
        throw(ArgumentError(string("<interval> missing any <cn> element")))
    end
    #D()&& @show n

    i = if haskey(interval, "ci") # At most one ci named constant.
        let ci = @inbounds interval["ci"]
            (isnothing(ci) || isempty(ci)) &&
                throw(ArgumentError("<interval> <ci> element is $(repr(ci))"))
            if ci isa Vector
                length(ci) > 1 &&
                    throw(ArgumentError("<interval> has too many <ci> elements: $ci"))
                value_type[_ci(x) for x in ci]
            else
                value_type[_ci(ci)]
            end
        end
    else
        length(n) == 1 && throw(ArgumentError("<interval> <ci> element missing."))
    end
    #D()&& @show i

    a = n[1]
    b = length(n) > 1 ? n[2] : i[1]
    tup = tuple(closure, a, b)
    a <= b || error("invalid interval $(repr(tup))")
    return tup
end

"Map MathML constant string `i` to a Number. Supported: `infin, infty`."
function _ci(i)
    if i == "infin" || i == "infty"
        return Base.Inf
    else
        error("may only contain infin|infty, found: $i")
    end
end
