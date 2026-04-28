# PNML
Still alpha. Every changes is probably breaking. Things change radically all the time.

[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR) in Julia.

Features that have not been started:
  - Write pnml file
  - Update pnml model
  - Create pnml model

Features that are not complete:
  - HLPNG - many-sorted algebras are complex. Work in process.
  - pntd specialize
  - toolspecific usage
  - API definition

Features that work:
  - stochastic petri nets (examples/lotka-volterra.jl) via rate labels for transitions.
  - pnml core: can read & print Model Checking Contest (MCC) models, abet with some warnings & exceptions due to incomplete implementation.
  - MetaGraphNext.SimpleDiGraphFromIterator used to create a graph with labels.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![codecov](https://codecov.io/gh/strangehurst/PNML.jl/graph/badge.svg?token=7uARCtHrK9)](https://codecov.io/gh/strangehurst/PNML.jl)
