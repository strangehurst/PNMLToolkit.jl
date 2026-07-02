```@meta
CurrentModule = PNML
```

# PNML.jl

Documentation for the GitHub [PNMLToolkit.jl](https://github.com/strangehurst/PNMLToolkit.jl) repository.
An unregistered monorepo using Pkg.jl's workspace and source mechanisms.
Which defines a Julia sub-package named `PNML` that handles an XML markup language with the
acronym [pnml](http://www.pnml.org) -- [Petri Net](https://en.wikipedia.org/wiki/Petri_net) Markup Language.

```@eval
using Markdown, Pkg, Dates, InteractiveUtils

function print_dep_version(depname)
	deps = values(Pkg.dependencies())
	version = first(d for d in deps if d.name == depname).version
	"$depname: v$version"
end

Markdown.parse("""
	These docs were generated at $(now()) on $(gethostname()) using:
		- $(print_dep_version("PNML"))
		- $(print_dep_version("PNet"))
   """)
```

```@repl
using InteractiveUtils; # hide
versioninfo()
```

There are 2 flavors currently covered by PNML meta-models:
  - integer-valued, where tokens have collective identities.
  - High-level, where tokens have individual identities using a many-sorted algebra.

The people behind PNML, and as stated in _SO/IEC 15909-2_, are of the Model Driven Software Engineering camp and have chosen Java, Eclipse and its modeling framework (EMF). Including Object Management Group UML2 models.

See [*A primer on the Petri Net Markup Language and ISO/IEC 15909-2*](https://www.pnml.org/papers/pnnl76.pdf)(pdf) for more details. The rest of this document will hopefully make more sense if you are familiar with the primer's contents. Use the RelaxNG Schema as definitive like the 'primer' counsels.

See [Extending PNML Scope: a Framework to Combine Petri Nets Types](https://www.pnml.org/papers/topnoc-2012.pdf) for concepts relevant to *ISO/IEC 15909-3*.

## Interoperability

Petri Net Type Definition schema files (pntd) are defined using RELAX-NG XML Schema files (rng).
Petri Net Markup Language files (pnml) are intended to be validated against a pntd schema.

For interchange of pnml between tools it should be enough to support the same pntd schema.
We will act as if that is true.

Note that ISO released part 3 of the PNML standard covering extensions and structuring mechanisms in 2021. And some http://www.pnml.org files address these extensions.
Including [Extending PNML Scope: a Framework to Combine Petri Nets Types](https://www.pnml.org/papers/topnoc-2012.pdf).

It is possible to use a non-standard pntd and some exist in the wild.
And more will be standardized, either formally or informally.
Non-standard mostly means that the interchangibility is restricted.

Some go so far as to use non-standard URIs for pntds. We have not yet made that decision.
Note that the RelaxNG files are imbedded in ISO/IEC 15909-2 so can be easily duplicated.

Since validation is not a goal of PNML.jl the uri is treated as a string.
So non-standard pntds can be used for the URI of an XML `net` tag's `type` attribute.
Notably `pnmlcore` and `nonstandard` are mapped to [`PnmlCoreNet`](@ref).

`PnmlCoreNet` is the minimum level of meaning that any pnml file can hold.

Further parsing of labels is specialized upon subtypes of `PNet.AbstractPetriNet`.
See [Traits](@ref) for more details.

If you want interchangability of pnml models, you will have to stick to
the standard pnml pntds. The High Level Petri Net, even when restricted to
_symmetricnet.pntd_, is very expressive. Even the base _pnmlcore.pntd_ is useful.

## Why no Schema Verification

Within PNML.jl no schema-level validation is done.

Note that, depending on context, 'PNML' may refer to either
the markup language or the Julia code in the following.

In is allowed by the PNML standard to omit validation with the presumption that
some specialized, external tool can be applied, thus allowing the file format to be
used for inter-tool communication with lower overhead in each tool.

Also omiting pntd validation allows "duck typing" of Petri Nets built upon the
PNML intermediate representration.

Of some note it that PNML.jl extends PNML. These, non-standard pntd do not
(yet) have a schema written. See [`ContinuousNet`](@ref).
