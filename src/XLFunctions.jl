module XLFunctions

# These functions match the names of the Excel functions exactly
function_names = [
    :ceiling,
    :choose,
    :concat,
    :concatenate,
    :date,
    :datedif,
    :day,
    :eomonth,
    :edate,
    :floor,
    :int,
    :left,
    :lower,
    :mid,
    :month,
    :right,
    :round,
    :rounddown,
    :roundup,
    :substitute,
    :sum,
    :text,
    :upper,
    :year,
    :yearfrac,
]

include("xldates_xlserial.jl")
include("xldates.jl")
include("functions.jl")
include("functions_with_dots.jl")
include("boolcast.jl")

export XLDate
export bool
export BoolCastError
export NegativeStringLengthError

# Generate a Dict to access all Excel functions by name
xlfunctions = Dict(i => eval(i) for i in function_names)
for f in function_names
    @eval export $f
end
export xlfunctions

end
