# 

"""
Return a vector of patterns associated with each character of `code`, according to
the code128 subtype specified by `mode`, which can be either `:code128a`, `:code128b`,
or `:code128c`. It also updates the given multiplier and the check_sum addition for
the `code`. This method does not add the START and STOP symbols, only the patterns of
the given "chunk" `code`.
"""
function get_code128_chunk(code::AbstractString, mode, multiplier = 0)

    if mode in (:code128a, :code128b) && !all(x -> string(x) in CODE128[:, mode], code)
        throw(
            ArgumentError(
                "Some or all characters in `code` cannot be encoded in `$(Meta.quot(mode))`"
            )
        )
    end
    if mode == :code128c && !all(isdigit, code)
        throw(
            ArgumentError(
                "`code` must be composed only of digits for code128c encoding."
            )
        )
    end

    if mode == :code128c && rem(length(code), 2) != 0
        throw(ArgumentError("`code` must have even length for code128c encoding."))
    end

    # Initialization
    binary_pattern = Vector{String}()
    chk_sum = 0

    if mode == :code128c
        step = 2
    else
        step = 1
    end

    # Iterate code and uptade binary_pattern, multiplier and check sum
    for j in 1:step:length(code)

        # get CODE128 row for this iteration
        s = code[j:j + step - 1]
        row = CODE128[CODE128[:, mode] .== s, :]

        # update binary_pattern
        append!(binary_pattern, row.pattern)
        # increase multiplier
        multiplier += 1
        # update check sum
        chk_sum += multiplier * row.value[1]
    end

    return binary_pattern, chk_sum, multiplier
end

"""
    get_code128(code::AbstractString, mode::Symbol = :auto)

Encode the given `code` according to `mode`, which can be either `:code128a`, `:code128b`,
`:code128c`, or `:auto`. This is the full encoding; it includes the appropriate START
and STOP and END patterns.

The mode `:auto` is not fully implemented. It is able to detect whether `code` can be
encoded in either of the other modes and encode it accordingly, but it does not yet
implement mixed encoding.

The encoding is returned as a vector of string patterns, with each element corresponding
to the encoding of each symbol in `code`.
"""
function get_code128(code::AbstractString, mode::Symbol = :auto)

    if mode == :auto
        if all(isdigit, code)
            mode = :code128c
        elseif all(x -> string(x) in CODE128.code128a, code)
            mode = :code128a
        elseif all(x -> string(x) in CODE128.code128b, code)
            mode = :code128b
        elseif all(x -> string(x) in [CODE128.code128a; CODE128.code128b], code)
            throw(
                ErrorException(
                    "This `code` requires mixing different modes/subtypes " * 
                    "of code128, but this has not been implemented yet"
                )
            )
        else
            throw(
                ArgumentError("This `code` cannot be encoded in code128")
            )
        end
    end

    # initialize binary_pattern with the quiet zone, which is at least 10x, where x is
    # the width of each module, assumed here to be one bit. We use 11x just to have the
    # same extend as (most of) the other symbols.
    quiet_zone = ["0"^11]
    binary_pattern = copy(quiet_zone)

    # start multiplier (weight) for the check symbol
    multiplier = 0

    if mode == :code128a
        # Begins with "START A" code
        append!(binary_pattern, CODE128[CODE128[:, mode] .== "START A", :pattern])

        # Start summation for the check pattern with the value of "START A", which is 103
        chk_sum = 103
    elseif mode == :code128b
        # Begins with "START B" code
        append!(binary_pattern, CODE128[CODE128[:, mode] .== "START B", :pattern])

        # Start summation for the check pattern with the value of "START B", which is 104
        chk_sum = 104
    elseif mode == :code128c
        # Begins with "START C" code
        append!(binary_pattern, CODE128[CODE128[:, mode] .== "START C", :pattern])

        # Start summation for the check pattern with the value of "START B", which is 105
        chk_sum = 105
    else
        throw(ArgumentError("mode `$(Meta.quot(mode))` not implemented"))
    end 

    # get code and auxiliary variables for the encoding 
    bc, cs, = get_code128_chunk(code, mode, multiplier)

    # update binary_pattern and check sum
    append!(binary_pattern, bc)
    chk_sum += cs

    # Check sum binary_pattern
    chk_sum = rem(chk_sum, 103)
    if chk_sum < 10
        chk_sum_str = "0" * string(chk_sum)
    else
        chk_sum_str = string(chk_sum)
    end
    append!(binary_pattern, CODE128[CODE128.code128c .== chk_sum_str, :pattern])

    # "STOP" bar
    append!(binary_pattern, CODE128[CODE128.code128c .== "STOP", :pattern])

    # "END" bar
    push!(binary_pattern, "11")

    # Finish with another quiet zone
    append!(binary_pattern, quiet_zone)

    return binary_pattern
end
