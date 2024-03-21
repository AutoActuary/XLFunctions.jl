using Dates: Dates
using Printf

struct NegativeStringLengthError <: Exception
    msg::String
end

sum(x) = Base.sum(x)

sum(args...) = Base.sum([sum(i) for i in args])

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

function matchindex(regexmatch::RegexMatch)
    return regexmatch.offset => regexmatch.offset + length(regexmatch.match) - 1
end

function hour_ampm(x::DateTime)
    h = Dates.hour(x)
    displayh = h
    if h == 0
        displayh = 12
    elseif h > 13
        displayh = h - 12
    end
    displayp = h >= 12 ? "pm" : "am"
    return (displayh, displayp)
end

function concat(x::XLDate)
    return concat(x.val)
end

function concat(x::AbstractFloat)
    xstr = string(x)
    if endswith(xstr, ".0")
        xstr = xstr[1:(end - 2)]
    end
    return xstr
end

function concat(x::Union{AbstractArray,Tuple})
    return string((concat(i) for i in x)...)
end

function concat(x)
    return string(x)
end

function concat(args...)
    return concat(args)
end

# TODO: concatenate should not allow nesting
concatenate = concat

_text_short_circuit_patterns = [
    Regex(raw"^(yyyy)([^a-zA-Z])(mm)([^a-zA-Z])(dd)$", "i"),
    Regex(
        raw"^(yyyy)([^a-zA-Z])(mm)([^a-zA-Z])(dd)([^a-zA-Z]{1,2})(hh)([^a-zA-Z])(mm)([^a-zA-Z])(ss)$",
        "i",
    ),
]

function _text_short_circuit(x::Union{Number,XLDate}, format_text::String)
    lc_format_text = lowercase(format_text)
    if lc_format_text == "yyyymmdd"
        datetime = DateTime(XLDate(x))
        formatted_date = Dates.format(datetime, "%Y%m%d")  # Julia doesn't use %Y%m%d for this format
    elseif lc_format_text == "yyyy-mm-dd"
        datetime = DateTime(XLDate(x))
        formatted_date = Dates.format(datetime, "%Y-%m-%d")
    elseif lc_format_text == "yyyy/mm/dd"
        datetime = DateTime(XLDate(x))
        formatted_date = Dates.format(datetime, "%Y/%m/%d")
    elseif lc_format_text == "yyyy-mm-dd hh:mm:ss"
        datetime = DateTime(XLDate(x))
        formatted_date = Dates.format(datetime, "%Y-%m-%d %H:%M:%S")
    end

    # If not any of these, try a more expensive approach for similar ones
    for pattern in _text_short_circuit_patterns
        m = match(pattern, format_text)
        if m !== nothing
            # Convert x to DateTime only if a match is found
            datetime = DateTime(XLDate(x)) # Ensure this conversion is appropriate for your data

            y = lpad(Dates.year(datetime), 4, '0')
            mon = lpad(Dates.month(datetime), 2, '0')
            d = lpad(Dates.day(datetime), 2, '0')

            if pattern == _text_short_circuit_patterns[1]
                sep1 = m[2]
                sep2 = m[4]
                return string(y, sep1, mon, sep2, d)
            elseif pattern == _text_short_circuit_patterns[2]
                sep1 = m[2]
                sep2 = m[4]
                sep3 = m[6]
                sep4 = m[8]
                sep5 = m[10]
                h = lpad(Dates.hour(datetime), 2, '0')
                min = lpad(Dates.minute(datetime), 2, '0')
                sec = lpad(Dates.second(datetime), 2, '0')
                return string(y, sep1, mon, sep2, d, sep3, h, sep4, min, sep5, sec)
            end
        end
    end

    return nothing
end

function text(x::Union{Number,XLDate}, format_text)
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

    quick = _text_short_circuit(x, format_text)
    if quick !== nothing
        return quick
    end

    datedict = Dict(
        "m" => Dates.month,
        "mm" => x -> @sprintf("%02d", Dates.month(x)),
        "mmm" => x -> Dates.monthname(x)[1:3],
        "mmmm" => Dates.monthname,
        "mmmmm" => x -> Dates.monthname(x)[1],
        "d" => Dates.day,
        "dd" => x -> @sprintf("%02d", Dates.day(x)),
        "ddd" => x -> Dates.dayname(x)[1:3],
        "dddd" => Dates.dayname,
        "h" => Dates.hour,
        "hh" => x -> @sprintf("%02d", Dates.hour(x)),
        "am/pm" => x -> (hour_ampm(x)[2]),
        "h_" => x -> (hour_ampm(x)[1]),
        "hh_" => x -> @sprintf("%02d", (hour_ampm(x)[1])),
        "m_" => Dates.minute,
        "mm_" => x -> @sprintf("%02d", Dates.minute(x)),

        # Seconds with milliseconds
        "s" => Dates.second,
        "s.0" => x -> @sprintf("%0.1f", Dates.second(x) + (Dates.millisecond(x) / 1000)),
        "s.00" => x -> @sprintf("%0.2f", Dates.second(x) + (Dates.millisecond(x) / 1000)),
        "s.000" => x -> @sprintf("%0.3f", Dates.second(x) + (Dates.millisecond(x) / 1000)),
        "ss" => x -> @sprintf("%02d", Dates.second(x)),
        "ss.0" => x -> @sprintf("%04.1f", Dates.second(x) + (Dates.millisecond(x) / 1000)),
        "ss.00" => x -> @sprintf("%05.2f", Dates.second(x) + (Dates.millisecond(x) / 1000)),
        "ss.000" =>
            x -> @sprintf("%06.3f", Dates.second(x) + (Dates.millisecond(x) / 1000)),

        # Years
        "yy" => x -> (@sprintf("%04d", Dates.year(x)))[(end - 2):end],
        "yyyy" => x -> @sprintf("%04d", Dates.year(x)),
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
        keylist = [i[1] == 'h' ? i * "_" : i for i in keylist]
    end

    # Correct "minute" relative to hour seconds
    for (i, key) in enumerate(keylist)
        if key ∈ ("m", "mm")
            for (j, char) in [(i - 1, 'h'), (i + 1, 's')]
                if 1 <= j <= length(keylist) && keylist[j][1] == char
                    keylist[i] = key * "_"
                end
            end
        end
    end

    datetime = DateTime(XLDate(x))
    values = [string(datedict[key](datetime)) for key in keylist]

    outlist = []
    for i in 1:length(values)
        from = i == 1 ? 1 : idxlist[i - 1][2] + 1
        to = idxlist[i][1] - 1

        push!(outlist, format_text[from:to])
        push!(outlist, values[i])
    end

    last = if length(idxlist) == 0
        1
    else
        idxlist[end][end] + 1
    end
    push!(outlist, format_text[last:end])

    return join(outlist, "")
end

int(x) = Base.floor(Int, x)

round(x) = Base.round(x)

round(x, n::Int) = Base.round(x * (10.0^n)) / (10.0^n)

roundup(x, n=0) = ceil(x; digits=n)

rounddown(x, n=0) = Base.floor(x; digits=n)

function choose(index, args...)
    return args[int(index)]
end

function upper(::Missing)
    return missing
end

function upper(x::Bool)
    return x ? "TRUE" : "FALSE"
end

function upper(x)
    if x isa Number
        return replace(string(x), r"\.0$" => "")
    end
    return uppercase(string(x))
end

function lower(x::Missing)
    return missing
end

function lower(x::Bool)
    return x ? "true" : "false"
end

function lower(x)
    if x isa Number
        return replace(string(x), r"\.0$" => "")
    end
    return lowercase(string(x))
end

function mid(text::AbstractString, start, num_chars)
    start, num_chars = Base.floor(Int, start), Base.floor(Int, num_chars)
    if start <= 0
        throw(NegativeStringLengthError("mid(...) with start=$(start)"))
    end
    if num_chars < 0
        throw(NegativeStringLengthError("mid(...) with num_chars=$(num_chars)"))
    end
    return text[start:min(start + num_chars - 1, end)]
end

function left(text::AbstractString, num_chars)
    num_chars = Base.floor(Int, num_chars)
    if num_chars < 0
        throw(NegativeStringLengthError("left(...) with num_chars=$(num_chars)"))
    end
    if num_chars == 0
        return ""
    end
    return text[1:min(num_chars, end)]
end

function right(text::AbstractString, num_chars)
    num_chars = Base.floor(Int, num_chars)
    if num_chars < 0
        throw(NegativeStringLengthError("right(...) with num_chars=$(num_chars)"))
    end
    if num_chars == 0
        return ""
    end
    return text[max(1, end - num_chars + 1):end]
end

function substitute(
    text::AbstractString,
    old_text::AbstractString,
    new_text::AbstractString,
    instance_num::Union{Real,Nothing}=nothing,
)
    if instance_num === nothing
        # If no instance_num provided, replace all instances (case-sensitive)
        return replace(text, old_text => new_text)
    end

    instance_num = Base.floor(Int, instance_num)

    if instance_num < 1
        throw(ArgumentError("instance_num must be greater than or equal to 1"))
    end

    # Replace specific instance (case-sensitive)
    count = 0
    result = ""
    last_pos = 1
    found = false
    for m in eachmatch(Regex(escape_string(old_text)), text)
        count += 1
        if count == instance_num
            found = true
            result *= text[last_pos:(m.offset - 1)] * new_text
            last_pos = m.offset + length(m.match) # Corrected usage
            break
        else
            result *= text[last_pos:(m.offset - 1)] * m.match
            last_pos = m.offset + length(m.match) # Corrected usage
        end
    end
    if !found && instance_num > 1
        # If the specified instance was not found, return the original text
        return text
    end
    result *= text[last_pos:end]
    return result
end
