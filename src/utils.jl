"""
    pattern_img(binary_pattern, height = 20)

Return an Gray Image BitArray with the number of rows specified by `height` and
the `binary_pattern` filling the rows with 0's and 1's. Displaying the image reveals
the barcode.
"""
function pattern_img(binary_pattern, height = 20)
    bp = prod(binary_pattern)
    img = Gray.(repeat(reshape(map(==('1'), collect(bp)), 1,:), height, 1))
    return img
end

"""
    pattern_save(filename, binary_pattern, height = 20)

Save the `binary_pattern` to file using any format accepted by `FileIO` and with
the specified height.
"""
function pattern_save(filename, binary_pattern, height = 20)
    img = pattern_img(binary_pattern, height)
    FileIO.save(filename, img)
end



