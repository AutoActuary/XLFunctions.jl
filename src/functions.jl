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

function _format(x)
    if isa(x, XLDate)
        return _format(x.val)
    end

    if isa(x, Real) && x == round(x)
        return replace(string(x), r"\.0$" => "")
    end

    return string(x)
end

function _flatten_and_format(args...)
    formatted_args = map(x -> begin
        if typeof(x) <: Union{AbstractArray,Tuple}
            _flatten_and_format(x...)
        else
            _format(x)
        end
    end, args)
    return vcat(formatted_args...)
end

function concat(args...)
    formatted_args = _flatten_and_format(args...)
    return string(formatted_args...)
end

function concatenate(args...)
    return string(_format.(args)...)
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

int(x) = floor(Int, x)

round(x) = Base.round(x)

round(x, n::Int) = Base.round(x * (10.0^n)) / (10.0^n)

roundup(x, n=0) = ceil(x; digits=n)

rounddown(x, n=0) = floor(x; digits=n)

struct _Ceiling
    math::Base.Callable  # Use a more specific type as needed
end

function _ceiling(x, significance)
    return ceil(x / significance) * significance
end

function _ceiling_math(x, significance=1.0, mode=0)
    if significance == 0
        return typeof(x)(0)
    end

    # Adjusting significance for negative numbers based on mode
    adjusted_significance = significance
    if mode != 0 && x < 0
        adjusted_significance = -abs(significance)
    else
        adjusted_significance = abs(significance)
    end

    return ceil(x / adjusted_significance) * adjusted_significance
end

function (::_Ceiling)(x, significance)
    return _ceiling(x, significance)
end


ceiling = _Ceiling(_ceiling_math)


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
