using Barcode
using Test

@testset "Encoding" begin
    @testset "Code128a" begin
        let encoding = Barcode.get_encoding("A", :code128, :code128a)
            @test length(encoding) == 4
            @test encoding == [
                "START A",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let encoding = Barcode.get_encoding("\x01A\x02", :code128, :code128a)
            @test length(encoding) == 6
            @test encoding == [
                "START A",
                "\x01",
                "A",
                "\x02",
                "CHECKSUM",
                "STOP",
            ]
        end
    end

    @testset "Code128b" begin
        let encoding = Barcode.get_encoding("A", :code128, :code128b)
            @test length(encoding) == 4
            @test encoding == [
                "START B",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let encoding = Barcode.get_encoding("aBc", :code128, :code128b)
            @test length(encoding) == 6
            @test encoding == [
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
        let encoding = Barcode.get_encoding("A", :code128, :code128b)
            @test length(encoding) == 4
            @test encoding == [
                "START B",
                "A",
                "CHECKSUM",
                "STOP",
            ]
        end
        let encoding = Barcode.get_encoding("aBc", :code128, :code128b)
            @test length(encoding) == 6
            @test encoding == [
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
        let encoding = Barcode.get_encoding("00", :code128, :code128c)
            @test length(encoding) == 4
            @test encoding == [
                "START C",
                "00",
                "CHECKSUM",
                "STOP",
            ]
        end
        let encoding = Barcode.get_encoding("012345", :code128, :code128c)
            @test length(encoding) == 6
            @test encoding == [
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
        let encoding = Barcode.get_encoding("\x01Aa\x09A0902a93892\x02000a\x03z", :code128)
            @test length(encoding) == 28
            @test encoding == [
                "START A",
                "\x01",
                "A",
                "SHIFT B",
                "a",
                "\t",
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
                "\x02",
                "0",
                "CODE C",
                "00",
                "CODE B",
                "a",
                "SHIFT A",
                "\x03",
                "z",
                "CHECKSUM",
                "STOP",
            ]
        end
    end
end

@testset "Patterns" begin
    
    @testset "code128 subtypes" begin
        let binary_pattern = Barcode.get_pattern("A", :code128, :code128a)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10100011000", # A
                "10100011000", # checksum 33 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let binary_pattern = Barcode.get_pattern("a", :code128, :code128b)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010010000", # START B
                "10010110000", # a
                "10010000110", # checksum 66 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let binary_pattern = Barcode.get_pattern("00", :code128, :code128c)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
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
        let binary_pattern = Barcode.get_pattern("A", :code128)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10100011000", # A
                "10100011000", # checksum 33 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let binary_pattern = Barcode.get_pattern("a", :code128)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010010000", # START B
                "10010110000", # a
                "10010000110", # checksum 66 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let binary_pattern = Barcode.get_pattern("00", :code128)
            @test length(binary_pattern) == 7
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010011100", # START C
                "11011001100", # 00
                "11001100110", # checksum 2 pattern
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end

        let binary_pattern = Barcode.get_pattern("\x02A\tB\x07\x03", :code128)
            @test length(binary_pattern) == 12
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10010000110", # \x02 = STX = Start of Text
                "10100011000", # A
                "10000110100", # \t = Horizontal Tab
                "10001011000", # B
                "10011010000", # \x07 = Bell
                "10000101100", # \x03 = ETX = End of Text
                "10001100100", # CHECKSUM
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
        end
    end

    @testset "mixed subtypes" begin

        let binary_pattern = Barcode.get_pattern(
                ["START A", "A", "B", "SHIFT B", "a", "A", "CODE C", "00", "CHECKSUM", "STOP"],
                :code128,
            )
            @test length(binary_pattern) == 13
            @test binary_pattern == [
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

        let binary_pattern = Barcode.get_pattern(
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
            binary_pattern = Barcode.get_pattern(zip, :code128)
            @test length(binary_pattern) == 10
            @test binary_pattern == [
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
            @test Barcode.pattern_img("../img/zipcode_$zip.png", binary_pattern) === nothing
        end

        let binary_pattern = Barcode.get_pattern("CSE370", :code128)
            @test length(binary_pattern) == 12
            @test binary_pattern == [
                "00000000000", # Quiet zone
                "11010000100", # START A
                "10001000110", # C
                "11011101000", # S
                "10001101000", # E
                "11001011100", # 3
                "11101101110", # 7
                "10011101100", # 0
                "11001001110", # check sum 20 
                # (1 * 103 + 1 * 35 + 2 * 51 + 3 * 37 + 4 * 19 + 5 * 23 + 6 * 16)
                "11000111010", # STOP
                "11", # END
                "00000000000", # Quiet zone
            ]
            @test Barcode.pattern_img("../img/CSE370.png", binary_pattern) === nothing
        end
    end
end
