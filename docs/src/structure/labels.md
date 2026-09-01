#
```@meta
CurrentModule = PNML
```

# Labels

## Diagrams

```plantuml
skinparam componentStyle rectangle
scale max 1024*1024

title Input

cloud "pnml.com" {
    database "RelaxNG Schema" $schema
    file PNTD
}

file "Input.pnml"

component Parser #Yellow {
    [EzXML]
    [XMLDict]
}

component Core {
    [Sort]
    [Term]
    [Declaration]
    [Lable]
    [Node]
    [Expression]
}
component Storage {
    component [DeclDicts] {
        component variabledecls
        component namedsorts
        component arbitrarysorts
        component partitionsorts
        component namedoperators
        component arbitraryoperators
        component partitionops
        component feconstants
        component usersorts
        component useroperators
    }
    component [NetKeys] {
        component page_set
        component place_set
        component transition_set
        component arc_set
        component reftransition_set
        component refplace_set
    }
    component [NetData] {
        component place_dict
        component transition_dict
        component arc_dict
        component refplace_dict
        component reftransition_dict
    }
}

component PetriNet {
    [PnmlNet]
}
"Input.pnml" -- PNTD : uri
"RelaxNG Schema" -- PNTD

Input.pnml -- Parser : xml
Parser -- Core
Core -- Storage
PetriNet -- Storage
PetriNet -- Core
```

## PNTD Maps

Defaut PNTD to Symbol map (URI string to pntd symbol):
```@example
using PNML; foreach(println, sort(collect(pairs(PNML.PnmlTypes.pntd_map)))) #hide
```
```@docs; canonical=false
PNML.PnmlTypes.pntd_map
```

PnmlType map (pntd symbol to singleton):
```@example
using PNML; foreach(println, pairs(PNML.PnmlTypes.pnmltype_map)) #hide
```
```@docs; canonical=false
PNML.PnmlTypes.pnmltype_map
```


## Handling Labels

The implementation of Labels supports _annotation_ and _attribute_ format labels.

### Annotation Labels

_annotation_ format labels are expected to have either a <text> element,
a <structure> element or both. Often the <text> is a human-readable representation
of of the <structure> element. `Graphics` and `ToolInfo` elements may be present.

For `PTNet` (and `pnmlcore`) only the `Name` label with a <text> element
(and no <structure> element) is defined by the standard.

Labels defined in High-Level pntds, specifically 'Symmetric Nets',
"require" all meaning to reside in the <structure>.

### Attribute Labels

_attribute_ format labels are present in the UML model of pnml.
They differ from _annotation_ by omitting the `Graphics` element,
but retain the `ToolInfo` element. Unless an optimization is identified,
both _attribute_ and _annotation_ will share the same implementation.

A standard-conforming pnml model would not have any `Graphics` element
so that field would be `nothing`.
