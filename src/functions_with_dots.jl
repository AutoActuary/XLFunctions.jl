# Excel have a lot of functions with a dot `.` in the name. I'm not sure how to support this.
# Currently we create a object and add properties to the object to mimick the naming convention

struct _Ceiling
    math::Base.Callable
end

function _ceiling(x, significance)
    if significance == 0
        return typeof(x)(0)

    elseif (x > 0 && significance < 0)
        throw(
            ArgumentError(
                "Excel ceiling($x, $significance): number cannot be positive if significance is negative",
            ),
        )
    end

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

struct _Floor
    math::Base.Callable
end

function _floor(x, significance)
    if significance == 0
        throw(ArgumentError("Excel floor($x, $significance): significance cannot be zero"))
    elseif (x > 0 && significance < 0)
        throw(
            ArgumentError(
                "Excel floor($x, $significance): number cannot be positive if significance is negative",
            ),
        )
    end

    return Base.floor(x / significance) * significance
end

function _floor_math(x, significance=1.0, mode=0)
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

    return Base.floor(x / adjusted_significance) * adjusted_significance
end

function (::_Floor)(x, significance)
    return _floor(x, significance)
end

floor = _Floor(_floor_math)
