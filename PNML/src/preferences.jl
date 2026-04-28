# Preference scheme inspired by Tim Holy's Cthuhlu.jl

"""
    save_config!(config::PnmlConfig=CONFIG)

Save a configuration to your `LocalPreferences.toml` file using Preferences.jl.
The saved preferences will be automatically loaded next time you do `using PNML`

## Examples
```julia
julia> using PNML

julia> PNML.CONFIG.verbose = true;

julia> PNML.CONFIG.warn_on_unclaimed = true;     # Customize some defaults

julia> PNML.save_config!(PNML.CONFIG); # Will be automatically read next time you `using PNML`
```
"""
function save_config!(config::PnmlConfig=CONFIG; kwargs...)
    set_preferences!(PNML,
        "indent_width" => config.indent_width,
        "text_optional" => config.text_optional,
        "verbose" => config.verbose,
        "warn_on_namespace" => config.warn_on_namespace,
        "warn_on_fixup" => config.warn_on_fixup,
        "warn_on_unclaimed" => config.warn_on_unclaimed,
        "warn_on_unimplemented" => config.warn_on_unimplemented,

        "base_path" => config.base_path,
        "log_path" => config.log_path,
        "log_to_file" => config.log_to_file,
        "log_date_format" => config.log_date_format; kwargs...
        )
end

function read_config!()
    global CONFIG
    @reset CONFIG.indent_width = load_preference(PNML, "indent_width", CONFIG.indent_width)
    @reset CONFIG.text_optional = load_preference(PNML, "text_optional", CONFIG.text_optional)
    @reset CONFIG.verbose = load_preference(PNML, "verbose", CONFIG.verbose)
    @reset CONFIG.warn_on_namespace = load_preference(PNML, "warn_on_namespace", CONFIG.warn_on_namespace)
    @reset CONFIG.warn_on_fixup = load_preference(PNML, "warn_on_fixup", CONFIG.warn_on_fixup)
    @reset CONFIG.warn_on_unclaimed = load_preference(PNML, "warn_on_unclaimed", CONFIG.warn_on_unclaimed)
    @reset CONFIG.warn_on_unimplemented = load_preference(PNML, "warn_on_unimplemented", CONFIG.warn_on_unimplemented)

    @reset CONFIG.base_path = load_preference(PNML, "base_path", CONFIG.base_path)
    @reset CONFIG.log_path = load_preference(PNML, "log_path", CONFIG.log_path)
    @reset CONFIG.log_to_file = load_preference(PNML, "log_to_file", CONFIG.log_to_file)
    @reset CONFIG.log_date_format = load_preference(PNML, "log_date_format", CONFIG.log_date_format)
end

function Base.show(io::IO, config::PnmlConfig)
    println(io, "indent_width          = ", config.indent_width)
    println(io, "text_optional         = ", config.text_optional)
    println(io, "verbose               = ", config.verbose)
    println(io, "warn_on_namespace     = ", config.warn_on_namespace)
    println(io, "warn_on_fixup         = ", config.warn_on_fixup)
    println(io, "warn_on_unclaimed     = ", config.warn_on_unclaimed)
    println(io, "warn_on_unimplemented = ", config.warn_on_unimplemented)
    println(io, "base_path             = ", config.base_path)
    println(io, "log_path              = ", config.log_path)
    println(io, "log_to_file           = ", config.log_to_file)
    println(io, "log_date_format       = ", config.log_date_format)
end

"""
    set_config(config::PnmlConfig = CONFIG; parameters...)
    set_config(config::PnmlConfig, parameters::NamedTuple)

Create a new `PnmlConfig` from the parameters provided as keyword arguments,
with all other parameters identical to those of `config`.
"""
function set_config end

set_config(config::PnmlConfig = CONFIG; parameters...) = set_config(config, NamedTuple(parameters))
set_config(config::PnmlConfig, parameters::NamedTuple) = setproperties(config, parameters)

"""
    set_config!(; kwargs...)

Create a new `PnmlConfig` with [`set_config`](@ref), then update the binding `PNML.CONFIG`
to now refer to that object.
"""
function set_config!(; kwargs...)
    global CONFIG = set_config(CONFIG; kwargs...)
end
