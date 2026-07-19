"""
    metagraph(net::PnmlNet) -> MetaGraphsNext.MetaGraph

Create a graph.
Note that when `is_collective_token` is true the graph `weight_function` becomes complex.
"""
function metagraph(net::PnmlNet{P})where {P <: AbstractPNTD}
    #! println("\nmetagraph $(pntd_of(net)) $(pid(net))")

    if !(narcs(net) > 0 && nplaces(net) > 0 && ntransitions(net) > 0)
        msg = string("Attempted to create a `MetaGraph` from an incomplete $(pntd_of(net)) graph: ",
                  " net id = ", pid(net),
                  " narcs = ", narcs(net),
                  " nplaces = ", nplaces(net),
                  " ntransitions = ", ntransitions(net))
        throw(ArgumentError(msg))
    end

    # map pnml id symbol to vertex code.
    vcode  = vertex_codes(net) # inverse is vertex_labels(net)
    vlabel = vertex_labels(net)
    @assert length(vlabel) == length(vcode)

    # Create a directed graph from every arc in the petri net graph.
    graph = SimpleDiGraphFromIterator(Edge(vcode[PNML.source(a)] => vcode[PNML.target(a)]) for a in PNML.arcs(net))
    @assert length(vcode) == Graphs.nv(graph)

    # Map place/pransition pid to (vertex code, label).
    vdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    vertex_data!(vdata, net, vcode)
    @assert length(vdata) == Graphs.nv(graph)

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edge_data = Dict((PNML.source(a), PNML.target(a)) => a for a in PNML.arcs(net))
    @assert length(edge_data) == Graphs.ne(graph)

    #todo weight function for MetaGraph
    weight_function, default_weight =
    if is_collective_token(pntd_of(net))
        # No variable substitutions here.
        tuple(a -> inscription(a)(NamedTuple()),
              PNML.Parser.default(PNML.Inscription, net))
    else
        #!@error "graph edge weight function of multiset in $(pntd_of(net)) $(pid(net))"
        tuple(a -> 1, 1)
    end

    MetaGraph(graph, vlabel, vdata,
                edge_data, # edge metadata is an `Arc`
                PNML.name(net), # graph metadata
                weight_function,
                default_weight)
end

"pnml id symbol mapped to graph vertex code integer."
function vertex_codes(n::PnmlNet)
    Dict(s=>i for (i,s) in
        enumerate(union(PNML.place_idset(n),
                        PNML.transition_idset(n))))
end

"graph vertex code integer mapped to pnml id symbol."
function vertex_labels(n::PnmlNet)
    Dict(i=>s for (i,s) in
        enumerate(union(PNML.place_idset(n),
                        PNML.transition_idset(n))))
end

"""
Fill `vdata` dictionary where keys are pnml ids,
values are tuples of vertex code, place or transition.
`vcode` is a dictionary mapping pnml ids to vertex codes.
"""
function vertex_data!(vdata::Dict{Symbol, Tuple{Int, Union{Place, Transition}}},
                     net::PnmlNet,
                     vcode::AbstractDict)
    for p::Place in PNML.places(net)
        place_id = pid(p)
        vdata[place_id] = tuple(vcode[place_id], p)
    end
    for t::Transition in PNML.transitions(net)
        trans_id = pid(t)
        vdata[trans_id] = tuple(vcode[trans_id], t)
    end
    return vdata
end
