# Start with a copy of Petri.jl examples/lotka-volterra.jl.
# see #https://algebraicjulia.github.io/AlgebraicPetri.jl/dev/generated/predation/lotka-volterra/
using PNML: PNML, SimpleNet, PnmlNet, place_idset, transition_function, initial_markings
using PNML: nplaces, ntransitions, transitions, places, preset, pnmlnet, pid

#using Petri: Petri, Model, Graph, ODEProblem
using LabelledArrays
using Plots: Plots
using OrdinaryDiffEq: OrdinaryDiffEq, Tsit5

using AlgebraicPetri
using Catlab
using Catlab.CategoricalAlgebra
using Catlab.Graphs
using Catlab.Graphics

"""
PNML model for the original example below. Note that the type is "continuous"!
"""
const str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
        <page id="page0">
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
            <arc id="a1" source="rabbits"   target="birth">     <inscription><text>1</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits">   <inscription><text>2</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves">    <inscription><text>2</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death">     <inscription><text>1</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
"""


function lotka(s::AbstractString=str)
    snet = PNML.SimpleNet(s) # Use the PnmlNet
    net = pnmlnet(snet)

    # **Step 1:** Define the states and transitions of the Petri Net

    lp = collect(PNML.labeled_places(net))
    lt = collect(PNML.labeled_transitions(net))
    ct = collect(PNML.counted_transitions(net))

    state_dict(n) = Dict(s => i for (i, s) in enumerate(n))

    # Whole-grained Petri net requires all inscriptions === 1.
    p = AlgebraicPetri.LabelledReactionNet{Float64,Float64}()

    let n = lp
        @show n
        @show states = map(first, collect(n))
        @show concentrations = map(last, collect(n))
        @show state_idx = state_dict(states)

        AlgebraicPetri.add_species!(p, length(states), concentration=concentrations, sname=states)

        for (i, ((name, rate), (ins, outs))) in enumerate(lt)
            println("$i:  (($name, $rate), ($ins, $outs)))", )
            i = AlgebraicPetri.add_transition!(p, rate=rate, tname=name)

            # preset Iterators.map(x -> source(arcdict(net)[x]), tgt_arcs(net, id))
            # preset Iterators.map(arcid -> source(arcdict(net)[arcid]), tgt_arcs(net, id))

            # postset Iterators.map(x -> target(arcdict(net)[x]), src_arcs(net, id))

            AlgebraicPetri.add_inputs!(p, length(ins),
                repeat([i], length(ins)), map(x -> state_idx[x], collect(ins)))
            AlgebraicPetri.add_outputs!(p, length(outs),
                repeat([i], length(outs)), map(x -> state_idx[x], collect(outs)))
        end
    end
    #! lotka = Petri.Model(S, Δ)
    #! display(Petri.Graph(lotka))
    return p
    #display(to_graphviz(lotka(str)))
end

function stuff(lotka)
    # display_uwd(ex) = to_graphviz(ex, box_labels=:name, junction_labels=:variable, edge_attrs=Dict(:len=>".75"));
    # display_uwd(lotka)
    println("---")
    # **Step 2:** Define the parameters and transition rates
    #
    # Once a model is defined, we can define out initial parameters `u0`, a time
    # span `tspan`, and the transition rates of the interactions `β`

    u0 = PNML.labeled_places(net) #Vector(:wolves=>10.0, :rabbits=>100.0)
    tspan = (0.0,100.0)
    β = PNML.rates(net) #Vector(:birth=>0.3, :predation=>0.015, :death=>0.7);

    @show u0 tspan β

    # **Step 3:** Generate a solver and solve
    #
    # Finally we can generate a solver and solve the simulation

    # AlgebraicPetri.ODEProblem uses a AlgebraicPetri.AbstractetriNet a C-Set
    #prob = Petri.ODEProblem(lotka, u0, tspan, β) # transform using Petri.vectorfield(m)
    vf = AlgebraicPetri.vectorfield(lotka)
    @show prob = OrdinaryDiffEq.ODEProblem(vf, u0, tspan, β)
    #sol = OrdinaryDiffEq.solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)
    #plot(sol, labels=["Rabbits" "Wolves"])

    sol = OrdinaryDiffEq.solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

    display(Plots.plot(sol))
end

#^ AlgebraicPetri/jl test:
#! du = LVector(S=0.0, I=0.0, R=0.0)
#! out = vectorfield_expr(sir_lrxn)(du, concentrations(sir_lrxn), rates(sir_lrxn), 0.01)


#=
#out = vectorfield(sir_rxn)(du, concentrations(sir_rxn), rates(sir_rxn), 0.01)
valueat(f::Function, u, t) = try f(u,t) catch e f(t) end

function vectorfield(net::AbstractPnmlNet) #! MY version
    outmatrix = PNML.output_matrix(net)
    inmatrix = PNML.input_matrix(net)
    dt = outmatrix - inmatrix # incidence_matrix, but here we want input also

    # Return anonymous function f!(du, u, p, t)
    # where du is some vector indexed by place (ID?).
    (du, u, p, t) -> begin # closure over dt, inmatrix
        rates = zeros(valtype(du), ntransitions(net)) # φ in paper
        # φ = [βₜ Σ\_(s∈r(t)) uₛ for t in preset(net, transition_id)]
        # r : T → N^S is preset(net, transition_id)
        # p : S → N^T is preset(net, place_id)
        # r^-1 : S → N^T is preset(net, place_id)

        for (i, t) in enumerate(transitions(net))
            rates[i] = PNML.rate_value(t, pntd) * prod(PNML.initial_marking(p) ^ inmatrix[i, j] for (j,p) in enumerate(places(net)) if pid(p) in preset(net, pid(t)))
        end
        for j in 1:nplaces(net)
            du[j] = sum(rates[i] * dt[i, j] for i in 1:ntransitions(net); init=0.0)
        end
        du
  end
end
=#
#^ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

xxx="""
Following Baez & Pollard ([18], Definition 13),
 we associate an ODE to a Petri net by applying the law of mass action,
 which states that transitions consume inputs and produce outputs at rates proportional to
 the product of their input concentrations.

     p : S → N^T
 so that p(s) is the multiset of transitions producing the species s.
   preset(net, place_id)

     r : T → N^S
so that r(t) is the multiset of species that are inputs to the transition t.
   preset(net, transition_id)

    r^-1 : S → N^T
maps a species s to the multiset of transitions for which it is an input.
   preset(net, place_id)

Each species `s`` in the Petri net is assigned a variable uₛ in the ODE.

The transitions define the following vector field on the state space RS :

    `u̇ₛ = Σ_(t∈p(s)) φₜ - Σ_(t∈r^-1(s)) φₜ

 where φₜ := βₜ Σ_(s∈r(t)) uₛ

and βt is the rate constant associated with transition t.

These equations define the standard interpretation of Petri nets as systems of ODEs
governing chemical reaction networks.

Note that the multiset multiplicities represent the stoichiometric coefficients
in the chemical reaction interpretation of the Petri net.
"""


#= !!!
vectorfield(pn::AbstractPetriNet) = begin #^ AlgebraicPetri.jl version
  tm = TransitionMatrices(pn)
  dt = tm.output - tm.input # dt is incidence matrix
  (du, u, p, t) -> begin
    rates = zeros(valtype(du), nt(pn))
    u_m = [u[sname(pn, i)] for i in 1:ns(pn)] #? species name is ID, u is marking?
    p_m = [p[tname(pn, i)] for i in 1:nt(pn)] #? transition name is ID, p is rate label?
    for i in 1:nt(pn)
      rates[i] = valueat(p_m[i], u, t) * prod(u_m[j]^tm.input[i, j] for j in 1:ns(pn))
    end
    for j in 1:ns(pn)
and βt is the rate constant associated with transition t.

These e
      du[sname(pn, j)] = sum(rates[i] * dt[i, j] for i in 1:nt(pn); init=0.0)
    end
    du
  end
end

#!#############################################################################
sname/tname return an index if labels are not present (AlgebraicPetri)
funcindex!(list, key, f, vals...) = list[key] = f(list[key],vals...)
transitionrate(S, T, k, rate, t) = exp(reduce((x,y)->x+log(S[y] <= 0 ? 0 : S[y]),
                                       keys(first(T[k]));
                                       init=log(valueat(rate[k],S,t))))
valueat(f::Function, u, t) = try f(u,t) catch e f(t) end

# Petri.jl
function vectorfield(m::Model)
    S = m.S # PNML.place_idset(net) # [:rabbits, :wolves]
    T = m.Δ # PNML.transition_function(net)


    ϕ = Dict()
    f(du, u, rate, t) = begin
        for k in keys(u)
          ϕ[k] = #!transitionrate(u, T, k, p, t)
          exp(reduce((x,y) -> x + log(du[y] <= 0 ? 0 : du[y]), keys(first(u[k])); init=log(valueat(rate[k], du, t))))
        end
        for s in S
          du[s] = 0
        end
        for k in keys(T)
            l,r = T[k] # ins, outs
            for s in keys(l)
              #funcindex!(du, s, -, ϕ[k] * l[s])
              du[s] = -(du[s], (ϕ[k] * l[s]))
            end
            for s in keys(r)
              #funcindex!(du, s, +, ϕ[k] * r[s])
              du[s] = +(du[s], (ϕ[k] * r[s]))
            end
        end
        return du
    end
    return f
end

# AlgebraicPetri.jl

struct TransitionMatrices
  input::Matrix{Int} #
  output::Matrix{Int}
  TransitionMatrices(p::AbstractPetriNet) = begin
    input, output = zeros(Int, (nt(p), ns(p))), zeros(Int, (nt(p), ns(p)))
    for i in 1:ni(p) # arc from transition to place
      input[subpart(p, i, :it), subpart(p, i, :is)] += 1
    end
    for o in 1:no(p) # arc from place to transition
      output[subpart(p, o, :ot), subpart(p, o, :os)] += 1
    end
    new(input, output)
  end
end

=#

nothing
