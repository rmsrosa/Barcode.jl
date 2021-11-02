using Barcode
using Test

@testset "code128a chunk" begin
    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("A", :code128a, 0)
        @test length(binary_pattern) == weight == 1
        @test binary_pattern == [
            "10100011000", # A binary_pattern
        ]
        @test chk_sum % 103 == 33
    end

    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("CSE370", :code128a, 0)
        @test length(binary_pattern) == weight == 6
        @test binary_pattern == [
            "10001000110", "11011101000", "10001101000",
            "11001011100", "11101101110", "10011101100"
        ]
        @test chk_sum % 103 == 20
    end
end

@testset "code128b chunk" begin
    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("a", :code128b, 0)
        @test length(binary_pattern) == weight == 1
        @test binary_pattern == [
            "10010110000", # A binary_pattern
        ]
        @test chk_sum % 103 == 65
    end

    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("#( a%)", :code128b, 0)
        @test length(binary_pattern) == weight == 6
        @test binary_pattern == [
            "10010011000", "10001100100", "11011001100",
            "10010110000", "10001001100", "11001001000"
        ]
        @test chk_sum % 103 == 49
    end
end

@testset "code128c chunk" begin
    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("00", :code128c, 0)
        @test length(binary_pattern) == weight == 1
        @test binary_pattern == [
            "11011001100", # 00 binary_pattern
        ]
        @test chk_sum % 103 == 0
    end

    let ( binary_pattern, chk_sum, weight ) = Barcode.get_code128_chunk("123456", :code128c, 0)
        @test length(binary_pattern) == weight == 3
        @test binary_pattern == [
            "10110011100", "10001011000", "11100010110"
        ]
        @test chk_sum % 103 == 42
    end
end

@testset "code128" begin
    let binary_pattern = Barcode.get_code128("A", :code128a)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010000100", # START A
            "10100011000", # A
            "10100011000", # checksum 33 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end

    let binary_pattern = Barcode.get_code128("a", :code128b)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010010000", # START B
            "10010110000", # a
            "10010000110", # checksum 66 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end

    let binary_pattern = Barcode.get_code128("00", :code128c)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010011100", # START C
            "11011001100", # 00
            "11001100110", # checksum 2 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end
end

@testset "auto" begin
    let binary_pattern = Barcode.get_code128("A", :auto)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010000100", # START A
            "10100011000", # A
            "10100011000", # checksum 33 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end

    let binary_pattern = Barcode.get_code128("a", :auto)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010010000", # START B
            "10010110000", # a
            "10010000110", # checksum 66 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end

    let binary_pattern = Barcode.get_code128("00", :auto)
        @test length(binary_pattern) == 5
        @test binary_pattern == [
            "11010011100", # START C
            "11011001100", # 00
            "11001100110", # checksum 2 pattern
            "11000111010", # STOP
            "11" # END
        ]
    end
end

@testset "zip" begin
    let zip = "12.345-678"
        zip = replace(zip, r"\s|\.|\-" => "")
        binary_pattern = Barcode.get_code128(zip, :code128c)
        @test length(binary_pattern) == 8
        @test binary_pattern == [
            "11010011100", # START C
            "10110011100", # 12
            "10001011000", # 34
            "11100010110", # 56
            "11000010100", # 78
            "10001110110", # checksum pattern 47 = 
                           # (1 * 105 + 1 * 12 + 2 * 34 + 3 * 56 + 4 * 78) % 103
            "11000111010", # STOP
            "11" # END
        ]
    end
end