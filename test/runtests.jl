using XLFunctions

@testitem "xldate" begin
    using Dates: Dates, DateTime

    # Does it display like truncated ISO 8601?
    @test repr(XLDate(32937.0)) == "XLDate(\"1990-03-05\")"
    @test repr(XLDate(32937)) == "XLDate(\"1990-03-05\")"
    @test repr(XLDate(32937.12345)) == "XLDate(\"1990-03-05T02:57:46.079\")"
    @test string(date(1910, 5, 5)) == "1910-05-05"
    @test "$(date(1910, 5, 5))" == "1910-05-05"

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
end
