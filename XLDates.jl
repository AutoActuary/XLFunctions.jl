using Dates
import Base: show

struct XLDate{T<:Real}
   val::T
end

show(io::IO, xldate::XLDate) = show(io, "XLDate($(xldatetodate(xldate)))")

function xldatetodate(xldate::Integer)
   Dates.DateTime(1899, 12, 30) + Dates.Day(xldate)
end
function xldatetodate(xldate::Real)
   t,d = modf(xldate)
   return Dates.DateTime(1899, 12, 30) + Dates.Day(d) + Dates.Millisecond((floor(t * 86400000)))
end

function xldatetodate(xldate::XLDate)
   xldatetodate(xldate.val)
end

function xldatetodate(xldate::XLDate)
   xldatetodate(xldate.val)
end

function toxldate(date::Date)
   datetime = Dates.value(DateTime(date) - Dates.DateTime(1899, 12, 30))
   datetime = round(datetime/86400000,digits = 3)
   return XLDate(datetime)
end

function toxldate(date::DateTime)
   datetime = Dates.value(date - Dates.DateTime(1899, 12, 30))
   datetime = round(datetime/86400000,digits = 3)
   return XLDate(datetime)
end

Base.convert(d::Type{Dates.DateTime},n::XLDate) = xldatetodate(n)
Base.convert(d::Type{Dates.Date},n::XLDate) = convert(Date,xldatetodate(n))
Base.convert(d::Type{T},n::XLDate) where T<: Real = convert(d,n.val)
Base.convert(d::Type{XLDate},n::Dates.DateTime) = toxldate(n)
Base.convert(d::Type{XLDate},n::Dates.Date) = toxldate(n)


function text(xldate::XLDate, format_text::String)
end


# m mm
# mmm - short form of the month name, for example
# mmmm - long form of the month name, for example
# mmmmm - month as the first letter, for example M (stands for March and May)

# d  dd
# ddd - abbreviated day of the week, for example
# dddd - full name of the day of the week, for example

# h hh m mm s ss AM/PM
# Minutes if you put "m" immediately after h codes (hours) or immediately before s codes (seconds)
