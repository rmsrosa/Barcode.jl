# Barcode

A [Code128](https://en.wikipedia.org/wiki/Code_128) barcode generator (see also [The 128 code](http://grandzebu.net/informatique/codbar-en/code128.htm) and [How Barcodes Work](https://courses.cs.washington.edu/courses/cse370/01au/minirproject/BarcodeBattlers/barcodes.html)).

This package is under development.

Currently, only code128 is being implemented, but other barcodes might be implemented in the future. Contributions are welcome!

## Example

The main encoding method is `get_pattern(code::AbstractString, encoding_type::Symbol)`.

Currently, only Code128 is implemented, for which one should set `encoding_type` to `:code128`..

The method attempts to infer whether `code` can be encoded using `code128c` (only digits, with even length), `code128a`, or `code128b` subtypes. You can also enforce each subtype by calling `get_pattern(code, Val(:code128), mode)`, where `mode` can be either `:code128a`, `:code128b`, or `:code128c`.

The code128 encoding also allows mixing subtypes, but this is not yet implemented.

The method returns a Vector of Strings with 0's and 1's, representing the code for each symbol in the barcode, where `0` is a space and `1` is a bar. One can concatenate it to a single String if desired.

Here is an example with a ZIP code:

```julia
julia> zip = "12.345-678"
"12.345-678"

julia> zip = replace(zip, r"\s|\.|\-" => "")
"12345678"

julia> binary_pattern = Barcode.get_pattern(zip, :code128)
10-element Vector{String}:
 "00000000000"
 "11010011100"
 "10110011100"
 "10001011000"
 "11100010110"
 "11000010100"
 "10001110110"
 "11000111010"
 "11"
 "00000000000"

julia> prod(binary_pattern)
"00000000000110100111001011001110010001011000111000101101100001010010001110110110001110101100000000000"
```

Once `binary_pattern` is obtained, one can create a Gray Image array and/or save the image to file with `Barcode.pattern_img(binary_pattern; img_height = 20)` and `Barcode.pattern_img(filename, binary_pattern; img_height = 20)`.

Here is the result of saving the zip code above to a PNG file with `Barcode.pattern_img("img/zipcode_12345678.png", binary_pattern)`:

![Zip Code 12.345-678](img/zipcode_12345678.png)

Here is another example which is detected as `code128a`:

```julia
julia> binary_pattern = Barcode.get_pattern("CSE370", :code128)
12-element Vector{String}:
 "00000000000"
 "11010000100"
 "10001000110"
 "11011101000"
 "10001101000"
 "11001011100"
 "11101101110"
 "10011101100"
 "11001001110"
 "11000111010"
 "11"

julia> Barcode.pattern_img("img/CSE370.png", binary_pattern)
```

![CSE370](img/CSE370.png)

The pattern is obtained by first encoding the given code in a symbolic vectorial representation and then send to another dispatch of the function above. For example,

```julia
julia> encoding = get_encoding("CSE370", :code128)
9-element Vector{String}:
 "START A"
 "C"
 "S"
 "E"
 "3"
 "7"
 "0"
 "CHECKSUM"
 "STOP"

julia> get_pattern(encoding, :code128)
12-element Vector{String}:
 "00000000000"
 "11010000100"
 "10001000110"
 "11011101000"
 "10001101000"
 "11001011100"
 "11101101110"
 "10011101100"
 "11001001110"
 "11000111010"
 "11"
 "00000000000"
```
## To-do

There are still a few things to be done in regards to the generated images, and with the image formats to play along with other graphic tools.

Encoding also needs to be able to handle changing subtypes and using directive FNC4 to access iso-latin ISO/IEC 8859-1.

And there are plenty of other barcode formats that can be implemented.

## License

This package is provided under the [MIT License](LICENSE).
