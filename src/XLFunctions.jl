module XLFunctions

function_names = [
    :ceiling,
    :choose,
    :concatenate,
    :date,
    :day,
    :eomonth,
    :int,
    :month,
    :round,
    :rounddown,
    :roundup,
    :sum,
    :text,
    :year,
    :yearfrac,
]

include("xldates.jl")
include("functions.jl")

xlfunctions = Dict(i => eval(i) for i in function_names)

export XLDate
for f in function_names
    @eval export $f
end
export xlfunctions

end
