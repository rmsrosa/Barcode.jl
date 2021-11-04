module Barcode

using DataFrames
using Images
using FileIO

include("code128_charset.jl")
include("encoding.jl")
include("pattern.jl")
include("utils.jl")

end
