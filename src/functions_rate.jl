function rate(
    nper, pmt, pv, fv=0.0, type=0, guess=nothing; tol=1e-11, max_iter=200
)::Float64
    if type != 0 && type != 1
        error("type must be 0 (end of period) or 1 (beginning of period)")
    end

    rate = guess === nothing ? _heuristic_rate_guess(nper, pmt, pv, fv) : guess

    for i in 1:max_iter
        new_rate = _f_rate_newton_step(rate, nper, pmt, pv, fv, type)

        if abs(new_rate - rate) < tol
            return new_rate
        end

        rate = new_rate
    end

    println(max_iter)
    return rate
end

function _heuristic_rate_guess(nper, pmt, pv, fv)
    if pv - fv == 0
        return 0.0
    else
        return (pmt * nper + (pv + fv)) / (-(pv + fv) * nper)
    end
end

function _f_rate(rate, nper, pmt, pv, fv=0.0, type=0)
    if rate == 0.0
        return pv + pmt * nper + fv
    else
        return pv * (1 + rate)^nper +
               pmt * (1 + rate * type) * ((1 + rate)^nper - 1) / rate +
               fv
    end
end

function _f_rate_derivative(rate, nper, pmt, pv, fv=0.0, type=0)
    if rate == 0.0
        return pmt * nper
    else
        return pv * nper * (1 + rate)^(nper - 1) +
               pmt * (1 + rate * type) * ((1 + rate)^nper - 1) / rate +
               pmt * nper * (1 + rate * type) * (1 + rate)^(nper - 1)
    end
end

function _f_rate_newton_step(rate_guess, nper, pmt, pv, fv, type)
    f_value = _f_rate(rate_guess, nper, pmt, pv, fv, type)
    f_prime = _f_rate_derivative(rate_guess, nper, pmt, pv, fv, type)
    return rate_guess - f_value / f_prime
end
