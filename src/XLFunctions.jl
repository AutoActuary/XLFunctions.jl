module XLFunctions

    export text, XLDate, int

    using Dates: length
    using ReTest
    include("xldates.jl")
    include("functions.jl")

end