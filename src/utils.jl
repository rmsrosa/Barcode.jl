"""
    pattern_img(binary_pattern; img_height = 50)

Return an image of type `Matrix{Gray{Bool}}` where the number of rows is specified
by `img_height` and where the rows are filled with the `binary_pattern`. Displaying
the image reveals the barcode.

You can save the generated image via `FileIO.save`, using any format accepted by `FileIO`.
"""
function pattern_img(binary_pattern; img_height = 50)
    cbp = collect(prod(binary_pattern))
    # with a little help from @ScottPJones and @borodi
    img =
        Gray.(
            [
                fill(true, 1, length(cbp))
                repeat(reshape(map(==('0'), cbp), 1, :), img_height, 1)
                fill(true, 1, length(cbp))
            ],
        )
    return img
end
