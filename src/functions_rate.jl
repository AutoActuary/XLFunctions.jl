function rate(
    nper, pmt, pv, fv=0.0, type=0, guess=nothing; tol=1e-11, max_iter=150
)::Float64
    if type != 0 && type != 1
        error("type must be 0 (end of period) or 1 (beginning of period)")
    end

    fv == pv && return NaN

    current_rate = if guess !== nothing
        guess
    else
        _rate_guess(nper, pmt, pv, fv)
    end

    for _ in 1:max_iter
        new_rate = _f_rate_newton_step(current_rate, nper, pmt, pv, fv, type)

        if abs(new_rate - current_rate) < tol
            return new_rate
        end

        current_rate = new_rate
    end

    return if abs(_pv(current_rate, nper, pmt, fv, type) - pv) / max(1, abs(pv)) > 1e-6
        NaN
    else
        # pv error less than 6 significant digits
        current_rate
    end
end

function _rate_guess(nper, pmt, pv, fv)::Float64
    return max(
        -Inf,
        (pmt * nper + (pv + fv)) / (-(pv + fv) * nper) *
        (1 + (pv - fv) / (pv + fv) * 1 / (2 * nper)),
    )
end

function _f_rate(rate, nper, pmt, pv, fv, type)::Float64
    if rate == 0.0
        return pv + pmt * nper + fv
    else
        return pv * (1 + rate)^nper +
               pmt * (1 + rate * type) * ((1 + rate)^nper - 1) / rate +
               fv
    end
end

function _pv(rate, nper, pmt, fv, type)::Float64
    if rate == 0.0
        return -(pmt * nper + fv)
    else
        return -(
            pmt * (1 + rate * type) * (1 - (1 + rate)^(-nper)) / rate + fv / (1 + rate)^nper
        )
    end
end

function _f_rate_derivative(rate, nper, pmt, pv, fv, type)::Float64
    if rate == 0.0
        return pmt * nper
    else
        return pv * nper * (1 + rate)^(nper - 1) +
               pmt * (1 + rate * type) * ((1 + rate)^nper - 1) / rate +
               pmt * nper * (1 + rate * type) * (1 + rate)^(nper - 1)
    end
end

function _f_rate_newton_step(rate_guess, nper, pmt, pv, fv, type)::Float64
    f_value = _f_rate(rate_guess, nper, pmt, pv, fv, type)
    f_prime = _f_rate_derivative(rate_guess, nper, pmt, pv, fv, type)
    return max(-Inf, rate_guess - f_value / f_prime)
end
