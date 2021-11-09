# Get pattern

function _barcode_pattern_code128(encoding::Vector{<:AbstractString})

    m = match(r"^START (A|B|C)$", first(encoding))
    m !== nothing || throw(
        ArgumentError(
            "First element of `encoding` should be either `START A`, `START B` or `START C`",
        ),
    )

    last(encoding) == "STOP" ||
        throw(ArgumentError("Last element of `encoding` should be `STOP`"))

    count(encoding .== "STOP") == 1 ||
        throw(ArgumentError("""There should be only one "STOP" in the encoding sequence"""))

    count(match.(r"^START [A|B|C]$", encoding) .!== nothing) == 1 ||
        throw(
            ArgumentError(
                "There should be only one r\"START [A|B|C]\" in the encoding sequence"
            )
        )

    subtype = Symbol("code128$(lowercase(m.captures[1]))")
    nextsubtype = subtype

    # initialize pattern with the quiet zone, which is at least 10x, where x is
    # the width of each module, assumed here to be one bit. We use 11x just to have the
    # same length as the other symbols (except the double bar termination symbol).
    quiet_zone = "0"^11
    pattern = [quiet_zone]

    nrow = findfirst(==(first(encoding)), CODE128[:, subtype])
    push!(pattern, CODE128.pattern[nrow])
    chk_sum = CODE128.value[nrow]
    multiplier = 0

    for c in encoding[2:end]

        multiplier += 1

        if c == "CHECKSUM"
            push!(pattern, CODE128.pattern[rem(chk_sum, 103)+1])
            chk_sum += multiplier * chk_sum
        else
            nrow = findfirst(==(c), CODE128[:, nextsubtype])
            nrow === nothing && throw(
                ArgumentError(
                    "$c is not part of subtype $(titlecase(string(nextsubtype))) of Code128",
                ),
            )
            push!(pattern, CODE128.pattern[nrow])
            chk_sum += multiplier * CODE128.value[nrow]

            nextsubtype = subtype
            m = match(r"^CODE (A|B|C)$", c)
            if m !== nothing
                subtype = nextsubtype = Symbol("code128$(lowercase(m.captures[1]))")
            end


            m = match(r"^SHIFT (A|B)$", c)
            if m !== nothing
                nextsubtype = Symbol("code128$(lowercase(m.captures[1]))")
            end

        end
    end
    # "END" bars
    push!(pattern, "11")

    # Quiet zone
    push!(pattern, quiet_zone)

    return pattern
end

"""
    barcode_pattern(encoding::Vector{<:AbstractString}, encoding_type::Symbol)

Return the binary pattern for a given vector, following the specifications determined
    by the `encoding_type`.

Currently, only Code128 specification is available.

If `encoding_type` is either `:code128a`, `:code128b`, or `:code128c`, it returns the
encoding following the corresponding subtype. If `encoding_type` is `:code128`, it will
return an optimized encoding, possibily mixing different subtypes. This strategy
follows the specifications in "GS1 General Specifications, Version 13, Issue 1, Jan-2013,
Section 5.4.7.7. Use of Start, Code Set, and Shift symbols to Minimize Symbol Length
(Informative), pages 268 to 269."

In this case of a Vector argument, it is assumed that `encoding` starts with either
`START A`, `START B`, or `START C` and that it ends with `STOP`.

The checksum must either be already computed or one can add an element `CHECKSUM`
for the check sum to be computed and included where this directive appears.

# Examples

```jldoctest
julia> pattern = barcode_pattern(
       ["START C", "00", "01", "32", "CHECKSUM", "STOP"],
       :code128
       )
9-element Vector{String}:
 "00000000000"
 "11010011100"
 "11011001100"
 "11001101100"
 "11000110110"
 "10111101110"
 "11000111010"
 "11"
 "00000000000"

julia> pattern = barcode_pattern(
    ["START A", "A", "B", "C", "CHECKSUM", "STOP"],
    :code128
    )
9-element Vector{String}:
 "00000000000"
 "11010000100"
 "10100011000"
 "10001011000"
 "10001000110"
 "11011001100"
 "11000111010"
 "11"
 "00000000000"
```
"""
function barcode_pattern(encoding::Vector{<:AbstractString}, encoding_type::Symbol)
    if encoding_type in (:code128, :code128a, :code128b, :code128c)
        pattern = _barcode_pattern_code128(encoding)
    else
        throw(
            ArgumentError(
                "Pattern encoding for encoding type `$encoding_type` not implemented"
            )
        )
    end
    return pattern
end

"""
    barcode_pattern(msg::AbstractString, encoding_type::Symbol)

Retrieve the binary pattern for the given `msg`, according to the encoding Code128.

If `mode` is set to either `:code128a`, `:code128b`, or `:code128c`, it returns the encoding
following the corresponding subtype. It throws an `ArgumentError` if the given `msg` is not
suitable for encoding with the given subtype.

If `mode` is not given or if it is set to `:auto`, which is the default, then it attempts
to use either of these subtypes or a combination of them. It throws an `ArgumentError` if
not possible to do so.

The encoding is returned as a vector of string patterns, with each element corresponding
to the encoding of each symbol in `code`, and appended with the proper quiet zones and the
`START`, `STOP`, checksum, and ending bar patterns.
"""
function barcode_pattern(msg::AbstractString, encoding_type::Symbol)
    encoding = encode(msg, encoding_type)
    return barcode_pattern(encoding, encoding_type)
end

function _barcode_depattern_code128(pattern::AbstractString)

    all(d -> d in ('0', '1'), pattern) || throw(
        ArgumentError(
            "A barcode pattern should be made of 0's and 1's only"
        )
    )

    firstbar = findfirst(==('1'), pattern)
    lastbar = findlast(==('1'), pattern)
    lastbar - firstbar ≥ 34 || throw(
        ArgumentoError(
            "Barcode pattern is too short to be a Code128 barcode pattern"
        )
    )
    pattern[lastbar-1:lastbar] == "11" || throw(
        ArgumentError(
            "Barcode pattern does not end properly with a double bar"
        )
    )
    rem(lastbar - firstbar - 1, 11) == 0 || throw(
        ArgumentError(
            "Barcode pattern contents should have a length multiple of 11"
        )
    )
    
    patterns = [pattern[i:i+10] for i in firstbar:11:lastbar-2]

    first(patterns) in CODE128[104:106, :pattern] || throw(
        ArgumentError(
            "Barcode pattern should start with a pattern for either `START A`, " *
            "`START B`, or `START C`" 
        )
    )

    last(patterns) == CODE128[107, :pattern] || throw(
        ArgumentError(
            "Barcode pattern should end with the pattern for `STOP`"
        )
    )

    count(patterns .== CODE128[107, :pattern]) == 1 ||
        throw(ArgumentError("There should be only one pattern for \"STOP\""))

    count([p in CODE128[104:106, :pattern] for p in patterns]) == 1 ||
        throw(ArgumentError("There should be only one pattern for r\"START [A|B|C]\""))

    # initialize code with the subtype START code
    code = CODE128.code128a[CODE128[:, :pattern] .== first(patterns)]
    nextsubtype = subtype = Symbol("code128$(lowercase(first(code)[end]))")

    nrow = findfirst(==(first(code)), CODE128[:, subtype])
    chk_sum = CODE128.value[nrow]
    multiplier = 0

    for p in patterns[2:end-2] # skip START [A|B|C] and stops before CHECKSUM and STOP

        multiplier += 1

        nrow = findfirst(==(p), CODE128[:, :pattern])
        nrow === nothing && throw(
            ArgumentError(
                "$p is not a valid CODE128 pattern",
            ),
        )
        push!(code, CODE128[nrow, nextsubtype])
        chk_sum += multiplier * CODE128.value[nrow]

        nextsubtype = subtype

        p == CODE128.pattern[99] && (
            (subtype == :code128a && (nextsubtype = :code128b)) ||
            (subtype == :code128b && (nextsubtype = :code128a))
        )
        p == CODE128.pattern[100] && subtype in (:code128a, :code128b) &&
            (subtype = nextsubtype = :code128c)
        p == CODE128.pattern[101] && subtype in (:code128a, :code128c) &&
            (subtype = nextsubtype = :code128b)
        p == CODE128.pattern[102] && subtype in (:code128b, :code128c) &&
            (subtype = nextsubtype = :code128a)
    end

    push!(code, "CHECKSUM")
    push!(code, "STOP")

    return code
end

function barcode_depattern(pattern::AbstractString, encoding_type::Symbol)
    encoding_type == :code128 || throw(
        ArgumentError(
            "Decoding type `$(Meta.quot(mode))` not implemented"
        )
    )
    encoding_type == :code128 && (code = _barcode_depattern_code128(pattern))

    return code
end

barcode_depattern(pattern::Vector{<:AbstractString}, encoding_type::Symbol) =
    barcode_depattern(prod(pattern), encoding_type)
    
function barcode_decode(pattern::AbstractString, encoding_type::Symbol)
    encoding_type == :code128 || throw(
        ArgumentError(
            "Decoding type `$(Meta.quot(mode))` not implemented"
        )
    )
    encoding_type == :code128 && (code = _barcode_depattern_code128(pattern))
    
    msg = decode(code, encoding_type)

    return msg
end

barcode_decode(pattern::Vector{<:AbstractString}, encoding_type::Symbol) =
    barcode_decode(prod(pattern), encoding_type)
