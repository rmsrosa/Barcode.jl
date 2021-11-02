# Barcode

A [Code128](https://en.wikipedia.org/wiki/Code_128) barcode generator (see also [The 128 code](http://grandzebu.net/informatique/codbar-en/code128.htm) and [How Barcodes Work](https://courses.cs.washington.edu/courses/cse370/01au/minirproject/BarcodeBattlers/barcodes.html)).

This package is under development.

Currently, only code128 is being implemented, but other barcodes might be implemented in the future. Contributions are welcome!

## Example

The main encoding method is `get_code128(code::AbstractString, mode::Symbol = :auto)`.

In mode `:auto`, the method attempts to infer whether `code` can be encoded using `code128c` (only digits, with even length), `code128a`, or `code128b` subtypes. You can also enforce each subtype setting `mode` to either `:code128a`, `:code128b`, or `:code128c`.

The code128 encoding also allows mixing subtypes, but this is not yet implemented in `:auto`.

The method returns a Vector of Strings with 0's and 1's, representing the code for each symbol in the barcode. One can concatenate it to a single String if desired.

Here is an example with a ZIP code:

```julia
julia> zip = "12.345-678"
"12.345-678"

julia> zip = replace(zip, r"\s|\.|\-" => "")
"12345678"

julia> binary_pattern = Barcode.get_code128(zip)
8-element Vector{String}:
 "11010011100"
 "10110011100"
 "10001011000"
 "11100010110"
 "11000010100"
 "10001110110"
 "11000111010"
 "11"

julia> prod(binary_pattern)
"1101001110010110011100100010110001110001011011000010100100011101101100011101011"
```

Once `binary_pattern` is obtained, one can create a Gray Image array and/or save the image to file with `pattern_img(binary_pattern; height = 20)` and `Barcode.pattern_save(filename, binary_pattern; height = 20)`.

Here is the result of saving the zip code above to a PNG file with `Barcode.pattern_save("../img/zipcode_12345678.png", binary_pattern)`:

![Zip Code 12.345-678](img/zipcode_12345678.png)

Here is another example with `code128a`:

```julia
julia> binary_pattern = Barcode.get_code128(zip, :code128c);

julia> pattern_img("../img/CSE370.png", binary_pattern)
```

![CSE370](img/CSE370.png)

## To-do

There are still a few things to be done in regards to the generated images, and with the image formats to play along with other graphic tools.

Mode `:auto` also needs to be able to handle changing subtypes.

And there are plenty of other barcode formats that can be implemented.

## License

This package is provided under the [MIT License](LICENSE).
