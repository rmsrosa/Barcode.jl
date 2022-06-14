module Barcodes

using DataFrames
using Images

include("code128_charset.jl")
include("encoding.jl")
include("pattern.jl")
include("utils.jl")
include("types.jl")

end
