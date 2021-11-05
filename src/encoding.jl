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
            throw(ErrorException("mode `:auto` not yet fully implemented"))
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
