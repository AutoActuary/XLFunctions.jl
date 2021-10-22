module XLFunctions

    export text, XLDate, int, date, year, month, day, eomonth

    using Dates: length
    using ReTest
    include("xldates.jl")
    include("functions.jl")

end