"""
    barcode_img(pattern; img_height = 50)

Return an image of type `Matrix{Gray{Bool}}` where the number of rows is specified
by `img_height` and where the rows are filled with the `binary_pattern`. Displaying
the image reveals the barcode.

You can save the generated image via `FileIO.save`, using any format accepted by `FileIO`.
"""
function barcode_img(pattern; img_height = 50)
    img =
        Gray.(
            [
                fill(true, 1, length(pattern))
                repeat(reshape([c == ('0') for c in pattern], 1, :), img_height, 1)
                fill(true, 1, length(pattern))
            ],
        )
    return img
end
