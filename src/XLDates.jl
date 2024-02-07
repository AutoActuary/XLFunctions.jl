using Dates: Dates, DateTime, length
import Base: repr, show, +, *, -, /, ^, <, >, ==, isless, convert, promote_rule

struct XLDate{T<:Real}
    val::T
    function XLDate(number::T) where {T<:Real}
        return floor(number) == number ? new{Int}(Int(number)) : new{typeof(number)}(number)
    end
end

XLDate(date::DateTime) = begin
    number = Dates.value(date - Dates.DateTime(1899, 12, 30))
    number = number / 86400000
    XLDate(number)
end

XLDate(date::Dates.Date) = XLDate(Dates.DateTime(date))

function XLDate(date::T) where {T<:AbstractString}
    # Convert Excel datetime format to ISO format by replacing space with 'T'
    date_iso = replace(date, r"^(\d{4}-\d{2}-\d{2}) (\d{2})" => s"\1T\2")
    fracmatch = match(r"T\d{2}:\d{2}:\d{2}(\.\d+)?$", date_iso)

    # Attempt to detect and construct a format string for fractional seconds
    if fracmatch !== nothing && fracmatch.captures[1] !== nothing
        # There are fractional seconds, handle them appropriately
        return XLDate(
            DateTime(
                date_iso,
                "yyyy-mm-ddTHH:MM:SS." * repeat("s", length(fracmatch.captures[1]) - 1),
            ),
        )
    else
        return XLDate(DateTime(date_iso))
    end
end

#TODO: Why cast to itself?
XLDate(date::XLDate) = date

function _xldate_to_iso8601(xldate::XLDate)
    datetime = Dates.DateTime(xldate)
    return if xldate.val == floor(xldate.val)
        # format to ISO 8601 day
        Dates.format(datetime, "yyyy-mm-dd")
    else
        # format to ISO 8601 milliseconds
        Dates.format(datetime, "yyyy-mm-ddTHH:MM:SS.sss")
    end
end

function repr(xldate::XLDate)
    return "XLDate(\"$(_xldate_to_iso8601(xldate))\")"
end

function show(io::IO, xldate::XLDate)
    return print(io, _xldate_to_iso8601(xldate))
end

DateTime(xldate::XLDate) = xlnum_to_datetime(xldate.val)

function xlnum_to_datetime(number::Real)
    decimal, whole = modf(number)
    return Dates.DateTime(1899, 12, 30) +
           Dates.Day(whole) +
           Dates.Millisecond((floor(decimal * 86400000)))
end

# Conversions
function convert(::Type{XLDate{T₁}}, n::XLDate{T₂}) where {T₁} where {T₂}
    return DateTime(convert(T₁, n.val))
end
convert(::Type{DateTime}, n::XLDate) = DateTime(n)
convert(::Type{XLDate}, n::DateTime) = XLDate(n)
convert(::Type{T}, n::XLDate) where {T<:Real} = convert(T, n.val)
convert(::Type{XLDate}, n::T) where {T<:Real} = XLDate(n)
convert(::Type{XLDate}, n::T) where {T<:AbstractString} = XLDate(n)

# # promote XLDate types is describes by the operations +, *, -, /, ^, <, >, ==, isless
# function promote_rule(::Type{XLDate{T₁}}, ::Type{XLDate{T₂}}) where {T₁} where {T₂}
#    return XLDate{promote_type(T₁, T₂)}
# end

function promote_rule(::Type{XLDate{T}}, ::Type{DateTime}) where {T}
    return XLDate
end

# promote XLDate types with other types
function promote_rule(::Type{XLDate{T₁}}, ::Type{T₂}) where {T₁} where {T₂<:Real}
    return promote_type(T₁, T₂)
end

function promote_rule(::Type{XLDate{T₁}}, ::Type{T₂}) where {T₁} where {T₂<:AbstractString}
    return XLDate
end

# Add some arithmitic promotions
for op in (:(+), :(*), :(-), :(/), :(^))
    @eval function ($op)(x::XLDate{T₁}, y::XLDate{T₂}) where {T₁} where {T₂}
        return XLDate(($op)(x.val, y.val))
    end
end

for op in (:(<), :(>), :(==), :isless)
    @eval ($op)(x::XLDate{T₁}, y::XLDate{T₂}) where {T₁} where {T₂} = ($op)(x.val, y.val)
end

for op in (:(+), :(*), :(-), :(/), :(^), :(<), :(>), :(==), :isless)
    @eval ($op)(x::T₁, y::XLDate{T₂}) where {T₁} where {T₂} = ($op)(promote(x, y)...)
    @eval ($op)(x::XLDate{T₁}, y::T₂) where {T₁} where {T₂} = ($op)(promote(x, y)...)
end

"
Excel compatable date function
"
function date(year, month, day)
    year, month, day = floor(year), floor(month), floor(day)

    # What the heck Excel:
    year = if year < 1900
        year + 1900
    else
        year
    end

    return XLDate(Dates.DateTime(year, month, day))
end

year(x) = Dates.year(Dates.DateTime(XLDate(x)))

month(x) = Dates.month(Dates.DateTime(XLDate(x)))

day(x) = Dates.day(Dates.DateTime(XLDate(x)))

function eomonth(x, months)
    avg_gregorian_days_in_month = 365.2425 / 12

    # First get the middle-ish of the next month (~15th day)
    # Then jump an average month at a time
    # Then floor the month -> (yyy, mm, 1)
    # Then jump one day earlier

    x = (
        date(year(x), month(x), avg_gregorian_days_in_month / 2) +
        floor(months + 1) * avg_gregorian_days_in_month
    )
    return x = XLFunctions.XLDate(date(year(x), month(x), 1) - 1)
end

function yearfrac(start_date, end_date, basis=0)
    start_date, end_date = minmax(XLDate(start_date), XLDate(end_date))

    if basis == 0
        # US (NASD) 30/360
        d_start = if day(start_date) == 31
            30
        else
            day(start_date)
        end
        d_end = if day(end_date) == 31 && day(start_date) in [31, 30]
            30
        else
            day(end_date)
        end
        return (
            360 * year(end_date) + 30 * month(end_date) + d_end - 360 * year(start_date) -
            30 * month(start_date) - d_start
        ) / 360

    elseif basis == 1
        # actual/actual
        years = year(start_date):year(end_date)
        nr_days_in_those_years = sum(Dates.Dates.daysinyear(i) for i in years)
        return (end_date - start_date) / (nr_days_in_those_years / length(years))

    elseif basis == 2
        # Actual/360
        return (end_date - start_date) / 360

    elseif basis == 3
        # Actual/365
        return (end_date - start_date) / 365

    elseif basis == 4
        # European 30/360
        d_start = if day(start_date) == 31
            30
        else
            day(start_date)
        end
        d_end = if day(end_date) == 31
            30
        else
            day(end_date)
        end
        return (
            360 * year(end_date) + 30 * month(end_date) + d_end - 360 * year(start_date) -
            30 * month(start_date) - d_start
        ) / 360
    else
        throw(ArgumentError("basis must be between 0 and 4"))
    end
end
