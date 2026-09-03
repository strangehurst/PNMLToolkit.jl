# Firing Rule

fire2(C, net::AbstractPnmlNet, marking) = fire(C, enabled(net, marking), marking)
#fire2(C, net::PnmlNet{PT_HLPNG}, marking) = fire(C, enabled(net, marking), marking)
function fire2(C, net::PnmlNet{HighLevelPNML}, marking)
    pntdsym(net) === :pt_hlpng ||
        println("firing $(pntd_of(net)) not implemented here, good luck")
    fire(C, enabled(net, marking), marking)
end

"""
    fire(incidence, enabled_vector, marking) -> ArbitraryOperator

Return the marking vector after firing transition: marking + incidence * enabled_vector

`marking` values added to product of `incidence'` matrix and firing `enabled_vector`.
"""
function fire(incidence, enabled_vector, m₀)
    #println("fire $incidence $enabled $m₀ ")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so fail here with incorrect marking!
    muladd(permutedims(incidence), enabled_vector, m₀) # old names, new values
end
