# Get pattern

"""
    get_pattern(code::Vector{<:AbstractString}, ::Val{:code128})

Return the binary pattern for a given vector of code128 symbols.

Currently, the `code` must start with either `START A`, `START B`, or `START C`
and must end with `STOP`.

The checksum must either be already computed or one can add an element `CHECKSUM`
for the check sum to be computed and included at the same index where this directive
appears.

# Example

```jldoctest
julia> binary_pattern = get_pattern(["START C", "00", "01", "32", "CHECKSUM", "STOP"], Val(:code128))
9-element Vector{String}:
 "00000000000"
 "11010011100"
 "11011001100"
 "11001101100"
 "11000110110"
 "11110100010"
 "11000111010"
 "11"
 "00000000000"

julia> binary_pattern = get_pattern(["START A", "A", "B", "C", "CHECKSUM", "STOP"], Val(:code128))
8-element Vector{String}:
 "00000000000"
 "11010000100"
 "10100011000"
 "10001011000"
 "10001000110"
 "11000111010"
 "11"
 "00000000000"
```
"""
function get_pattern(code::Vector{<:AbstractString}, ::Val{:code128})

    match(r"^START [A|B|C]$", first(code)) !== nothing || throw(
        ArgumentError(
            "First element of `code` should be either `START A`, `START B` or `START C`"
        )
    )

    last(code) == "STOP" || throw(
        ArgumentError(
            "Last element of `code` should be `STOP`"
        )
    )

    subtype = Symbol("code128$(lowercase(first(code)[end]))")

    # initialize binary_pattern with the quiet zone, which is at least 10x, where x is
    # the width of each module, assumed here to be one bit. We use 11x just to have the
    # same length as the other symbols (except the double bar termination symbol).
    quiet_zone = ["0"^11]
    binary_pattern = copy(quiet_zone)

    multiplier = 0
    after_start = false
    chk_sum = 0

    for c in code

        # multiplier is 1 for the first START symbol and the subsequent symbol
        if after_start == true
            after_start = false
        else
            multiplier += 1
        end
        if multiplier == 1 && match(r"^START (A|B|C)$", c) !== nothing
            after_start = true
        end

        if c == "CHECKSUM"
            append!(
                binary_pattern,
                CODE128[CODE128[:, :value] .== rem(chk_sum, 103), :pattern]
            )
            chk_sum += multiplier * chk_sum
        else
            row = CODE128[CODE128[:, subtype] .== c, :]
            append!(binary_pattern, row.pattern)
            chk_sum += multiplier * row.value[1]
        end
    end
    # "END" bars
    push!(binary_pattern, "11")

    # Quiet zone
    append!(binary_pattern, quiet_zone)

    return binary_pattern
end

"""
    get_pattern(code::AbstractString, ::Val{:code128}, mode::Symbol = :auto)

Retrieve the bar pattern for the given `code`, according to the encoding Code128.

If `mode` is set to either `:code128a`, `:code128b`, or `:code128c`, it returns the encoding
following the corresponding subtype. It throws an `ArgumentError` if the given `code` is not
suitable for encoding with the given subtype.

If `mode` is not given or if it is set to `:auto`, which is the default, then it attempts
to use either of these subtypes or a combination of them. It throws an `ArgumentError` if
not possible to do so.

The encoding is returned as a vector of string patterns, with each element corresponding
to the encoding of each symbol in `code`, and appended with the proper quiet zones and the
`START`, `STOP`, checksum, and ending bar patterns.
"""
function get_pattern(code::AbstractString, ::Val{:code128}, mode::Symbol = :auto)
    encoding = get_encoding(code, Val(:code128), mode)
    return get_pattern(encoding, Val(:code128))
end

"""
    get_pattern(code, encoding_type::Symbol, args...)

Redirect dispatch according to the given symbol `encoding_type`.
"""
get_pattern(code, encoding_type::Symbol, args...) =
    get_pattern(code, Val(encoding_type), args...)
