# These functions are here to access certain properties of a xl serial date without
# having to convert to DateTime. The more implemented here, the faster our underlying
# date calculations

# Arrays for month starts in leap and regular years
const _months_start_leap = [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336]
const _months_start_regular = [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

# Checks if a given year is a leap year
function _is_leap(year::Real)
    year = Base.floor(Int, year)
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
end

# Calculates the year from a serial date
function _year_of_xlserial(xlserial::Real)
    nr_of_days_since_0000_01_00 = Base.floor(Int, xlserial) + 693958
    year_estimate = Base.floor(Int, nr_of_days_since_0000_01_00 / 365.2425)

    leap_years = (
        Base.floor(Int, year_estimate / 4) - Base.floor(Int, year_estimate / 100) +
        Base.floor(Int, year_estimate / 400)
    )

    # Correct estimate by calculating how many days are coming from leap years
    corrected_days = nr_of_days_since_0000_01_00 - leap_years
    year = Base.floor(Int, corrected_days ÷ 365)
    return year
end

# Calculates the serial date of the start of a given year
function _year_to_xlserial(year::Real)
    days_since_0000_01_00_estimate = Base.floor(Int, year) * 365

    prev_year = year - 1
    corrected_days = (
        Base.floor(Int, prev_year / 4) - Base.floor(Int, prev_year / 100) +
        Base.floor(Int, prev_year / 400)
    )

    days_since_0000_01_00 = days_since_0000_01_00_estimate + corrected_days
    xlserial = days_since_0000_01_00 - 693958
    return xlserial
end

# Calculates the year, month, day, and day of the year from a serial date
function _year_month_day_of_xlserial(xlserial::Real)
    year = _year_of_xlserial(xlserial)
    start_of_year = _year_to_xlserial(year)

    leap = _is_leap(year)

    day_of_the_year = Base.floor(Int, xlserial) - start_of_year + 1

    if leap
        month = Base.floor(Int, day_of_the_year / (366 / 12)) + 1

        if day_of_the_year in (31, 244, 305, 366)
            month -= 1
        end

        day = day_of_the_year - _months_start_leap[month] + 1
    else
        month = Base.floor(Int, day_of_the_year / (365 / 12)) + 1

        if day_of_the_year in (31, 365)
            month -= 1
        elseif day_of_the_year in (60, 91, 121, 152, 182)
            month += 1
        end

        day = day_of_the_year - _months_start_regular[month] + 1
    end

    return year, month, day
end
