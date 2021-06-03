include("XLDates.jl")

subtotal_lookup = Dict(
    1 => :average,
    2 => :count,
    3 => :counta,
    4 => :xmax,
    5 => :xmin,
    6 => :product,
    7 => :stdev,
    8 => :stdevp,
    9 => :xsum,
    10 => :var,
    11 => :varp,
)

import Base: sum
sum(args...) = sum(args)


function matchindex(regexmatch::RegexMatch)
    return regexmatch.offset => regexmatch.offset + length(regexmatch.match)-1
end


function TEXT(x::Number, format_text::String)
    # m
    # mm
    # mmm - short form of the month name, for example
    # mmmm - long form of the month name, for example
    # mmmmm - month as the first letter, for example M (stands for March and May)

    # d  dd
    # ddd - abbreviated day of the week, for example
    # dddd - full name of the day of the week, for example

    # h hh m mm s ss AM/PM
    # Minutes if you put "m" immediately after h codes (hours) or immediately before s codes (seconds)

    #yy - two-digit year.
    #yyyy - four-digit year.

    valdict = Dict(
        "m" => "_MONTHS_",
        "d" => "_DAYS_",
        "h" => "_HOURS_",
        "s" => "_SECS_",
        "y" => "_YEAR_"
    )

    monthsdict = 

    r = r"(m+)|(d+)|(h+)|(s+)|(y+)"

    wordlist = []
    idxlist = []

    for m in eachmatch(r, lowercase(format_text))
        push!(idxlist, matchindex(m))
        push!(wordlist, valdict[string(m.match[1])])
    end


    println(idxlist)
    outlist = []
    for i in 1:length(wordlist)
        from = if i==1 1 else idxlist[i-1][2]+1 end
        to = idxlist[i][1]-1

        push!(outlist, format_text[from:to])
        push!(outlist, wordlist[i])
    end

    last = if length(idxlist)==0 1 else idxlist[end][end]+1 end
    push!(outlist, format_text[last:end])

    return outlist
end

join(TEXT(5, "yyy - mmm - yyy - h"), "")


b = match(r"m+", "yyy mmm yyy")




ss = "yyymmmyyymmm"
for m in eachmatch(r"m+", ss)
    i, j = matchindex(m)
    println(ss[i:j])
end
