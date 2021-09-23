import Base: sum
using Dates
using Printf

# Naughty pirating to adhere to XL's way of doing things
sum(args...) = sum(args)


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


matchindex(regexmatch::RegexMatch) = begin
    return regexmatch.offset => regexmatch.offset + length(regexmatch.match)-1
end


hour_ampm(x::DateTime) = begin
    h = hour(x)
    displayh = h
    if h == 0
        displayh = 12
    elseif h > 13
        displayh = h - 12
    end
    displayp= h >= 12 ? "pm" : "am"
    (displayh, displayp)
end


text(x::Union{Number,XLDate}, format_text) = begin
    # m - e.g. 2 (or minute if after "h"/"hh" or immediately before "s"/"ss")
    # mm - e.g. 02 
    # mmm - e.g. Feb - short form of the month name, for example
    # mmmm - e.g. February - long form of the month name, for example
    # mmmmm - e.g. F - month as the first letter, for example M (stands for March and May)

    # d - e.g. 5
    # dd - e.g. 05
    # ddd - abbreviated day of the week, for example
    # dddd - full name of the day of the week, for example

    # h hh m mm s ss AM/PM
    # Minutes if you put "m" immediately after h codes (hours) or immediately before s codes (seconds)
    # h/hh change to <=12 if AM/PM present

    #yy - two-digit year.
    #yyyy - four-digit year.

    datedict = Dict(
        "m" => month,
        "mm" => x->@sprintf("%02d", month(x)),
        "mmm" => x->monthname(x)[1:3],
        "mmmm" => monthname,
        "mmmmm" => x->monthname(x)[1],
        "d" => day,
        "dd" => x->@sprintf("%02d", day(x)),
        "ddd" => x->dayname(x)[1:3],
        "dddd" => dayname,

        "h" => hour,
        "hh" => x->@sprintf("%02d", hour(x)),

        "am/pm" => x->(hour_ampm(x)[2]),
        "h_" => x->(hour_ampm(x)[1]),
        "hh_" => x->@sprintf("%02d", (hour_ampm(x)[1])),

        "m_" => minute,
        "mm_" => x->@sprintf("%02d", minute(x)),

        # Seconds with milliseconds
        "s" => second,
        "s.0" => x->@sprintf("%0.1f", second(x)+(millisecond(x)/1000)),
        "s.00" => x->@sprintf("%0.2f", second(x)+(millisecond(x)/1000)),
        "s.000" => x->@sprintf("%0.3f", second(x)+(millisecond(x)/1000)),
        "ss" => x->@sprintf("%02d", second(x)),
        "ss.0" => x->@sprintf("%04.1f", second(x)+(millisecond(x)/1000)),
        "ss.00" => x->@sprintf("%05.2f", second(x)+(millisecond(x)/1000)),
        "ss.000" => x->@sprintf("%06.3f", second(x)+(millisecond(x)/1000)),

        # Years
        "yy" => x->(@sprintf("%04d", year(x)))[end-2:end],
        "yyyy" => x->@sprintf("%04d", year(x)),
    )

    #monthsdict = ...?
    r = r"(am/pm)|(m{1,5})|(d{1,4})|(h{1,2})|(s{1,2}\.0{1,3})|(s{1,2})|(yyyy)|(yy)"

    keylist = []
    idxlist = []

    for m in eachmatch(r, lowercase(format_text))
        push!(idxlist, matchindex(m))
        key = string(m.match)
        push!(keylist, key)
    end

    # Correct "hour" if am/pm present
    if "am/pm" ∈ keylist
        keylist = [i[1]=='h' ? i*"_" : i for i in keylist]
    end

    # Correct "minute" relative to hour seconds
    for (i, key) ∈ enumerate(keylist)
        if key ∈ ("m", "mm")
            for (j, char) ∈ [(i-1, 'h'), (i+1, 's')]
                if 1 <= j <= length(keylist) && keylist[j][1] == char 
                    keylist[i] = key*"_"
                end
            end
        end
    end
    
    datetime = DateTime(x)
    values = [string(datedict[key](datetime)) for key in keylist]

    outlist = []
    for i in 1:length(values)
        from = i==1 ? 1 : idxlist[i-1][2]+1
        to = idxlist[i][1]-1

        push!(outlist, format_text[from:to])
        push!(outlist, values[i])
    end

    last = if length(idxlist)==0 1 else idxlist[end][end]+1 end
    push!(outlist, format_text[last:end])

    return join(outlist, "")
end


@testset "text" begin
    nums = [64.16983719, 719.4682757, 749.8760207, 284.6091198, 447.6473053, 89.31552312, 850.0871191, 451.3678795, 581.5977343, 651.2308527, 344.1675642]
    results = ["04:04:33.93 am", "11:14:19.02 am", "09:01:28.19 pm", "02:37:07.95 pm", "03:32:07.18 pm", "07:34:21.20 am", "02:05:27.09 am", "08:49:44.79 am", "02:20:44.24 pm", "05:32:25.67 am", "04:01:17.55 am"]

    for (num, result) ∈ zip(nums, results)
        @test text(num, "hh:mm:ss.00 AM/PM") == result
        @test text(num, "hh:mm:s.00 AM/PM") == replace(result, ":07."=>":7.")
    end

    results = ["19000304", "19011219", "19020118", "19001010", "19010322", "19000329", "19020429", "19010326", "19010803", "19011012", "19001209"]
    for (num, result) ∈ zip(nums, results)
        @test text(num, "yyyyMMdd") == result
    end 
end


int(x) = floor(Int,x)