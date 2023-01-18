module XLFunctions

export XLDate, text, int, date, yearfrac, year, month, day, eomonth

# Add xl_ prefix to allow name conflicts
for f in (:text, :int, :date, :year, :yearfrac, :month, :day, :eomonth)
    xl_f = Symbol("xl_", f)
    @eval $xl_f(args...) = $f(args...)
    @eval export $xl_f
end

include("xldates.jl")
include("functions.jl")

end
