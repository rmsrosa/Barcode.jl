# Barcode

A [Code128](https://en.wikipedia.org/wiki/Code_128) barcode generator (see also [The 128 code](http://grandzebu.net/informatique/codbar-en/code128.htm) and [How Barcodes Work](https://courses.cs.washington.edu/courses/cse370/01au/minirproject/BarcodeBattlers/barcodes.html)).

This package is under development.

Currently, only code128 is being implemented, but other barcodes might be implemented in the future. Contributions are welcome!

## Examples

The main encoding methods are `encode(msg::AbstractString, encoding_type::Symbol)`, which yields a Code128 symbolic encoding for the given `msg`, `barcode_pattern(code::Vector{<:AbstractString}, encoding_type::Symbol)`, which yields the bar pattern for the given `code`, and `barcode_pattern(msg::AbstractString, encoding_type::Symbol)`, which yields the bar pattern directly from the `msg`(which simply calls the previous two methods).

Currently, only Code128 is implemented, for which one should set `encoding_type` to `:code128`, or one of its subtypes `:code128a`, `:code128b`, or `:code128c`.

If `:code128` is given, the method attempts to infer whether `code` can be encoded using `code128c` (only digits, with even length), `code128a`, or `code128b` subtypes, or it will then look for an optimized mixed-subtype encoding.

The pattern is a Vector of Strings with 0's and 1's, representing the bar code chunk for each code128 symbol in the barcode, where `0` is a space and `1` is a bar. One can concatenate it to a single String if desired.

Here is an example with a ZIP code:

```julia
julia> using Barcode

julia> zip_code = "12.345-678"
"12.345-678"

julia> zip_code = replace(zip_code, r"\s|\.|\-" => "")
"12345678"

julia> pattern = Barcode.barcode_pattern(zip_code, :code128)
"00000000000110100111001011001110010001011000111000101101100001010010001110110110001110101100000000000"
```

One can see the code with `encode`:

```julia
julia> code = Barcode.encode(zip_code, :code128)
7-element Vector{String}:
 "START C"
 "12"
 "34"
 "56"
 "78"
 "CHECKSUM"
 "STOP"
```

Once the `pattern` is obtained, one can create a Gray Image with `img = Barcode.barcode_img(pattern; img_height = 20)`. After that, you can save it with `FileIO`.

```julia
julia> using FileIO

julia> FileIO.save("img/zipcode_12345678.png", img)
```

Here is the result of saving the zip code above to a PNG file with `Barcode.barcode_img("img/zipcode_12345678.png", pattern)`:

![Zip Code 12.345-678](img/zipcode_12345678.png)

Here is another example with mixed subtypes:

```julia
julia> code = encode("CSE370", :code128)
9-element Vector{String}:
 "START B"
 "C"
 "S"
 "E"
 "3"
 "CODE C"
 "70"
 "CHECKSUM"
 "STOP"

julia> pattern = Barcode.barcode_pattern(code, :code128)
"000000000001101001000010001000110110111010001000110100011001011100101110111101011000010010010001100110001110101100000000000"

julia> img = Barcode.barcode_img(pattern)

julia> FileIO.save("img/CSE370.png", img)
```

![CSE370](img/CSE370.png)

## To-do

There are still a few things to be done in regards to the generated images, and with the image formats to play along with other graphic tools.

Encoding also needs to be able to handle using directive FNC4 to access iso-latin ISO/IEC 8859-1. (Currently, it is actualy GSM-128 encoding).

And there are plenty of other barcode formats that can be implemented.

## License

This package is provided under the [MIT License](LICENSE).
