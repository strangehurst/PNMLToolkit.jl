#push!(LOAD_PATH, "../src/")
using Documenter, Pkg
#using DocumenterInterLinks
using DocumenterPlantUML
using PNML

the_repo() =  if isempty(get(ENV, "DOCUMENTER_KEY", ""))
    "github.com/strangehurst/PNML.jl"
else
    "/home/jeff/Jules/PNML/PNML"
end

DocMeta.setdocmeta!(PNML, :DocTestSetup, :(using PNML); recursive=true)

mathengine = MathJax3(Dict(:loader => Dict("load" => ["[tex]/require", "[tex]/mathtools"]),
    :tex => Dict("inlineMath" => [["\$", "\$"], ["\\(", "\\)"]],
        "packages" => [
            "base",
            "ams",
            "autoload",
            "mathtools",
            "require"
        ])))

pages=[
    "Petri Net Markup Language" => "index.md",
    "Status"                    => "status.md",
    "References"                => "references.md",
    "Structure" => [
        "Intermediate Representation" => "structure/layers.md",
        "Petri Net Type Definition" => "structure/pntd.md",
        "High Level Concepts"       => "structure/high_level.md",
        "Labels"                    => "structure/labels.md",
        "Traits"                    => "structure/traits.md",
        "Type Hierarchies"          => "structure/type_hierarchies.md",
        "Interfaces"                => "structure/interface.md",
        "Math"                      => "structure/mathematics.md",
        "Default Values"            => "structure/defaults.md",
        "Parser"                    => "structure/parser.md",
        "Enabling & Firing Rules"   => "structure/enabling_firing.md",
    ],
    #"Examples"                  => "examples.md",
    "Docstrings"                => "library.md",
    #"acknowledgments.md",
]
#todo include("pages.jl")

#links = Interlinks("PNML" => joinpath(@__DIR__, "inventories", "Julia.toml"))

################################################################################
# Building HTML documentation with Documenter
################################################################################

makedocs(sitename="PNML.jl",
         authors = "Jeff Hurst",
         modules = [PNML],
         clean = true,
         doctest = false, # runtests.jl also does doctest
         #repo="/home/jeff/Jules/PNML/{path}",
         #repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),
         warnonly = [:docs_block, :missing_docs, :cross_references],
         checkdocs = :all,
         # plugins = [links]
         format=Documenter.HTML(;
                                #edit_link=nothing,
                                # CI means publish documentation on GitHub.
                                prettyurls = (get(ENV, "CI", nothing) == "true"),
                                canonical = "https://strangehurst.github.io/PNMLToolkit.jl",
                                size_threshold_ignore = ["library.md"],
                                mathengine,
                                inventory_version = "",
                                ),
         pages=pages,
         )

################################################################################
# Deploying documentation
################################################################################

if !isempty(get(ENV, "DOCUMENTER_KEY", ""))
    deploydocs(;
            # repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),
            repo = "github.com/strangehurst/PNMLToolkit.jl",
               devbranch = "main",
               push_preview = false,
               )
end
