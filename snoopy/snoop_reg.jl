# SnoopCompile
using SnoopCompileCore
invs = @snoop_invalidations using PNML;
using SnoopCompile, AbstractTrees
trees = invalidation_trees(invs);
tree = trees[1]
sig, victim = tree.mt_backedges[end];
sig
victim
print_tree(victim)
invalidated(invs)


# invalidations = @snoopr begin
#     #!using PnmlIDRegistrys

#     tinf = @snoopi_deep begin
#         @with PNML.idregistry => registry() begin
#             register_id!(idregistry[], :p)
#             register_id!(idregistry[], :p)
#             !isregistered(idregistry[], "p")
#             !isregistered(idregistry[], :p)
#         end
#     end
# end

# using SnoopCompile

# trees = SnoopCompile.invalidation_trees(invalidations);
# staletrees = precompile_blockers(trees, tinf)

# @show length(SnoopCompile.uinvalidated(invalidations)) # show total invalidations

# if !isempty(trees)
#     show(trees[end]) # show the most invalidating method

#     # Count number of children (number of invalidations per invalidated method)
#     n_invalidations = map(SnoopCompile.countchildren, trees)

#     import Plots
#     Plots.plot(
#         1:length(trees),
#         n_invalidations;
#         markershape=:circle,
#         xlabel="i-th method invalidation",
#         label="Number of children per method invalidations"
#     )
# end
