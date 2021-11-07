# Get encoding

# Code128 encoding with subtype Code128A
function _get_encoding_code128a(data::AbstractString)
    @inbounds for i = 1:ncodeunits(data)
        codeunit(data, i) ≥ 127 && throw(
            ArgumentError(
                "The given `data` is not fully ASCII and cannot be encoded in Code128A"
            ),
        )
        codeunit(data, i) ≥ 96 && throw(
            ArgumentError(
                "The given ascii `data` contains lowercase letters or characters outside " *
                "the range 0 - 95 and cannot be encoded in subtype Code128A"
            )
        )
    end
    
    encoding = [
        "START A"
        string.(collect(data))
        "CHECKSUM"
        "STOP"
    ]
    return encoding
end

# Code128 encoding with subtype Code128B
function _get_encoding_code128b(data::AbstractString)
    @inbounds for i = 1:ncodeunits(data)
        codeunit(data, i) ≥ 127 && throw(
            ArgumentError(
                "The given `data` is not fully ASCII and cannot be encoded in Code128A"
            )
        )
        codeunit(data, i) ≤ 31 && throw(
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
    @inbounds for i = 1:ncodeunits(data)
        codeunit(data, i) ≥ 127 && throw(
            ArgumentError(
                "The given `data` is not fully ASCII and cannot be encoded in Code128A"
            )
        )
        codeunit(data, i) ≤ 31 && throw(
            ArgumentError(
                "The given ascii `data` contains symbology characters outside the range " *
                "32 - 127 and cannot be fully encoded in subtype Code128B"
            )
        )
    end

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
    isascii(data) || throw(
        ArgumentError(
            "The given `data` is not fully ASCII and cannot be encoded in Code128A"
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
    elseif 0 ≤ Int(first(data)) ≤ 31 # check whether it is a symbology element (NUL to US)
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
            if 0 ≤ Int(data[ind]) ≤ 31 ||
                    (Int(data[ind]) ≤ 95 && len_data > ind && 0 ≤ Int(data[ind+1]) ≤ 31)
                push!(encoding, "CODE A")
                nextsubtype = subtype = :code128a
            else
                push!(encoding, "CODE B")
                nextsubtype = subtype = :code128b
            end             
        elseif nextsubtype != :code128c && are_digits[ind] && 
                (
                    (findnext(iszero, are_digits, ind) !== nothing && iseven(findnext(iszero, are_digits, ind) - ind)) ||
                    (findnext(iszero, are_digits, ind) === nothing && len_data > ind && isodd(len_data - ind))
                )
            push!(encoding, "CODE C")
            nextsubtype = subtype = :code128c
        elseif nextsubtype != :code128a && 0 ≤ Int(data[ind]) ≤ 31 # check for symbology
            if nextsubtype == :code128b && len_data > ind && 96 ≤ Int(data[ind+1]) ≤ 126
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
            push!(encoding, data[ind:ind+1])
            ind += 2
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
