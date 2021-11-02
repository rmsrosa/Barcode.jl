using Barcode
using Test

@testset "code128a chunk" begin
    binarycode, chk_sum, weight = Barcode.get_code128_chunk("A", :code128a, 0)
    @test length(binarycode) == weight == 1
    @test binarycode == [
        "10100011000", # A binary code
    ]
    @test chk_sum % 103 == 33

    binarycode, chk_sum, weight = Barcode.get_code128_chunk("CSE370", :code128a, 0)
    @test length(binarycode) == weight == 6
    @test binarycode == [
        "10001000110", "11011101000", "10001101000",
        "11001011100", "11101101110", "10011101100"
    ]
    @test chk_sum % 103 == 20
end

@testset "code128b chunk" begin
    binarycode, chk_sum, weight = Barcode.get_code128_chunk("a", :code128b, 0)
    @test length(binarycode) == weight == 1
    @test binarycode == [
        "10010110000", # A binary code
    ]
    @test chk_sum % 103 == 65

    binarycode, chk_sum, weight = Barcode.get_code128_chunk("#( a%)", :code128b, 0)
    @test length(binarycode) == weight == 6
    @test binarycode == [
        "10010011000", "10001100100", "11011001100",
        "10010110000", "10001001100", "11001001000"
    ]
    @test chk_sum % 103 == 49
end

@testset "code128c chunk" begin
    binarycode, chk_sum, weight = Barcode.get_code128_chunk("00", :code128c, 0)
    @test length(binarycode) == weight == 1
    @test binarycode == [
        "11011001100", # 00 binary code
    ]
    @test chk_sum % 103 == 0

    binarycode, chk_sum, weight = Barcode.get_code128_chunk("123456", :code128c, 0)
    @test length(binarycode) == weight == 3
    @test binarycode == [
        "10110011100", "10001011000", "11100010110"
    ]
    @test chk_sum % 103 == 42
end

@testset "code128c" begin
    binarycode = Barcode.get_code128("A", :code128a)
    @test length(binarycode) == 5
    @test binarycode == [
        "11010000100", # START A
        "10100011000", # A
        "10100011000", # checksum 33 pattern
        "11000111010", # STOP
        "11" # END
    ]

    binarycode = Barcode.get_code128("a", :code128b)
    @test length(binarycode) == 5
    @test binarycode == [
        "11010010000", # START B
        "10010110000", # a
        "10010000110", # checksum 66 pattern
        "11000111010", # STOP
        "11" # END
    ]

    binarycode = Barcode.get_code128("00", :code128c)
    @test length(binarycode) == 5
    @test binarycode == [
        "11010011100", # START C
        "11011001100", # 00
        "11001100110", # checksum 2 pattern
        "11000111010", # STOP
        "11" # END
    ]
end

@testset "zip" begin
    zip = "12.345-678"
    zip = replace(zip, r"\s|\.|\-" => "")
end