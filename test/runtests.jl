using Barcode
using Test

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
            "00000000000" # Quiet zone
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
            "00000000000" # Quiet zone
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
            "00000000000" # Quiet zone
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
            "00000000000" # Quiet zone
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
            "00000000000" # Quiet zone
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
            "00000000000" # Quiet zone
        ]
    end
end

@testset "mixed subtypes" begin
    
    let binary_pattern = Barcode.get_pattern(
        ["START A", "A", "B", "Shift B", "a", "A", "Code C", "00", "CHECKSUM", "STOP"],
        :code128
    )
        @test length(binary_pattern) == 13
        @test binary_pattern == [
            "00000000000", # Quiet zone
            "11010000100", # "START A" (103)
            "10100011000", # "A" (33)
            "10001011000", # "B" (34)
            "11110100010", # "Shift B" (98)
            "10010110000", # "a" (65)
            "10100011000", # "A" (33)
            "10111011110", # "Code C" (99)
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
            "START C", "FNC 1", "42", "18", "40", "20", "50",
            "Code A",  "0", "CHECKSUM", "STOP"
        ],
        :code128
    )
        
    end
end

@testset "save img" begin
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
            "00000000000" # Quiet zone
        ]
        @test Barcode.pattern_img("../img/CSE370.png", binary_pattern) === nothing
    end
end