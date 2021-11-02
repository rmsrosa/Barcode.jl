# 

"""
Returns a vector of patterns associated with each character of `code`, according to
the code128 subtype specified by `mode`, which can be either `:code128a`, `:code128b`,
or `:code128c`. It also updates the given multiplier and the check_sum addition for
the `code`. This method does not add the START and STOP symbols, only the patterns of
the given "chunk" `code`.
"""
function get_code128_chunk(code::AbstractString, mode, multiplier = 0)

    if mode in (:code128a, :code128b) && !all(x -> string(x) in CHARSET[:, mode], code)
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

        # get CHARSET row for this iteration
        s = code[j:j + step - 1]
        row = CHARSET[CHARSET[:, mode] .== s, :]

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
    binary_pattern = Vector{String}()

    # start multiplier (weight) for the check symbol
    multiplier = 0

    if mode == :auto
        if all(isdigit, code)
            mode = :code128c
        elseif all(x -> string(x) in CHARSET.code128a, code)
            mode = :code128a
        elseif all(x -> string(x) in CHARSET.code128b, code)
            mode = :code128b
        elseif all(x -> string(x) in [CHARSET.code128a; CHARSET.code128b], code)
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
    if mode == :code128a
        # Begins with "START A" code
        append!(binary_pattern, CHARSET[CHARSET[:, mode] .== "START A", :pattern])

        # Start summation for the check pattern with the value of "START A", which is 103
        chk_sum = 103
    elseif mode == :code128b
        # Begins with "START B" code
        append!(binary_pattern, CHARSET[CHARSET[:, mode] .== "START B", :pattern])

        # Start summation for the check pattern with the value of "START B", which is 104
        chk_sum = 104
    elseif mode == :code128c
        # Begins with "START C" code
        append!(binary_pattern, CHARSET[CHARSET[:, mode] .== "START C", :pattern])

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
    append!(binary_pattern, CHARSET[CHARSET.code128c .== chk_sum_str, :pattern])

    # "STOP" bar
    append!(binary_pattern, CHARSET[CHARSET.code128c .== "STOP", :pattern])

    # "END" bar
    push!(binary_pattern, "11")

    return binary_pattern
end
