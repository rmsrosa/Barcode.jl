# Get pattern

"""
    get_pattern(encoding::Vector{<:AbstractString}, ::Val{:code128})

Return the binary pattern for a given vector of code128 symbols.

Currently, the `encoding` must start with either `START A`, `START B`, or `START C`
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
function get_pattern(encoding::Vector{<:AbstractString}, ::Val{:code128})

    m = match(r"^START (A|B|C)$", first(encoding))
    m !== nothing || throw(
        ArgumentError(
            "First element of `code` should be either `START A`, `START B` or `START C`",
        ),
    )

    last(encoding) == "STOP" ||
        throw(ArgumentError("Last element of `code` should be `STOP`"))

    count(encoding .== "STOP") == 1 ||
        throw(ArgumentError("""There should be only one "STOP" in the encoding sequence"""))

    count(match.(r"^START [A|B|C]$", encoding) .!== nothing) == 1 ||
        throw("""There should be only one r"START [A|B|C]" in the encoding sequence""")

    subtype = Symbol("code128$(lowercase(m.captures[1]))")
    nextsubtype = subtype

    # initialize binary_pattern with the quiet zone, which is at least 10x, where x is
    # the width of each module, assumed here to be one bit. We use 11x just to have the
    # same length as the other symbols (except the double bar termination symbol).
    quiet_zone = "0"^11
    binary_pattern = [quiet_zone]

    nrow = findfirst(==(first(encoding)), CODE128[:, subtype])
    push!(binary_pattern, CODE128.pattern[nrow])
    chk_sum = CODE128.value[nrow]
    multiplier = 0

    for c in encoding[2:end]

        multiplier += 1

        if c == "CHECKSUM"
            push!(binary_pattern, CODE128.pattern[rem(chk_sum, 103)+1])
            chk_sum += multiplier * chk_sum
        else
            nrow = findfirst(==(c), CODE128[:, nextsubtype])
            nrow === nothing && throw(
                ArgumentError(
                    "$c is not part of subtype $(titlecase(string(nextsubtype))) of Code128",
                ),
            )
            push!(binary_pattern, CODE128.pattern[nrow])
            chk_sum += multiplier * CODE128.value[nrow]

            nextsubtype = subtype
            m = match(r"^Code (A|B|C)$", c)
            if m !== nothing
                subtype = nextsubtype = Symbol("code128$(lowercase(m.captures[1]))")
            end


            m = match(r"^Shift (A|B)$", c)
            if m !== nothing
                nextsubtype = Symbol("code128$(lowercase(m.captures[1]))")
            end

        end
    end
    # "END" bars
    push!(binary_pattern, "11")

    # Quiet zone
    push!(binary_pattern, quiet_zone)

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
    get_pattern(arg, encoding_type::Symbol, args...)

Redirect dispatch according to the given symbol `encoding_type`.
"""
get_pattern(arg, encoding_type::Symbol, args...) =
    get_pattern(arg, Val(encoding_type), args...)
