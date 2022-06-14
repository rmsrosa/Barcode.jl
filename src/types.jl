"""
    abstract type Barcode end

Abstract supertype for all the barcodes.
"""
abstract type Barcode end

"""
    struct Code128 <: Barcode

Composite type for Code128 barcode.

Fields:
    subtype::Symbol
        Either :code128A, :code128B, :code128C, or just :code128 for the mixed subtypes.
    message::String
        String with the message encoded
    code::Vector{String}
        Encoded message.
"""
struct Code128 <: Barcode
    subtype::Symbol
    message::String
    code::Vector{String}
    
    function Code128(msg::String, encoding_type::Symbol=:code128)
        code = encode(msg, encoding_type)

        a = any(∈(("START A", "CODE A", "SHIFT A")), code)
        b = any(∈(("START B", "CODE B", "SHIFT B")), code)
        c = any(∈(("START C", "CODE C", "SHIFT C")), code)
        subtype = a + b + c > 1 ? :code128 :
            a === true ? :code128a :
            b === true ? :code128b :
            c === true ? :code128c :
            nothing
        new(subtype, msg, code)
    end

    function Code128(code::Vector{String})
        chk_sum = checksum(code, :code128)
        m = match(r"CHECKSUM (\d+)", code[end-1])
        m === nothing || parse(Int, m.captures[1]) == chk_sum || @warn "Code checksum does not match computed checksum; using computed checksum."
        code[end-1] == "CHECKSUM" && (code[end-1] = "$(code[end-1]) $chk_sum")

        msg = decode(code, :code128)

        subtype = any(c -> (startswith("SHIFT", c) | startswith("CODE", c)), code) ? :code128 :
            code[1] == "START A" ? :code128a :
            code[1] == "START B" ? :code128b :
            code[1] == "START C" ? :code128c :
            throw(ArgumentError("Not a valid Code128"))

        new(subtype, msg, code)
    end
end
