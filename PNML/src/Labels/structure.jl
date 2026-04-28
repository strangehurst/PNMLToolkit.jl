# """
# $(TYPEDEF)
# $(TYPEDFIELDS)

# High-level Annotation Labels place meaning in <structure> that is consumed by "claimed" labels.
# Is is expected to contain an abstract syntax tree (ast) for the many-sorted algebra expressed in XML.
# We implement this to allow use of <structure> tags by other PnmlTypes.

# # Extra
# There are various defined structure ast variants in pnml:
#   - Sort Type of a Place [builtin, multi, product, user]
#   - Place Marking [variable, operator]
#   - Transition Condition [variable, operator]
#   - Arc Inscription [variable, operator]
#   - Declarations [sort, variable, operator]

# These should all have dedicated parsers and objects as *claimed labels*.
# Here we provide a fallback for *unclaimed tags*.
# """
# struct Structure{T}
#     tag::Symbol
#     el::T
# end
# Structure(s::AbstractString, e; ddict) = Structure(Symbol(s), e, ddict)

# tag(s::Structure) = s.tag
# sortelements(s::Structure) = s.el # label elements
