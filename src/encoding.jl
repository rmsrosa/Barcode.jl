# Get encoding

"""
    get_encoding(data::AbstractString, ::Val{code128}; mode::Symbol)

Return the encoded sequence from the given `data`, following the code128 specifications.

If `mode` is either `:code128a`, `:code128b`, or `:code128c`, it returns the encoding
following the corresponding subtype.

The `data` needs to be a string of ascii characteres to be encoded, otherwise the method
throws an `ArgumentError`.

If `mode` is not given or if it is set to `:auto`, which is the default, the method attempts
to use either of these subtypes or a combination of them. It throws an `ErrorException` if a
proper way is not found. Please, report an issue if this happens.
"""
function get_encoding(data::AbstractString, ::Val{:code128}, mode::Symbol = :auto)
    data = ascii(data) # converts to String - throws error if not all characters are ascii
    encoding = String[]

    if mode in (:code128a, :code128b)
        all(x -> string(x) in CODE128[:, mode], data) || throw(
            ArgumentError(
                "The given `code` cannot be encoded in subtype $(titlecase(string(mode)))",
            ),
        )
        push!(encoding, "START $(uppercase(string(mode)[end]))")
        append!(encoding, string.(collect(data)))
        push!(encoding, "CHECKSUM")
        push!(encoding, "STOP")
    elseif mode == :code128c
        (all(isdigit, data) && iseven(length(data))) ||
            throw(ArgumentError("The given `code` cannot be encoded in subtype Code128A"))
        push!(encoding, "START C")
        append!(encoding, [data[j:j+1] for j = 1:2:length(data)])
        push!(encoding, "CHECKSUM")
        push!(encoding, "STOP")
    elseif mode == :auto
        if all(isdigit, data) && iseven(length(data))
            encoding = get_encoding(data, Val(:code128), :code128c)
        elseif all(x -> string(x) in CODE128.code128a, data)
            encoding = get_encoding(data, Val(:code128), :code128a)
        elseif all(x -> string(x) in CODE128.code128b, data)
            encoding = get_encoding(data, Val(:code128), :code128b)
        else
            encoding = get_encoding_mixed(data, Val(:code128))
        end
    else
        throw(ArgumentError("mode `$(Meta.quot(mode))` not implemented"))
    end
    return encoding
end

"""
    get_encoding(code, encoding_type::Symbol, args...)

Redirect dispatch according to the given symbol `encoding_type`.
"""
get_encoding(data, encoding_type::Symbol, args...) =
    get_encoding(data, Val(encoding_type), args...)

function get_encoding_mixed(data, ::Val{:code128})
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
