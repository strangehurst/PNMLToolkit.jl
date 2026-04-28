Base.@kwdef struct PnmlConfig
    indent_width::Int           = 4
    text_optional::Bool         = true

    #app_env::String             = DEV
    verbose::Bool               = false
    base_path::String           = "PNML"
    log_path::String            = "log"
    log_to_file::Bool           = false
    log_requests::Bool          = true
    log_date_format::String     = "yyyy-mm-dd HH:MM:SS"

    warn_on_fixup::Bool         = false
    warn_on_namespace::Bool     = true
    warn_on_unclaimed::Bool     = false
    warn_on_unimplemented::Bool = false
end

"""
    PNML.CONFIG

Configuration with default values that can be overidden by a LocalPreferences.toml.

# Options
  - `indent_width::Int`: Indention of nested lines.
  - `text_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
  - `warn_on_fixup::Bool`: When an missing value is replaced by a default value, issue a warning.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules & do not have an xml namespace.
  - `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined. While allowed, there will be code required to do anything useful with the label.
  - `warn_on_unimplemented::Bool`: Issue warning to highlight something unimplemented. Expect high volume of messages.
  - `verbose::Bool`: Print information as runs.

See `PnmlConfig` for default values.
"""
global CONFIG::PnmlConfig = PnmlConfig()
