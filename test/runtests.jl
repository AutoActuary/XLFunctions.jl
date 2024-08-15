using XLFunctions

@testitem "xlserial" begin
    using Dates
    lhs = []
    rhs = []
    for xlserial in 70:500000
        push!(lhs, XLFunctions._year_month_day_of_xlserial(xlserial))

        datetime_result = XLFunctions.xlnum_to_datetime(xlserial)
        year, month, day = Dates.year(datetime_result),
        Dates.month(datetime_result),
        Dates.day(datetime_result)
        push!(rhs, (year, month, day))
    end

    @test lhs == rhs
end

@testitem "xldate" begin
    using Dates: Dates, DateTime

    # Does it display like truncated ISO 8601?
    @test repr(XLDate(32937.0)) == "XLDate(\"1990-03-05\")"
    @test repr(XLDate(32937)) == "XLDate(\"1990-03-05\")"
    @test repr(XLDate(32937.12345)) == "XLDate(\"1990-03-05T02:57:46.079\")"
    @test string(date(1910, 5, 5)) == "1910-05-05"
    @test "$(date(1910, 5, 5))" == "1910-05-05"

    # Non ISO complient
    @test XLDate("2020-01-01 15:01:34") == XLDate("2020-01-01T15:01:34")

    # Decimals allowed
    @test XLDate("2020-01-01 15:01:34.12").val == 43831.62608935185
    @test XLDate("2020-01-01 15:01:34.120").val == 43831.62608935185
    @test XLDate("2020-01-01 15:01:34.1200").val == 43831.62608935185
    @test XLDate("2020-01-01 15:01:34.12000").val == 43831.62608935185
    @test XLDate("2020-01-01 15:01:34.120000").val == 43831.62608935185
    @test XLDate("2020-01-01 15:01:34.1200000").val == 43831.62608935185

    # Does it retain it's convertion to and from DateTime?
    nowdate = Dates.now()
    @test XLDate(DateTime(XLDate(15673))).val ≈ 15673
    @test XLDate(DateTime(XLDate(DateTime(XLDate(nowdate))))).val ≈ XLDate(nowdate).val
    x = Dates.now()
    @test XLDate(x) - XLDate(Dates.Date(x)) < 1.0001
    @test 32937 == XLDate(32937.0)

    # Does it handle basic arithmitic?
    @test 5 + XLDate(44350.88) == 44355.88
    @test XLDate(44350.88) + 5 == 44355.88
    @test XLDate(44350.88) >= 44350.88

    # Can you extract year month and day
    @test date(10.2, 5.1, 5.2) == 3778
    @test date(1910.2, 5.1, 5.2) == 3778
    @test date(1910, 5, 5) == XLDate(Dates.DateTime(1910, 5, 5))

    # Can you extract year month and day from a String
    @test year("2020-01-02") == 2020
    @test month("2020-01-02") == 1
    @test day("2020-01-02") == 2

    @test eomonth(123224, 3).val == 123331
    @test eomonth(123224, -3).val == 123147
    @test string(eomonth("2023-01-15", 1)) == "2023-02-28"
    @test string(eomonth("2023-01-31", 0)) == "2023-01-31"
    @test string(eomonth("2023-02-01", -1)) == "2023-01-31"
    @test string(eomonth("2023-12-31", 2)) == "2024-02-29"
    @test string(eomonth("2024-01-01", -2)) == "2023-11-30"
    @test string(eomonth("2023-03-31", -1)) == "2023-02-28"
    @test string(eomonth("2023-05-15", 6)) == "2023-11-30"
    @test string(eomonth("2023-08-31", -3)) == "2023-05-31"
    @test string(eomonth("2023-07-01", 12)) == "2024-07-31"
    @test string(eomonth("2023-01-15", 1.9)) == "2023-02-28"
    @test string(eomonth("2023-01-31", 0.5)) == "2023-01-31"
    @test string(eomonth("2023-02-01", -1.1)) == "2023-01-31"
    @test string(eomonth("2023-12-31", 2.8)) == "2024-02-29"
    @test string(eomonth("2024-01-01", -2.5)) == "2023-11-30"
    @test string(eomonth("2023-03-31", -1.9)) == "2023-02-28"
    @test string(eomonth("2023-05-15", 6.7)) == "2023-11-30"
    @test string(eomonth("2023-08-31", -3.2)) == "2023-05-31"
    @test string(eomonth("2023-07-01", 12.4)) == "2024-07-31"

    @test string(edate("2022-01-05", -1)) == "2021-12-05"
    @test string(edate("2022-01-05", -1.01)) == "2021-12-05"
    @test string(edate("2024-02-29", -1)) == "2024-01-29"
    @test string(edate("2022-01-31", 1)) == "2022-02-28"
    @test string(edate("2022-03-31", 1)) == "2022-04-30"
    @test string(edate("2022-12-31", 1)) == "2023-01-31"
    @test string(edate("2023-02-28", 1)) == "2023-03-28"
    @test string(edate("2023-01-31", 1)) == "2023-02-28"
    @test string(edate("2024-01-31", 1)) == "2024-02-29"
    @test string(edate("2022-03-31", -1)) == "2022-02-28"
    @test string(edate("2022-01-01", -2)) == "2021-11-01"
    @test string(edate("2024-03-01", -1)) == "2024-02-01"
    @test string(edate("2022-01-31", 0.5)) == "2022-01-31"
    @test string(edate("2022-11-30", -0.5)) == "2022-11-30"
    @test string(edate("2022-01-15", 12)) == "2023-01-15"
    @test string(edate("2022-01-15", -12)) == "2021-01-15"
    @test string(edate("2021-12-31", 1)) == "2022-01-31"
    @test string(edate("2022-01-01", -1)) == "2021-12-01"

    projectionstartdate = date(2022, 04, 01)
    rundate = date(2022, 4, 1)
    @test (
        ((year(rundate) * 12 + month(rundate)) - year(projectionstartdate) * 12) -
        month(projectionstartdate)
    ) + 1 == 1

    start_date = date(2012, 1, 1)
    end_date = date(2012, 7, 30)

    for i in 1:4
        @test yearfrac(end_date, end_date, i) == 0
    end
    @test yearfrac(start_date, end_date) ≈ 0.58055556
    @test yearfrac(start_date, end_date, 1) ≈ 0.57650273
    @test yearfrac(start_date, end_date, 3) ≈ 0.57808219
    @test yearfrac(start_date, end_date, 4) ≈ 0.58055555

    start_date = date(2019, 1, 1)
    end_date = date(2022, 7, 31)

    @test yearfrac(start_date, end_date) ≈ 3.583333333
    @test yearfrac("2019-01-01", "2022-07-31") ≈ 3.583333333
    @test yearfrac(start_date, end_date, 1) ≈ 3.578370979
    @test yearfrac(start_date, end_date, 2) ≈ 3.630555556
    @test yearfrac(start_date, end_date, 3) ≈ 3.580821918
    @test yearfrac(start_date, end_date, 4) ≈ 3.580555556

    @test "2019-01-01" + XLDate(1) == "2019-01-02"
    @test XLDate(1) + "2019-01-01" == "2019-01-02"
    @test_throws MethodError "2019-01-01" + "2022-07-31"
    @test_throws MethodError "2019-01-01" + 1
end

@testitem "ceiling" begin
    # Excel should be ashamed
    @test_throws ArgumentError XLFunctions.ceiling(12.5, -2.5)
    @test_throws ArgumentError XLFunctions.ceiling(5, -1)
    @test_throws ArgumentError XLFunctions.ceiling(5.5, -1.1)
    @test 0 == XLFunctions.ceiling(15, 0)

    @test 11 == XLFunctions.ceiling(10.5, 1)
    @test 10.5 == XLFunctions.ceiling(10.1, 0.5)
    @test -4 == XLFunctions.ceiling(-5.5, 2)
    @test 12.3 == XLFunctions.ceiling(12.25, 0.1)
    @test 15 == XLFunctions.ceiling(12, 5)
    @test -10 == XLFunctions.ceiling(-12, 5)
    @test -15 == XLFunctions.ceiling(-12, -5)
    @test 7.8 ≈ XLFunctions.ceiling(7.8, 0.2)
    @test 0 == XLFunctions.ceiling(0, 10)
    @test 0 == XLFunctions.ceiling(-2, 3)
    @test 123.456 == XLFunctions.ceiling(123.456, 0.001)
    @test 99.99 ≈ XLFunctions.ceiling(99.99, 0.01)
    @test 99 == XLFunctions.ceiling(99, 33)
    @test 100 == XLFunctions.ceiling(100, 100)
    @test 0 == XLFunctions.ceiling(-0.1, 1)
    @test 2 == XLFunctions.ceiling(1.1, 1)
    @test -1 == XLFunctions.ceiling(-1.1, 1)
    @test 1.5 == XLFunctions.ceiling(1.1, 0.5)
    @test -1 == XLFunctions.ceiling(-1.1, 0.5)
    @test -1 == XLFunctions.ceiling(-1, 0.5)
    @test 0 == XLFunctions.ceiling(0, 1)
    @test -4 == XLFunctions.ceiling(-3.5, -1)
    @test 3 == XLFunctions.ceiling(2.5, 1)
    @test -3 == XLFunctions.ceiling(-2.6, -0.5)
    @test 3 == XLFunctions.ceiling(2.6, 0.5)
    @test 4 == XLFunctions.ceiling(3.5, 2)
    @test -2 == XLFunctions.ceiling(-3.5, 2)
    @test 100 == XLFunctions.ceiling(100, 10)
    @test -100 == XLFunctions.ceiling(-100, 10)
    @test 0.1 == XLFunctions.ceiling(0.001, 0.1)
    @test 0.05 == XLFunctions.ceiling(0.001, 0.05)
end

@testitem "ceiling.math" begin
    @test 11 == ceiling.math(10.5, 1)
    @test 10.5 == ceiling.math(10.1, 0.5)
    @test -6 == ceiling.math(-5.5, 2, 1)
    @test -4 == ceiling.math(-5.5, 2)
    @test 12.3 == ceiling.math(12.25, 0.1)
    @test 15 == ceiling.math(12, 5)
    @test -15 == ceiling.math(-12, 5, 1)
    @test -10 == ceiling.math(-12, -5)
    @test 12.5 == ceiling.math(12.5, -2.5, 0)
    @test 0 == ceiling.math(15, 0)
    @test 7.8 ≈ ceiling.math(7.8, 0.2)
    @test -7.8 ≈ ceiling.math(-7.8, 0.2, 1)
    @test 0 == ceiling.math(0, 10)
    @test -3 == ceiling.math(-2, 3, 1)
    @test -2.5 == ceiling.math(-2.5, 0.5, 1)
    @test 5 == ceiling.math(5, -1)
    @test 5.5 == ceiling.math(5.5, -1.1)
    @test -5.5 == ceiling.math(-5.5, -1.1, 1)
    @test 123.456 == ceiling.math(123.456, 0.001)
    @test -123.456 == ceiling.math(-123.456, 0.001, 1)
    @test 99.99 ≈ ceiling.math(99.99, 0.01)
    @test 99 == ceiling.math(99, 33)
    @test -99 == ceiling.math(-99, 33, 1)
    @test 100 == ceiling.math(100, 100)
    @test -100 == ceiling.math(-100, 100, 0)
    @test -100 == ceiling.math(-100, 100, 1)
    @test 11 == ceiling.math(10.5)
end

@testitem "floor" begin
    # Excel should be ashamed
    @test_throws ArgumentError XLFunctions.floor(12.5, -2.5)
    @test_throws ArgumentError XLFunctions.floor(15, 0)
    @test_throws ArgumentError XLFunctions.floor(5, -1)
    @test_throws ArgumentError XLFunctions.floor(5.5, -1.1)

    @test 10 == XLFunctions.floor(10.5, 1)
    @test 10 == XLFunctions.floor(10.1, 0.5)
    @test -6 == XLFunctions.floor(-5.5, 2)
    @test 12.2 ≈ XLFunctions.floor(12.25, 0.1)
    @test 10 == XLFunctions.floor(12, 5)
    @test -15 == XLFunctions.floor(-12, 5)
    @test -10 == XLFunctions.floor(-12, -5)

    @test 7.8 ≈ XLFunctions.floor(7.8, 0.2)
    @test 0 == XLFunctions.floor(0, 10)
    @test -3 == XLFunctions.floor(-2, 3)

    @test 123.456 == XLFunctions.floor(123.456, 0.001)
    @test 99.99 ≈ XLFunctions.floor(99.99, 0.01)
    @test 99 == XLFunctions.floor(99, 33)
    @test 100 == XLFunctions.floor(100, 100)
end

@testitem "floor.math" begin
    @test 10 == XLFunctions.floor.math(10.5, 1)
    @test 10 == XLFunctions.floor.math(10.1, 0.5)
    @test -4 == XLFunctions.floor.math(-5.5, 2, 1)
    @test -6 == XLFunctions.floor.math(-5.5, 2)
    @test 12.2 ≈ XLFunctions.floor.math(12.25, 0.1)
    @test 10 == XLFunctions.floor.math(12, 5)
    @test -10 == XLFunctions.floor.math(-12, 5, 1)
    @test -15 == XLFunctions.floor.math(-12, -5)
    @test 12.5 == XLFunctions.floor.math(12.5, -2.5, 0)
    @test 0 == XLFunctions.floor.math(15, 0)
    @test 7.8 ≈ XLFunctions.floor.math(7.8, 0.2)
    @test -7.8 ≈ XLFunctions.floor.math(-7.8, 0.2, 1)
    @test 0 == XLFunctions.floor.math(0, 10)
    @test 0 == XLFunctions.floor.math(-2, 3, 1)
    @test -2.5 == XLFunctions.floor.math(-2.5, 0.5, 1)
    @test 5 == XLFunctions.floor.math(5, -1)
    @test 5.5 == XLFunctions.floor.math(5.5, -1.1)
    @test -5.5 == XLFunctions.floor.math(-5.5, -1.1, 1)
    @test 123.456 == XLFunctions.floor.math(123.456, 0.001)
    @test -123.456 == XLFunctions.floor.math(-123.456, 0.001, 1)
    @test 99.99 ≈ XLFunctions.floor.math(99.99, 0.01)
    @test 99 == XLFunctions.floor.math(99, 33)
    @test -99 == XLFunctions.floor.math(-99, 33, 1)
    @test 100 == XLFunctions.floor.math(100, 100)
    @test -100 == XLFunctions.floor.math(-100, 100, 0)
    @test -100 == XLFunctions.floor.math(-100, 100, 1)
    @test 10 == XLFunctions.floor.math(10.5)
end

@testitem "dateif" begin
    @test datedif("2001-01-01", "2003-01-01", "Y") == 2
    @test datedif("2001-06-01", "2002-08-15", "D") == 440
    #@test datedif("2001-06-01", "2002-08-15", "YD") == 75
    @test datedif("2001-01-01", "2001-12-31", "M") == 11
    @test datedif("2001-02-28", "2002-02-28", "Y") == 1
    @test datedif("2001-02-28", "2002-03-01", "Y") == 1
    @test datedif("2001-02-28", "2004-02-29", "Y") == 3
    @test datedif("2001-01-01", "2001-01-31", "MD") == 30
    #@test datedif("2001-01-31", "2001-02-28", "MD") == 28
    @test datedif("2001-01-01", "2002-01-01", "YM") == 0
    #@test datedif("2001-12-31", "2002-01-01", "YM") == 0
    #@test datedif("2001-01-31", "2001-02-01", "MD") == 1
    #@test datedif("2000-02-29", "2001-02-28", "YD") == 365
    #@test datedif("2000-02-29", "2001-03-01", "YD") == 0
    @test datedif("2001-04-01", "2001-05-01", "MD") == 0
    #@test datedif("2001-04-30", "2001-05-31", "MD") == 1
    #@test datedif("2000-01-01", "2000-12-31", "YD") == 365
    #@test datedif("2001-03-31", "2002-04-01", "YD") == 1
    @test datedif("2024-02-29", "2024-02-29", "D") == 0
    @test datedif("2024-02-29", "2025-02-28", "Y") == 0
    @test datedif("2024-02-29", "2028-02-29", "Y") == 4
    #@test datedif("2024-02-29", "2024-03-01", "MD") == 1
    #@test datedif("2024-02-29", "2024-03-29", "MD") == 0
    #@test datedif("2024-02-29", "2024-03-30", "MD") == 1
    #@test datedif("2024-02-29", "2024-03-31", "MD") == 2
    #@test datedif("2024-02-29", "2024-04-01", "MD") == 3
    #@test datedif("2024-12-31", "2025-01-01", "YD") == 1
    @test datedif("2023-01-01", "2024-01-01", "YM") == 0
    @test datedif("2023-02-28", "2024-02-28", "YM") == 0
    @test datedif("2023-02-28", "2024-02-29", "YM") == 0
    #@test datedif("2024-01-31", "2024-02-29", "YM") == 0
    #@test datedif("2024-02-29", "2025-02-28", "YD") == 365
    #@test datedif("2024-02-29", "2025-03-01", "YD") == 0
    @test datedif("2024-02-29", "2024-02-29", "M") == 0
    @test datedif("2024-02-29", "2024-02-29", "Y") == 0
    #@test datedif("2019-03-31", "2019-04-30", "MD") == 30
    #@test datedif("2019-03-30", "2019-04-30", "MD") == 0
    @test datedif("2020-02-29", "2021-03-01", "MD") == 0
    #@test datedif("2019-12-31", "2020-01-31", "MD") == 0

    #@test datedif("2024-02-29", "2023-02-28", "D") == #NUM!
    #@test datedif("2024-02-29", "2024-01-28", "M") == #NUM!
    #@test datedif("2024-02-29", "2023-02-29", "Y") == #VALUE!    
end

@testitem "text" begin
    nums = [
        64.16983719,
        719.4682757,
        749.8760207,
        284.6091198,
        447.6473053,
        89.31552312,
        850.0871191,
        451.3678795,
        581.5977343,
        651.2308527,
        344.1675642,
    ]
    results = [
        "04:04:33.93 am",
        "11:14:19.02 am",
        "09:01:28.19 pm",
        "02:37:07.95 pm",
        "03:32:07.18 pm",
        "07:34:21.20 am",
        "02:05:27.09 am",
        "08:49:44.79 am",
        "02:20:44.24 pm",
        "05:32:25.67 am",
        "04:01:17.55 am",
    ]

    for (num, result) in zip(nums, results)
        @test text(num, "hh:mm:ss.00 AM/PM") == result
        @test text(num, "hh:mm:s.00 AM/PM") == replace(result, ":07." => ":7.")
    end

    results = [
        "19000304",
        "19011219",
        "19020118",
        "19001010",
        "19010322",
        "19000329",
        "19020429",
        "19010326",
        "19010803",
        "19011012",
        "19001209",
    ]
    for (num, result) in zip(nums, results)
        @test text(num, "yyyyMMdd") == result
    end

    results = [
        "1900-03-04",
        "1901-12-19",
        "1902-01-18",
        "1900-10-10",
        "1901-03-22",
        "1900-03-29",
        "1902-04-29",
        "1901-03-26",
        "1901-08-03",
        "1901-10-12",
        "1900-12-09",
    ]
    for (num, result) in zip(nums, results)
        @test text(num, "yyyy-mm-dd") == result
    end

    @test concatenate("Hello", " ", "World", " ", XLDate(40000)) == "Hello World 40000"
end

@testitem "rounding" begin
    using XLFunctions: sum, round

    @test sum([1, 2, 3]) == 6
    @test sum(1, 2, 3) == 6.0
    @test sum([1, 2, 3], 4, [5, 6]) == 21

    @test round(1.234, 2) == 1.23
    @test round(1.235, 2) == 1.24
    @test round(1.234, 1) == 1.2
    @test round(1.235, 1) == 1.2
    @test round(1.234, 0) == 1.0
    @test round(1.635, 0) == 2.0
    @test round(1.234) == 1.0
    @test round(1.635) == 2.0
    @test round(123.234, -1) == 120.0

    @test roundup(1.234, 2) == 1.24
    @test roundup(1.235, 2) == 1.24
    @test roundup(1.234, 1) == 1.3
    @test roundup(1.235, 1) == 1.3
    @test roundup(1.234, 0) == 2.0
    @test roundup(1.235, 0) == 2.0
    @test roundup(1.234) == 2.0
    @test roundup(1.235) == 2.0
    @test roundup(123.234, -1) == 130.0

    @test rounddown(1.234, 2) == 1.23
    @test rounddown(1.235, 2) == 1.23
    @test rounddown(1.234, 1) == 1.2
    @test rounddown(1.235, 1) == 1.2
    @test rounddown(1.234, 0) == 1.0
    @test rounddown(1.235, 0) == 1.0
    @test rounddown(1.234) == 1.0
    @test rounddown(1.235) == 1.0
    @test rounddown(123.234, -1) == 120.0

    @test ceiling(3.7, 1) == 4.0
    @test ceiling(3.7, 0.5) == 4.0
    @test ceiling(3.7, 2) == 4.0
    @test ceiling(-3.7, 1) == -3.0
    @test ceiling(-3.7, 0.5) == -3.5
    @test ceiling(-3.7, 2) == -2.0
    @test ceiling(0, 1) == 0.0
    @test ceiling(0, 5) == 0.0
    @test ceiling(-0.3, 0.2) == -0.2
    @test ceiling(10, 2) == 10
    @test ceiling(10, 3) == 12
    @test ceiling(10.5, 0.2) ≈ 10.6 #rounding error
    @test ceiling(-10, 2) == -10
    @test ceiling(-10, 3) == -9
    @test ceiling(-10.5, 0.2) == -10.4
end

@testitem "bool" begin
    # Test for bool with Boolean values
    @test bool(true) == true
    @test bool(false) == false

    # Test for bool with String values
    @test bool("True") == true
    @test bool("true") == true
    @test bool("TrUe") == true
    @test bool("False") == false
    @test bool("false") == false
    @test_throws BoolCastError bool("RandomString")
    @test_throws BoolCastError bool("Trrrrue")

    # Test for bool with XLDate values
    @test bool(XLDate(0)) == false  # Excel's serial date for 0
    @test bool(XLDate(1)) == true   # Excel's serial date for January 1, 1900
    @test bool(XLDate(-1)) == true  # Negative date (if possible)

    # Test for bool with Number values
    @test bool(0) == false
    @test bool(0.0) == false
    @test bool(-0.0) == false
    @test bool(1) == true
    @test bool(-1) == true
    @test bool(1.1) == true
    @test bool(-1.1) == true

    @test bool(missing) === missing
end

@testitem "upper and lower" begin
    # Tests for `upper` function
    @test upper("hello") == "HELLO"
    @test upper("HELLO") == "HELLO"
    @test upper("HelloWorld") == "HELLOWORLD"
    @test upper(5) == "5"
    @test upper(5.0) == "5"
    @test upper(5.5) == "5.5"
    @test upper(:hello) == "HELLO"
    @test upper(true) == "TRUE"
    @test upper(missing) === missing

    # Tests for `lower` function
    @test lower("hello") == "hello"
    @test lower("HELLO") == "hello"
    @test lower("HelloWorld") == "helloworld"
    @test lower(5) == "5"
    @test lower(5.0) == "5"
    @test lower(5.5) == "5.5"
    @test lower(:HELLO) == "hello"
    @test lower(false) == "false"
    @test lower(missing) === missing
    @test lower(28734628300007468732468) == "28734628300007468732468"
end

@testitem "mid, left, right, substitute, concat" begin
    # MID function tests
    @test XLFunctions.mid("OpenAI ChatGPT", 6, 4) == "I Ch"
    @test_throws NegativeStringLengthError mid("Indexing 101", 0, 5)
    @test_throws NegativeStringLengthError mid("Indexing 101", 3, -1)
    @test mid("Unexpected Error", 5.5, 3) == "pec"
    @test mid("Out of Bounds", 14, 10) == ""
    @test mid("Fractional Index", 3.8, 4.2) == "acti"

    # LEFT function tests
    @test left("Hello, World!", 5) == "Hello"
    @test_throws NegativeStringLengthError left("2023-02-27", -1)
    @test left("Partial Text", 0) == ""
    @test left("Fractional", 4.5) == "Frac"
    @test left("Short", 10) == "Short"

    # RIGHT function tests
    @test right("Goodbye, World!", 7) == " World!"
    @test_throws NegativeStringLengthError right("2023-02-27", -2)
    @test right("Final Segment", 0) == ""
    @test right("Nearly There", 5.5) == "There"
    @test right("Brief", 10) == "Brief"

    # Note case sensitive
    @test substitute("Hello, world! World is big.", "world", "Julia") ==
        "Hello, Julia! World is big."
    @test substitute("Hello, world! World is big.", "world", "Julia", 1) ==
        "Hello, Julia! World is big."
    @test substitute("Cat, cat, CAT!", "cat", "dog", 2) == "Cat, cat, CAT!"
    @test substitute("Cat, cat, cat, cat!", "cat", "dog", 3) == "Cat, cat, cat, dog!"
    @test substitute("Bird, bird, bird!", "bird", "duck", 5) == "Bird, bird, bird!"
    @test substitute("bananas banananas", "na", "nana", 2) == "banananas banananas"
    @test_throws ArgumentError substitute("Anything here.", "here", "there", 0)
    @test_throws ArgumentError substitute("There is no spoon.", "fork", "spoon", 0)
    @test substitute("1234 1234", "2", "3", 1) == "1334 1234"
    @test substitute("Special & chars! & more chars!", "&", "and", 1) ==
        "Special and chars! & more chars!"
    @test substitute("Hello, world!", "test", "Julia") == "Hello, world!"
    @test substitute("hello, world!", "WORLD", "Julia", 1) == "hello, world!"

    @test "hello35world" == concat(["hello", 3, 5, "world"])
    @test "OpenAI GPT4 GPT4" == concat(["OpenAI", " ", "GPT", 4, " ", "GPT", 4])
    @test "2024-3-19 Excel" == concat(["2024", "-", 3, "-", 19, " ", "Excel"])
    @test "1.5 and 2 and again 2" == concat([1.5, " and ", 2, " and again ", 2])
    @test "Pi equals 3.14; E equals 2.718; Pi 3.14" ==
        concat(["Pi equals ", 3.14, "; E equals ", 2.718, "; Pi ", 3.14])
    @test "Date: 2024-03-19; Time: 12:00PM serial 45370" == concat(
        ["Date: ", "2024-03-19", "; ", "Time: ", "12:00PM"], " serial ", date(2024, 3, 19)
    )
    @test "FirstSecondThirdFirstSecondThird" ==
        concat(["First", "Second", "Third", "First", "Second", "Third"])
    @test "100200300 - 400500600" == concat([100, 200, 300, " - ", 400, 500, 600])
    @test "100200300 - 400500600and600" ==
        concat([100, 200, 300, " - ", 400, 500, 600], "and", [600])
    @test "Nestedlist with tuples too" ==
        concat([["Nested", "list"], " with ", ("tuples", " too")])
    @test "RepeatRepeatArraysArraysAndStrings" ==
        concat([["Repeat", "Repeat"], ["Arrays", "Arrays"], "And", "Strings"])
end

@testitem "rate" begin
    # Comparison to Excel
    @test rate(60, -200, 10000, 0) ≈ 0.00618341316125379
    @test rate(120, -300, 15000, 5000) ≈ 0.0163743926512608
    @test rate(48, -250, 8000, 1000) ≈ 0.0151344680950013
    @test rate(36, -400, 12000, 0, 1) ≈ 0.0108342374523016
    @test rate(60, -150, 5000, 1000, 0, 0.05) ≈ 0.0191742666276706
    @test rate(240, -1000, 200000, 0) ≈ 0.00156277072090473
    @test rate(360, -1500, 300000, 0, 1) ≈ 0.00368189518394644
    @test rate(180, -2000, 50000, 0) ≈ 0.039965433356609
    @test rate(12, -100, 1000, 0) ≈ 0.0292285407691377
    @test rate(72, -300, 15000, 0, 0, 0.08) ≈ 0.0107162066252848
    @test rate(120, -400, 25000, 0, 1, 0.03) ≈ 0.0125924190994841
    @test rate(84, -350, 12000, 0, 0, 0.07) ≈ 0.025708181166484
    @test rate(60, -200, 10000, 1000) ≈ 0.00348470868557156
    @test rate(48, -100, 5000, 0, 1, 0.06) ≈ -0.00172347009816564
    @test rate(36, -150, 8000, 0, 0, 0.02) ≈ -0.0198750058379085
    @test rate(60, -250, 12000, 0, 1) ≈ 0.0079103059143451
    @test rate(360, -1200, 250000, 0, 0, 0.04) ≈ 0.00337064246159166
    @test rate(240, -800, 150000, 0, 1, 0.05) ≈ 0.00216152997535674
    @test rate(12, -300, 3500, 0, 0, 0.1) ≈ 0.00436081777674966
    @test rate(60, -200, 10000, 0) ≈ 0.00618341316125379
    @test rate(120, 300, -15000, 5000) ≈ 0.018457514020011
    @test rate(48, 250, -8000, -1000) ≈ 0.0151344680950012
    @test rate(36, -400, 12000, 2000, 1) ≈ 0.0022723544992644
    @test rate(60, 150, -5000, -1000, 0, 0.05) ≈ 0.0191742666277084
    @test rate(240, -1000, 200000, -10000) ≈ 0.00185335293215548
    @test rate(360, 1500, -300000, 50000, 1) ≈ 0.00397534279776063
    @test rate(180, -2000, 50000, -5000) ≈ 0.0399689060288228
    @test rate(24, 500, -12000, 3000) ≈ 0.0156905080913063
    @test rate(12, 100, -1000, -200) ≈ -1.29803547364284E-09
    @test rate(72, -300, 15000, -3000, 0, 0.08) ≈ 0.0133056860905425
    @test rate(120, 400, -25000, 10000, 1, 0.03) ≈ 0.0143238026598161
    @test rate(84, -350, 12000, -2000, 0, 0.07) ≈ 0.0263888939219417
    @test rate(60, 200, -10000, 1000) ≈ 0.00840350248811834
    @test rate(48, -100, 5000, -500, 1, 0.06) ≈ 0.00228277799600976
    @test rate(36, 150, -8000, 0, 0, 0.02) ≈ -0.0198750058378295
    @test rate(60, -250, 12000, -2000, 1) ≈ 0.0112769794919453
    @test rate(360, 1200, -250000, 50000, 0, 0.04) ≈ 0.00374547917992404
    @test rate(240, -800, 150000, -10000, 1, 0.05) ≈ 0.00250603712857146
    @test rate(12, 300, -3500, 200, 0, 0.1) ≈ 0.0123295838958103
end