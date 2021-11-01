# 

"""
This dictionary gives the binary representation of digits and flow control symbols according
to the 128C standard representation.

From `00` to `99`, the key represents the digits in the code, while from `100` to `102`,
the key represents the value of the check symbol. From `START C` onwards, the key is
the character.
"""
const CODE128C = Dict(
    "00" => "11011001100",
    "01" => "11001101100",
    "02" => "11001100110",
    "03" => "10010011000",
    "04" => "10010001100",
    "05" => "10001001100",
    "06" => "10011001000",
    "07" => "10011000100",
    "08" => "10001100100",
    "09" => "11001001000",
    "10" => "11001000100",
    "11" => "11000100100",
    "12" => "10110011100",
    "13" => "10011011100",
    "14" => "10011001110",
    "15" => "10111001100",
    "16" => "10011101100",
    "17" => "10011100110",
    "18" => "11001110010",
    "19" => "11001011100",
    "20" => "11001001110",
    "21" => "11011100100",
    "22" => "11001110100",
    "23" => "11101101110",
    "24" => "11101001100",
    "25" => "11100101100",
    "26" => "11100100110",
    "27" => "11101100100",
    "28" => "11100110100",
    "29" => "11100110010",
    "30" => "11011011000",
    "31" => "11011000110",
    "32" => "11000110110",
    "33" => "10100011000",
    "34" => "10001011000",
    "35" => "10001000110",
    "36" => "10110001000",
    "37" => "10001101000",
    "38" => "10001100010",
    "39" => "11010001000",
    "40" => "11000101000",
    "41" => "11000100010",
    "42" => "10110111000",
    "43" => "10110001110",
    "44" => "10001101110",
    "45" => "10111011000",
    "46" => "10111000110",
    "47" => "10001110110",
    "48" => "11101110110",
    "49" => "11010001110",
    "50" => "11000101110",
    "51" => "11011101000",
    "52" => "11011100010",
    "53" => "11011101110",
    "54" => "11101011000",
    "55" => "11101000110",
    "56" => "11100010110",
    "57" => "11101101000",
    "58" => "11101100010",
    "59" => "11100011010",
    "60" => "11101111010",
    "61" => "11001000010",
    "62" => "11110001010",
    "63" => "10100110000",
    "64" => "10100001100",
    "65" => "10010110000",
    "66" => "10010000110",
    "67" => "10000101100",
    "68" => "10000100110",
    "69" => "10110010000",
    "70" => "10110000100",
    "71" => "10011010000",
    "72" => "10011000010",
    "73" => "10000110100",
    "74" => "10000110010",
    "75" => "11000010010",
    "76" => "11001010000",
    "77" => "11110111010",
    "78" => "11000010100",
    "79" => "10001111010",
    "80" => "10100111100",
    "81" => "10010111100",
    "82" => "10010011110",
    "83" => "10111100100",
    "84" => "10011110100",
    "85" => "10011110010",
    "86" => "11110100100",
    "87" => "11110010100",
    "88" => "11110010010",
    "89" => "11011011110",
    "90" => "11011110110",
    "91" => "11110110110",
    "92" => "10101111000",
    "93" => "10100011110",
    "94" => "10001011110",
    "95" => "10111101000",
    "96" => "10111100010",
    "97" => "11110101000",
    "98" => "11110100010",
    "99" => "10111011110",
    "100" => "10111101110",
    "101" => "11101011110",
    "102" => "11110101110",
    "START C" => "11010011100",
    "STOP" => "11000111010",
    "END" => "11"
)

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
