struct BoolCastError <: Exception
    msg::String
end

function bool(x::Bool)
    return x
end

function bool(x::AbstractString)
    if lowercase(x) in ("true", "false")
        return lowercase(x) == "true"
    else
        len = ncodeunits(x)
        xmsg = len > 20 ? x[0:nextind(x, 0, 17)] * "..." : x

        throw(BoolCastError("Cannot convert string of $(repr(xmsg)) to Bool"))
    end
end

function bool(x::XLDate)
    return x.val != 0
end

function bool(x::Number)
    return x != 0
end
