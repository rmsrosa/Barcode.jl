# Encoding and decoding

# Code128 encoding with subtype Code128A
function _get_encoding_code128a(data::AbstractString)
    @inbounds for i = 1:ncodeunits(data)
        codeunit(data, i) ≥ 0x7f && throw(
            ArgumentError(
                "The given `data` contains characters outside the range 0 - 126 and " * 
                "cannot be enncoded in Code128"
            ),
        )
        codeunit(data, i) ≥ 0x60 && throw(
            ArgumentError(
                "The given ascii `data` contains lowercase letters or characters outside " *
                "the range 0 - 95 and cannot be encoded in subtype Code128A"
            )
        )
    end
    
    encoding = ["START A"]
    @inbounds for i = 1:ncodeunits(data)
        if 0x20 ≤ codeunit(data, i) ≤ 0x5f
            push!(encoding, string(data[i]))
        elseif codeunit(data, i) ≤ 0x1f
            push!(encoding, CODE128[codeunit(data, i) + 0x41, :code128a])
        else
            throw(
                ArgumentError(
                    "Char in position $i in `data` cannot be encoded in subtype Code128A"
                )
            )
        end
    end
    append!(encoding, ["CHECKSUM", "STOP"])

    return encoding
end

# Code128 encoding with subtype Code128B
function _get_encoding_code128b(data::AbstractString)
    @inbounds for i = 1:ncodeunits(data)
        codeunit(data, i) ≥ 0x7f && throw(
            ArgumentError(
                "The given `data` contains characters outside the range 0 - 126 and " * 
                "cannot be enncoded in Code128"
            )
        )
        codeunit(data, i) ≤ 0x1f && throw(
            ArgumentError(
                "The given ascii `data` contains symbology characters outside the range " *
                "32 - 127 and cannot be fully encoded in subtype Code128B"
            )
        )
    end

    encoding = [
        "START B"
        string.(collect(data))
        "CHECKSUM"
        "STOP"
    ]
    return encoding
end

# Code128 encoding with subtype Code128C
function _get_encoding_code128c(data::AbstractString)
    all(isdigit, data) || throw(
        ArgumentError(
            "The given `data` contains characters which are not digits and cannot " *
            "be encoded in subtype Code128C"
        )
    )
    iseven(length(data)) || throw(
        ArgumentError(
            "The given `data` contains an odd number of digits and cannot be fully " *
            "encoded in subtype Code128C"
        )
    )

    encoding = [
        "START C"
        [data[j:j+1] for j = 1:2:length(data)]
        "CHECKSUM"
        "STOP"
    ]
    return encoding
end

# Optimized Code128 (actually GS1-128) mixed-subtype encoding following the rules in 
# "GS1 General Specifications, Version 13, Issue 1, Jan-2013, Section 5.4.7.7.
# Use of Start, Code Set, and Shift symbols to Minimize Symbol Length (Informative),
# pages 268 to 269."
function _get_encoding_code128(data)
    maximum(codeunits(data)) ≤ 0x7e || throw(
        ArgumentError(
            "The given `data` contains characters outside the range 0-126 and cannot " *
            "be fully encoded in Code128"
        )
    )
    encoding = String[]

    len_data = length(data)
    are_digits = [isdigit(d) for d in data]

    # Determine start character:
    if (length(are_digits) == 2 && are_digits == [1, 1]) || (
        length(are_digits) ≥ 4 && are_digits[1:4] == [1, 1, 1, 1]
    ) # Determine whether there are enough digits
        subtype = :code128c
    elseif UInt8(first(data)) ≤ 0x1f # check whether it is a symbology element (NUL to US)
        subtype = :code128a
    else
        subtype = :code128b
    end

    push!(encoding, "START $(uppercase(string(subtype)[end]))")
    ind = 1
    nextsubtype = subtype

    while ind ≤ length(data)
        # Determine whether it needs to change or shift subtype
        if nextsubtype == :code128c && (len_data == ind || (len_data > ind && are_digits[ind:ind+1] != [1, 1]))
            if codeunit(data, ind) ≤ 0x1f ||
                    (codeunit(data, ind) ≤ 0x5f && len_data > ind &&
                        0 ≤ codeunit(data, ind+1) ≤ 0x1f)
                push!(encoding, "CODE A")
                nextsubtype = subtype = :code128a
            else
                push!(encoding, "CODE B")
                nextsubtype = subtype = :code128b
            end             
        elseif nextsubtype != :code128c && are_digits[ind] && 
                (
                    (findnext(iszero, are_digits, ind) !== nothing &&
                        iseven(findnext(iszero, are_digits, ind) - ind)) ||
                    (findnext(iszero, are_digits, ind) === nothing &&
                        len_data > ind && isodd(len_data - ind))
                )
            push!(encoding, "CODE C")
            nextsubtype = subtype = :code128c
        elseif nextsubtype != :code128a && codeunit(data, ind) ≤ 0x1f # check for symbology
            if nextsubtype == :code128b &&
                    len_data > ind && 0x60 ≤ codeunit(data, ind+1) ≤ 0x7e
                push!(encoding, "SHIFT A")
                nextsubtype = :code128a
            else
                push!(encoding, "CODE A")
                subtype = nextsubtype = :code128a
            end
        elseif nextsubtype != :code128b && 96 ≤ Int(data[ind]) ≤ 126 # check for lowercase
            if nextsubtype == :code128a && len_data > ind && 0 ≤ Int(data[ind+1]) ≤ 31
                push!(encoding, "SHIFT B")
                nextsubtype = :code128b
            else
                push!(encoding, "CODE B")
                subtype = nextsubtype = :code128b
            end
        end

        # encode data chunk
        if nextsubtype == :code128c
            push!(encoding, string(data[ind:ind+1]))
            ind += 2
        elseif nextsubtype == :code128a
            if codeunit(data, ind) ≤ 0x1f
                push!(encoding, CODE128[codeunit(data, ind) + 65, :code128a])
            else
                push!(encoding, string(data[ind]))
            end
            ind += 1
        else
            push!(encoding, string(data[ind]))
            ind += 1
        end
        nextsubtype = subtype
    end
    append!(encoding, ["CHECKSUM", "STOP"])
    return encoding
end

"""
    get_encoding(data::AbstractString, encoding_type::Symbol)

Return the encoded sequence from the given `data`, following the specifications determined
by the `encoding_type`.

Currently, only Code128 specification is available.

If `encoding_type` is either `:code128a`, `:code128b`, or `:code128c`, it returns the
encoding following the corresponding subtype. If `encoding_type` is `:code128`, it will
return an optimized encoding, possibily mixing different subtypes. This strategy
follows the specifications in "GS1 General Specifications, Version 13, Issue 1, Jan-2013,
Section 5.4.7.7. Use of Start, Code Set, and Shift symbols to Minimize Symbol Length
(Informative), pages 268 to 269."

The `data` needs to be a string of ascii characteres to be encoded, otherwise the method
throws an `ArgumentError`.

# Examples

```jldoctest
julia> encoding = get_encoding("000132", :code128c)
6-element Vector{String}:
 "START C"
 "00"
 "01"
 "32"
 "CHECKSUM"
 "STOP"

 julia> encoding = get_encoding("ABC", :code128a)
 6-element Vector{String}:
  "START A"
  "A"
  "B"
  "C"
  "CHECKSUM"
  "STOP"

julia> encoding = get_encoding("AaBC\x02", :code128)
9-element Vector{String}:
 "START B"
 "A"
 "a"
 "B"
 "C"
 "CODE A"
 "\x02"
 "CHECKSUM"
 "STOP"
```
"""
function get_encoding(data::AbstractString, encoding_type::Symbol)
    if encoding_type == :code128
        return _get_encoding_code128(data)
    elseif encoding_type == :code128a
        return _get_encoding_code128a(data)
    elseif encoding_type == :code128b
        return _get_encoding_code128b(data)
    elseif encoding_type == :code128c
        return _get_encoding_code128c(data)
    else
        throw(
            ArgumentError(
                "Encoding type `$(Meta.quot(mode))` not implemented"
            )
        )
    end
end

function _decode_code128(encoding::Vector{String})
    m = match(r"^START (A|B|C)$", first(encoding))
    m !== nothing || throw(
        ArgumentError(
            "First element of `encoding` should be either `START A`, `START B` or `START C`"
        ),
    )
    subtype = Symbol("code128$(lowercase(m.captures[1]))")
    nextsubtype = subtype    
    data = ""

    for c in encoding
        if nextsubtype == :code128a

        elseif nextsubtype == :code128b

        elseif nextsubtype == :code128c && all(isdigit, c)
            data *= c
        end
    end

end


"""
"""
function decode(encoding::Vector{String}, encoding_type::Symbol)
    if encoding_type in (:code128, :code128a, :code128b, :code128c)
        decoded = _decode_code128(encoding::Vector{String})
    else
        throw(
            ArgumentError(
                "Decoding type `$(Meta.quot(mode))` not implemented"
            )
        )
    end
    return decoded
end