Base.@kwdef struct PnmlConfig
    base_path::String           = "PNML"
    indent_width::Int           = 4
    log_date_format::String     = "yyyy-mm-dd HH:MM:SS"
    log_path::String            = "log"
    log_requests::Bool          = true
    log_to_file::Bool           = false
    omit_graphics::Bool         = true
    text_optional::Bool         = true
    verbose::Bool               = false
    warn_on_namespace::Bool     = true
    warn_on_unimplemented::Bool = false
end

"""
    PNML.CONFIG

Configuration with default values that can be overidden by a LocalPreferences.toml.

# Options
  - `indent_width::Int`: Indention of nested lines.
  - `omit_graphics::Bool`: Omit graphics.
  - `text_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
  - `verbose::Bool`: Print information as runs.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules & do not have an xml namespace.
  - `warn_on_unimplemented::Bool`: Issue warning to highlight something unimplemented. Expect high volume of messages.

See `PnmlConfig` for default values.
"""
global CONFIG::PnmlConfig = PnmlConfig()
