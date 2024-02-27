using XLFunctions

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

    @test concatenate("Hello", " ", "World", " ", XLDate(40000)) == "Hello World 2009-07-06"
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

@testitem "mid, left and right" begin
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
end