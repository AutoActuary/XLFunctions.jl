using ReTest
using Dates: DateTime
import Dates
import Base: show, +, *, -, /, ^, ==


@testset "XLDate" begin

   # Does it display like a number?
   @test repr(XLDate(32937.0)) == "32937"
   @test repr(XLDate(32937)) == "32937"

   # Does it retain it's convertion to and from DateTime?
   nowdate = Dates.now()
   @test XLDate(DateTime(XLDate(DateTime(XLDate(nowdate))))).val ≈ XLDate(nowdate).val
   @test XLDate(DateTime(XLDate(DateTime(XLDate(nowdate).val)).val)).val ≈ XLDate(nowdate).val

   # Does it handle basic arithmitic?
   @test 5 + XLDate(44350.88) == 44355.88
   @test XLDate(44350.88) + 5 == 44355.88

   @test date(10.2, 5.1, 5.2) == 3778
   @test date(1910.2, 5.1, 5.2) == 3778
   @test date(1910, 5, 5) == XLDate(Dates.DateTime(1910, 5, 5))
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


show(io::IO, xldate::XLDate) = print(io, "$(xldate.val)")


DateTime(xldate::XLDate) = DateTime(xldate.val)


DateTime(number::Real) = begin
   decimal, whole = modf(number)
   Dates.DateTime(1899, 12, 30) + Dates.Day(whole) + Dates.Millisecond((floor(decimal * 86400000)))
end


# Conversions
Base.convert(::Type{DateTime}, n::XLDate) = DateTime(n)
Base.convert(::Type{XLDate}, n::DateTime) = XLDate(n)
Base.convert(::Type{T}, n::XLDate) where T<: Real = convert(T, n.val)
Base.convert(::Type{XLDate}, n::T) where T<: Real = XLDate(n)


# Promote to DateTime
Base.promote_rule(::Type{XLDate{T}}, ::Type{DateTime}) where T<:Real = DateTime
Base.promote_rule(::Type{DateTime}, ::Type{XLDate{T}}) where T<:Real = DateTime


# Promote to Real
Base.promote_rule(::Type{XLDate{T₂}}, ::Type{T₁}) where T₁<:Real where T₂<:Real = promote_type(T₁, T₂)
Base.promote_rule(::Type{T₁}, ::Type{XLDate{T₂}}) where T₁<:Real where T₂<:Real = promote_type(T₁, T₂)


# Add some arithmitic promotions
+(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = +(promote(x,y)...)
*(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = *(promote(x,y)...)
-(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = -(promote(x,y)...)
/(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = /(promote(x,y)...)
^(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = ^(promote(x,y)...)
==(x::T₁, y::XLDate{T₂}) where T₁<:Real where T₂<:Real = ==(promote(x,y)...)

+(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = +(promote(x,y)...)
*(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = *(promote(x,y)...)
-(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = -(promote(x,y)...)
/(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = /(promote(x,y)...)
^(x::XLDate{T₁}, y::T₂) where T₁<:Real where T₂<:Real = ^(promote(x,y)...)
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
