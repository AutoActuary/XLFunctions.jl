module XLFunctions

export XLDate
export_xl = (
    :text,
    :int,
    :date,
    :year,
    :yearfrac,
    :month,
    :day,
    :eomonth,
    :sum,
    :round,
    :roundup,
    :rounddown,
)

# Add xl_ prefix to allow name conflicts
for f in export_xl
    xl_f = Symbol("xl_", f)
    @eval $xl_f(args...) = $f(args...)
    @eval export $f, $xl_f
end

include("xldates.jl")
include("functions.jl")

end
