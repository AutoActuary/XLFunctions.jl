using ReTest
using Dates: DateTime
import Dates
import Base: show, +, *, -, /, ^, <, >, ==


@testset "XLDate" begin

   # Does it display like a number?
   @test repr(XLDate(32937.0)) == "32937"
   @test repr(XLDate(32937)) == "32937"

   # Does it retain it's convertion to and from DateTime?
   nowdate = Dates.now()
   @test XLDate(DateTime(XLDate(15673))).val ≈ 15673
   @test XLDate(DateTime(XLDate(DateTime(XLDate(nowdate))))).val ≈ XLDate(nowdate).val

   # Does it handle basic arithmitic?
   @test 5 + XLDate(44350.88) == 44355.88
   @test XLDate(44350.88) + 5 == 44355.88
   @test XLDate(44350.88) >= 44350.88

   @test date(10.2, 5.1, 5.2) == 3778
   @test date(1910.2, 5.1, 5.2) == 3778
   @test date(1910, 5, 5) == XLDate(Dates.DateTime(1910, 5, 5))

   @test eomonth(123224,3).val == 123331
   @test eomonth(123224,-3).val == 123147


   projectionstartdate=date(2022, 04, 01)
   rundate = date(2022, 4, 1)
   @test (((year(rundate) * 12 + month(rundate)) - year(projectionstartdate) * 12) - month(projectionstartdate)) + 1 == 1
end


struct XLDate{T<:Real}
   val::T
   XLDate(number::T) where T<:Real = floor(number) == number ? new{Int}(Int(number)) : new{typeof(number)}(number)
end


XLDate(date::DateTime) = begin
   number = Dates.value(date - Dates.DateTime(1899, 12, 30))
   number = number/86400000
   XLDate(number)
end


XLDate(x::XLDate) = x


show(io::IO, xldate::XLDate) = print(io, "$(xldate.val)")


DateTime(xldate::XLDate) = xlnum_to_datetime(xldate.val)


xlnum_to_datetime(number::Real) = begin
   decimal, whole = modf(number)
   Dates.DateTime(1899, 12, 30) + Dates.Day(whole) + Dates.Millisecond((floor(decimal * 86400000)))
end
   

# Conversions
Base.convert(::Type{DateTime}, n::XLDate) = DateTime(n)
Base.convert(::Type{XLDate}, n::DateTime) = XLDate(n)
Base.convert(::Type{T}, n::XLDate) where T<: Real = convert(T, n.val)
Base.convert(::Type{XLDate}, n::T) where T<: Real = XLDate(n)


# Promote to DateTime
Base.promote_rule(::Type{XLDate{T}}, ::Type{DateTime}) where T<:Real = XLDate
Base.promote_rule(::Type{DateTime}, ::Type{XLDate{T}}) where T<:Real = XLDate


# Promote to Real
Base.promote_rule(::Type{XLDate{T₂}}, ::Type{T₁}) where T₁<:Real where T₂<:Real = promote_type(T₁, T₂)
Base.promote_rule(::Type{T₁}, ::Type{XLDate{T₂}}) where T₁<:Real where T₂<:Real = promote_type(T₁, T₂)


# Add some arithmitic promotions
+(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = +(promote(x,y)...)
*(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = *(promote(x,y)...)
-(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = -(promote(x,y)...)
/(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = /(promote(x,y)...)
^(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = ^(promote(x,y)...)
<(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = <(promote(x,y)...)
>(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = >(promote(x,y)...)
==(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = ==(promote(x,y)...)

+(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = +(promote(x,y)...)
*(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = *(promote(x,y)...)
-(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = -(promote(x,y)...)
/(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = /(promote(x,y)...)
^(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = ^(promote(x,y)...)
<(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = <(promote(x,y)...)
>(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = >(promote(x,y)...)
==(y::XLDate{T₂}, x::T₁) where T₁<:Real where T₂<:Real = ==(promote(x,y)...)


"
Excel compatable date function
"
date(year, month, day) = begin
   year, month, day = floor(year), floor(month), floor(day)

   # What the heck Excel:
   year = if year < 1900 year + 1900 else year end
   
   return XLDate(Dates.DateTime(year, month, day))
end

year(x) = Dates.year(DateTime(XLDate(x)))

month(x) = Dates.month(DateTime(XLDate(x)))

day(x) = Dates.day(DateTime(XLDate(x)))

eomonth(x, months) = begin
   avg_gregorian_days_in_month = 365.2425/12

   # First get the middle-ish of the next month (~15th day)
   # Then jump an average month at a time
   # Then floor the month -> (yyy, mm, 1)
   # Then jump one day earlier

   x = (date(year(x), month(x), avg_gregorian_days_in_month/2
         ) + floor(months+1)*avg_gregorian_days_in_month)
   x = XLFunctions.XLDate(date(year(x), month(x), 1)-1)
end