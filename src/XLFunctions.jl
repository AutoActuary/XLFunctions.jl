module XLFunctions

function_names = [
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
