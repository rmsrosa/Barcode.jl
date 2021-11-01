using Barcode
using Test

@testset begin
    binarycode = Barcode.get_code128c("00")
    @test length(binarycode) == 5
    @test binarycode == [
        "11010011100", # STARTC
        "11011001100", # 00
        "11001100110", # verification digit
        "11000111010", # STOP
        "11" # END
    ]
end