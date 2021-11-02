"""
    pattern_img(binary_pattern, height = 20)

Return an Gray Image BitArray with the number of rows specified by `height` and
the `binary_pattern` filling the rows with 0's and 1's. Displaying the image reveals
the barcode.
"""
function pattern_img(binary_pattern, height = 20)
    bp = prod(binary_pattern)
    img = Gray.(
        transpose(
            reduce(
                hcat,
                fill(BitVector(map(c -> parse(Bool, c), collect(bp))), height)
            )
        )
    )
    return img
end
