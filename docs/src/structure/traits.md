```@meta
CurrentModule = PNML
```

```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypes.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
```

# Traits

Some of the traits used are based on the pntd.
Each supported pntd has a singleton subtype of AbstractPNTD.

3 branches of pntd based on number system
  - _core_ uses integers
  - _high-level_ uses terms of many-sorted algebra
  - _continuous/hybrid_ uses floating point

Default place markings and arc inscriptions are different for the three.

# is_discrete
```@example types
list_type(PNML.is_discrete)
```

# is_continuous
```@example types
list_type(PNML.is_continuous)
```

# is_highlevel
```@example types
list_type(PNML.is_highlevel)
```
