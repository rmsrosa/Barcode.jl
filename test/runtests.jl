using Barcode
using Test
using FileIO

@testset "Encoding" begin
    @testset "Code128a" begin
        let code = Barcode.encode("A", :code128a)
            @test length(code) == 4
            @test code == [
                "START A",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let code = Barcode.encode("\x02A\x03", :code128a)
            @test length(code) == 6
            @test code == [
                "START A",
                "STX",
                "A",
                "ETX",
                "CHECKSUM",
                "STOP",
            ]
        end
    end

    @testset "Code128b" begin
        let code = Barcode.encode("A", :code128b)
            @test length(code) == 4
            @test code == [
                "START B",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let code = Barcode.encode("aBc", :code128b)
            @test length(code) == 6
            @test code == [
                "START B",
                "a",
                "B",
                "c",
                "CHECKSUM",
                "STOP",
            ]
        end
    end

    @testset "Code128b" begin
        let code = Barcode.encode("A", :code128b)
            @test length(code) == 4
            @test code == [
                "START B",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let code = Barcode.encode("aBc", :code128b)
            @test length(code) == 6
            @test code == [
                "START B",
                "a",
                "B",
                "c",
                "CHECKSUM",
                "STOP",
            ]
        end
    end

    @testset "Code128c" begin
        let code = Barcode.encode("00", :code128c)
            @test length(code) == 4
            @test code == [
                "START C",
                "00",
                "CHECKSUM",
                "STOP",
            ]
        end
        let code = Barcode.encode("012345", :code128c)
            @test length(code) == 6
            @test code == [
                "START C",
                "01",
                "23",
                "45",
                "CHECKSUM",
                "STOP",
            ]
        end
    end

    @testset "Code128 mixed subtypes" begin
        let code = Barcode.encode("\x02Aa\tA0902a93892\x03000a\x04z", :code128)
            @test length(code) == 28
            @test code == [
                "START A",
                "STX",
                "A",
                "SHIFT B",
                "a",
                "HT",
                "A",
                "CODE C",
                "09",
                "02",
                "CODE B",
                "a",
                "9",
                "CODE C",
                "38",
                "92",
                "CODE A",
                "ETX",
                "0",
                "CODE C",
                "00",
                "CODE B",
                "a",
                "SHIFT A",
                "EOT",
                "z",
                "CHECKSUM",
                "STOP",
            ]
        end
    end
end

@testset "Decoding" begin
    for msg in (
        "ABC",
        "abc",
        "0123",
        "\x02ABC\x03",
        "\x02ABcZ\x03",
        "\x02AB012345\x03",
        "A b!\t0012\nZ z@\t0013\nAz `\t9999\naA \x7f\t1357"
    )
        code = Barcode.encode(msg, :code128)
        @test msg == Barcode.decode(code, :code128)
    end
end
@testset "Patterns" begin
    
    @testset "code128 subtypes" begin
        let pattern = Barcode.barcode_pattern("A", :code128a)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10100011000", # A
                "10100011000", # checksum 33 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern("a", :code128b)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010010000", # START B
                "10010110000", # a
                "10010000110", # checksum 66 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern("00", :code128c)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010011100", # START C
                "11011001100", # 00
                "11001100110", # checksum 2 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end
    end

    @testset "code128 auto" begin
        let pattern = Barcode.barcode_pattern("A", :code128)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010010000", # START B
                "10100011000", # A
                "10001011000", # checksum 34 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern("a", :code128)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010010000", # START B
                "10010110000", # a
                "10010000110", # checksum 66 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern("00", :code128)
            @test length(pattern) == 7
            @test pattern == [
                "00000000000", # Quiet zone
                "11010011100", # START C
                "11011001100", # 00
                "11001100110", # checksum 2 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern("\x02A\tB\x07\x03", :code128)
            @test length(pattern) == 12
            @test pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10010000110", # \x02 = STX = Start of Text
                "10100011000", # A
                "10000110100", # \t = Horizontal Tab
                "10001011000", # B
                "10011010000", # \x07 = BEL = Bell
                "10000101100", # \x03 = ETX = End of Text
                "10001100100", # CHECKSUM
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end
    end

    @testset "mixed subtypes" begin

        let pattern = Barcode.barcode_pattern(
                ["START A", "A", "B", "SHIFT B", "a", "A", "CODE C", "00", "CHECKSUM", "STOP"],
                :code128
            )
            @test length(pattern) == 13
            @test pattern == [
                "00000000000", # Quiet zone
                "11010000100", # "START A" (103)
                "10100011000", # "A" (33)
                "10001011000", # "B" (34)
                "11110100010", # "SHIFT B" (98)
                "10010110000", # "a" (65)
                "10100011000", # "A" (33)
                "10111011110", # "CODE C" (99)
                "11011001100", # "00" (0)
                "11000010010", # CHECKSUM (75)
                # ( 103 + 1 * 33 + 2 * 34 + 3 * 98 + 4 * 65 + 5 * 33 + 6 * 99 + 7 * 0 ) % 103
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let pattern = Barcode.barcode_pattern(
                [
                    "START C",
                    "FNC 1",
                    "42",
                    "18",
                    "40",
                    "20",
                    "50",
                    "CODE A",
                    "0",
                    "CHECKSUM",
                    "STOP",
                ],
                :code128,
            )

        end
    end
end

@testset "Images" begin
    @testset "save Images.jl" begin
        let zip = "12.345-678"
            zip = replace(zip, r"\s|\.|\-" => "")
            pattern = Barcode.barcode_pattern(zip, :code128)
            img = Barcode.barcode_img(pattern)
            @test length(pattern) == 10
            @test pattern == [
                "00000000000", # Quiet zone
                "11010011100", # START C
                "10110011100", # 12
                "10001011000", # 34
                "11100010110", # 56
                "11000010100", # 78
                "10001110110", # checksum pattern 47 = 
                # (1 * 105 + 1 * 12 + 2 * 34 + 3 * 56 + 4 * 78) % 103
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
            @test FileIO.save("../img/zipcode_$zip.png", img) === nothing
        end

        let pattern = Barcode.barcode_pattern("CSE370", :code128)
            img = Barcode.barcode_img(pattern)
            @test length(pattern) == 12
            @test pattern == [
                "00000000000" # Quiet zone
                "11010010000" # START B
                "10001000110" # C
                "11011101000" # S
                "10001101000" # E
                "11001011100" # 3
                "10111011110" # CODE C
                "10110000100" # 70
                "10010001100" # CHECKSUM 4
                # (1 * 104 + 1 * 35 + 2 * 51 + 3 * 37 + 4 * 19 + 5 * 99 + 6 * 70) % 103 = 4
                "11000111010" # STOP
                "11" # END
                "00000000000" # Quiet zone
            ]
            @test FileIO.save("../img/CSE370.png", img) === nothing
        end
    end
end
