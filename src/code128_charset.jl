# 

"""
    const CODE128

`CODE128` is a DataFrame with columns `value`, `code128a`, `code128b`, `code128c`, and
`pattern`, containing the values and binary patterns for all three modes (or subtypes)
`code128a`, `code128b` and `code128c` encodings.
"""
const CODE128 = DataFrame(
    value = 0:106,
    code128a = [
        string.(Char(32):Char(95)) # ' ' to '_'
        [ # string.(Char(0):Char(31)) # NUL to US
            "NUL" # Null - Char(0) = \x00
            "SOH" # Start of Header
            "STX" # Start of Text
            "ETX" # End of Text
            "EOT" # End of Transmission
            "ENQ" # Enquiry
            "ACK" # Acknowledge
            "BEL" # Bell
            "BS" # Backspace
            "HT" # Horizontal Tab
            "LF" # Line Feed
            "VT" # Vertical Tab
            "FF" # Form Feed
            "CR" # Carriage Return
            "SO" # Shift Out
            "SI" # Shift In
            "DLE" # Data Link Escape
            "DC1" # Device Control 1
            "DC2" # Device Control 2
            "DC3" # Device Control 3
            "DC4" # Device Control 4
            "NAK" # Negative Acknowledge
            "SYN" # Synchronize
            "ETB" # End of Transmission Block
            "CAN" # Cancel
            "EM" # End of Medium
            "SUB" # Substitute
            "ESC" # Escape
            "FS" # File Separator
            "GS" # Group Separator
            "RS" #	Record Separator
            "US" #	Unit Separator - Char(31)
        ]
        [
            "FNC 3"
            "FNC 2"
            "SHIFT B"
            "CODE C"
            "CODE B"
            "FNC 4"
            "FNC 1"
            "START A"
            "START B"
            "START C"
            "STOP"
        ]
    ],
    code128b = [
        string.(Char(32):Char(126)) # SPACE to ~
        ["DEL", "FNC 3", "FNC 2", "SHIFT A", "CODE C", "FNC 4", "CODE A", "FNC 1"]
        ["START A", "START B", "START C", "STOP"]
    ],
    code128c = [
        string.(0:99, pad = 2)
        ["CODE B", "CODE A", "FNC 1", "START A", "START B", "START C", "STOP"]
    ],
    pattern = [
        "11011001100"
        "11001101100"
        "11001100110"
        "10010011000"
        "10010001100"
        "10001001100"
        "10011001000"
        "10011000100"
        "10001100100"
        "11001001000"
        "11001000100"
        "11000100100"
        "10110011100"
        "10011011100"
        "10011001110"
        "10111001100"
        "10011101100"
        "10011100110"
        "11001110010"
        "11001011100"
        "11001001110"
        "11011100100"
        "11001110100"
        "11101101110"
        "11101001100"
        "11100101100"
        "11100100110"
        "11101100100"
        "11100110100"
        "11100110010"
        "11011011000"
        "11011000110"
        "11000110110"
        "10100011000"
        "10001011000"
        "10001000110"
        "10110001000"
        "10001101000"
        "10001100010"
        "11010001000"
        "11000101000"
        "11000100010"
        "10110111000"
        "10110001110"
        "10001101110"
        "10111011000"
        "10111000110"
        "10001110110"
        "11101110110"
        "11010001110"
        "11000101110"
        "11011101000"
        "11011100010"
        "11011101110"
        "11101011000"
        "11101000110"
        "11100010110"
        "11101101000"
        "11101100010"
        "11100011010"
        "11101111010"
        "11001000010"
        "11110001010"
        "10100110000"
        "10100001100"
        "10010110000"
        "10010000110"
        "10000101100"
        "10000100110"
        "10110010000"
        "10110000100"
        "10011010000"
        "10011000010"
        "10000110100"
        "10000110010"
        "11000010010"
        "11001010000"
        "11110111010"
        "11000010100"
        "10001111010"
        "10100111100"
        "10010111100"
        "10010011110"
        "10111100100"
        "10011110100"
        "10011110010"
        "11110100100"
        "11110010100"
        "11110010010"
        "11011011110"
        "11011110110"
        "11110110110"
        "10101111000"
        "10100011110"
        "10001011110"
        "10111101000"
        "10111100010"
        "11110101000"
        "11110100010"
        "10111011110"
        "10111101110"
        "11101011110"
        "11110101110"
        "11010000100"
        "11010010000"
        "11010011100"
        "11000111010"
    ],
)
