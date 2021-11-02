# 

"""
Recebe uma string com 8 dígitos e retorna uma lista 
com a representação binária dos dígitos de acordo 
com o conjunto C de caracteres do padrão code 128
de código de barras (code128 START C).

# Input
    `code`: string
        string with eight digits representing a zip code. If there is a dash, the dash will
        be stripped out of the string.

# Output
    binary_pattern: Vector{String} 
        A Vector with eight elements de 8 strings, cada string representando um 
        caracter do code 128 na representação binária, que
        é uma string com 11 digitos 1 ou 0, sendo 1 indicando
        a presença da barra e 0 a ausência. 
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

function get_code128(code::AbstractString, mode::Symbol = :auto)
    binary_pattern = Vector{String}()
    if mode == :code128c
        # Begins with "START C" code
        append!(binary_pattern, CHARSET[CHARSET.code128c .== "START C", :pattern])

        # Start summation (with the value of "START C", which is 105) for the check symbol
        chk_sum = 105
        # start multiplier (weight) for the check symbol
        multiplier = 0

        # get code and auxiliary variables for the code128c encoding 
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
    else
        throw(ArgumentError("mode `$(Meta.quot(mode))` not implemented"))
    end
    return binary_pattern
end
