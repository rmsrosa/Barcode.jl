# Get encoding

"""
    get_encoding(code::AbstractString, ::Val{code128}; mode::Symbol)

Return the encoded sequence from the given string `code`, according to the code128 encoding.

If `mode` is either `:code128a`, `:code128b`, or `:code128c`, it returns the encoding
following the corresponding subtype. It throws an `ArgumentError` if the given `code` is not
suitable for encoding with the given subtype.

If `mode` is not given or if it is set to `:auto`, which is the default, then it attempts
to use either of these subtypes or a combination of them. It throws an `ArgumentError` if not
possible to do so.
"""
function get_encoding(code, ::Val{:code128}, mode::Symbol = :auto)
    encoding = String[]
    if mode in (:code128a, :code128b)
        all(x -> string(x) in CODE128[:, mode], code) || throw(
            ArgumentError(
                "The given `code` cannot be encoded in subtype $(titlecase(string(mode)))",
            ),
        )
        push!(encoding, "START $(uppercase(string(mode)[end]))")
        append!(encoding, string.(collect(code)))
        push!(encoding, "CHECKSUM")
        push!(encoding, "STOP")
    elseif mode == :code128c
        (all(isdigit, code) && iseven(length(code))) ||
            throw(ArgumentError("The given `code` cannot be encoded in subtype Code128A"))
        push!(encoding, "START C")
        append!(encoding, [code[j:j+1] for j = 1:2:length(code)])
        push!(encoding, "CHECKSUM")
        push!(encoding, "STOP")
    elseif mode == :auto
        if all(isdigit, code) && iseven(length(code))
            encoding = get_encoding(code, Val(:code128), :code128c)
        elseif all(x -> string(x) in CODE128.code128a, code)
            encoding = get_encoding(code, Val(:code128), :code128a)
        elseif all(x -> string(x) in CODE128.code128b, code)
            encoding = get_encoding(code, Val(:code128), :code128b)
        else
            throw(ArgumentError("mode `:auto` not yet fully implemented"))
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
get_encoding(code, encoding_type::Symbol, args...) =
    get_encoding(code, Val(encoding_type), args...)
