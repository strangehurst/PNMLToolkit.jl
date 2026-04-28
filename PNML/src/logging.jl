using SciMLLogging: SciMLLogging, AbstractVerbositySpecifier,
                    AbstractMessageLevel, WarnLevel, InfoLevel, Silent, ErrorLevel

# Main verbosity struct
struct PnmlVerbosity{T} <: AbstractVerbositySpecifier{T}
    algorithm_choice::AbstractMessageLevel
    iteration_progress::AbstractMessageLevel

    function PnmlVerbosity{T}(;
            algorithm_choice = WarnLevel(),
            iteration_progress = InfoLevel()
    ) where {T}
        new{T}(algorithm_choice, iteration_progress)
    end
end

# Constructor with enable/disable parameter
PnmlVerbosity(; enable = true, kwargs...) = PnmlVerbosity{enable}(; kwargs...)
const verbose = PnmlVerbosity{true}() # Create enabled verbosity
const silent = PnmlVerbosity{false}() # Create disabled verbosity

"Return file path string after creating intermediate directories."
function logfile(config, filename)
    logname = joinpath(tempdir(), config.base_path, config.log_path, filename)
    mkpath(dirname(logname))
    return logname
    #mktemp(path; cleanup=false)[2]
end
function logstream(path; kwds...)
    open(path, "a")
end
# Create a logger
const logger_for_pnml = SciMLLogging.SciMLLogger(
    info_repl = true,     # Show info in REPL
    warn_repl = true,     # Show warnings in REPL
    error_repl = true,    # Show errors in REPL
    info_file = logstream(logfile(CONFIG, "infos.log")),  # Also log to file
    warn_file = logstream(logfile(CONFIG, "warnings.log")), # Also log to file
    error_file = logstream(logfile(CONFIG, "errors.log")), # Also log warnings to file
)
