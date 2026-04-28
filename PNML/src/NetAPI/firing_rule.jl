# Firing Rule

"""
    fire(incidence, enabled, marking) -> ArbitraryOperator

Return the marking vector after firing transition: marking + incidence * enabled

`marking` values added to product of `incidence'` matrix and firing vector `enabled`.
"""
function fire(incidence, enabled, m₀)
    #println("fire")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so fail here with incorrect marking!
    muladd(permutedims(incidence), enabled, m₀) # old names, new values
end

fire2(C, net::AbstractPnmlNet, marking) = fire(C, enabled(net, marking), marking)
fire2(C, net::PnmlNet{PT_HLPNG}, marking) = fire(C, enabled(net, marking), marking)
function fire2(C, net::PnmlNet{T}, marking) where {T <: AbstractHLCore}
    println("firing $(pntd(net)) not implemented here, good luck")
    fire(C, enabled(net, marking), marking)
end
