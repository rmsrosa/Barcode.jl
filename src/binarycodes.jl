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
    binarycode: Vector{String} 
        A Vector with eight elements de 8 strings, cada string representando um 
        caracter do code 128 na representação binária, que
        é uma string com 11 digitos 1 ou 0, sendo 1 indicando
        a presença da barra e 0 a ausência. 
"""
function get_code128c(code::AbstractString)    

    code = replace(code, r"\s|\.|\-" => "")
    if !all(isdigit, code)
        throw(ArgumentError("`code` must be composed only of digits"))
    end
    if rem(length(code), 2) != 0
        throw(ArgumentError("`code` must have even length."))
    end

    # Begins with "START C" code
    binarycode = Vector{String}()
    push!(binarycode, CODE128C["START C"])

    # Start summation (with the value of "START C", which is 105) for the check symbol
    chk_sum = 105
    # start multiplier (weight) for the check symbol
    i = 0

    # Barras do CEP e somatório com peso para o código verificador
    for j in 1:2:length(code)
        s = code[j:j+1]
        push!(binarycode, CODE128C[s])
        # increase multiplier and value for the check symbol
        i += 1
        chk_sum += i * parse(Int, s)
    end

    # Verication digit bar
    chk_sum = rem(chk_sum, 103)
    if chk_sum < 10
        chk_sum_str = "0" * string(chk_sum)
    else
        chk_sum_str = string(chk_sum)
    end
    push!(binarycode, CODE128C[chk_sum_str])

    # "STOP" bar
    push!(binarycode, CODE128C["STOP"])

    # "END" bar
    push!(binarycode, CODE128C["END"])

    return binarycode
end
