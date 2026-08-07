# SnoopCompile driver script.
# Usage:
#   cd PNML/snoopy
#   julia --startup-file="no" --project=@.
#   include("snoop_pnml.jl")
using SnoopCompileCore
invalidations = @snoop_invalidations begin
    using PNML

    tinf = @snoop_inference begin
        m = PNML.pnmlmodel(xmlnode("""<?xml version="1.0"?>
            <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                <net id="net0" type="pnmlcore">
                    <page id="page1">
                        <place id="p1"/>
                        <transition id ="t1"/>
                        <arc id="a11" source="p1" target="t1"/>
                        <arc id="a12" source="t1" target="rp1"/>
                        <referencePlace id="rp1" ref="p2"/>
                        <page id="page11">
                            <place id="p11" />
                            <page id="page111">
                                <place id="p111" />
                            </page>
                        </page>
                        <page id="page12" />
                        <page id="page13" />
                        <page id="page14" />
                    </page>
                    <page id="page2">
                       <place id="p2"/>
                        <transition id ="t2"/>
                        <arc id="a21" source="t2" target="p2"/>
                        <arc id="a22" source="t2" target="rp2"/>
                        <referencePlace id="rp2" ref="p3111"/>
                        <referenceTransition id="rt2" ref="t3"/>
                    </page>
                    <page id="page3">
                        <place id="p3"/>
                        <transition id ="t3"/>
                        <arc id="a31" source="t3" target="p4"/>
                        <place id="p31"/>
                        <transition id ="t31"/>
                        <arc id="a311" source="t31" target="p1"/>
                        <place id="p311" />
                        <place id="p3111" />
                    </page>
                </net>
            </pnml>
        """));
    end
end

using SnoopCompile, AbstractTrees, PrettyTables
@show tinf

trees = SnoopCompile.invalidation_trees(invalidations);
staletrees = precompile_blockers(trees, tinf)
thinned = filtermod(PNML, trees)
itrigs = inference_triggers(tinf; exclude_toplevel=false)

#@show first(itrigs)

@show length(trees)
@show length(staletrees)
@show length(thinned)
@show length(itrigs)
@show length(SnoopCompile.uinvalidated(invalidations)) # show total invalidations

if isempty(trees)
    println("no invalidation_trees found")
end

println("methinvs")
methinvs = trees[end];

show(methinvs) # show the most invalidating method
println()

println("root")
root = methinvs.backedges[end]

@show length(itrigs)
report_invalidations(; invalidations, n_rows=0)
#=
show(root; maxdepth=10)
println()

using ProfileView
ProfileView.view(flamegraph(tinf))

# Count number of children (number of invalidations per invalidated method)
n_invalidations = map(SnoopCompile.countchildren, trees)

import Plots
Plots.plot(
    1:length(trees),
    n_invalidations;
    markershape=:circle,
    xlabel="i-th method invalidation",
    label="Number of children per method invalidations"
)

using AbstractTrees
=#
