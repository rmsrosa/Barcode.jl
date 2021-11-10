"""
    barcode_img(pattern; img_height = 50)

Return an image of type `Matrix{Gray{Bool}}` where the number of rows is specified
by `img_height` and where the rows are filled with the `binary_pattern`. Displaying
the image reveals the barcode.

You can save the generated image via `FileIO.save`, using any format accepted by `FileIO`.
"""
function barcode_img(pattern::AbstractString; img_height = 50)
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

function barcode_positions(pattern::AbstractString)
    x = Int[]
    w = Int[]

    ind = 1
    
    while ind ≤ length(pattern)
        if pattern[ind] == '1'
            push!(x, ind)
            next_ind = findnext(==('0'), pattern, ind)
            push!(w, next_ind - ind)
            ind = next_ind
        else
            ind += 1
        end
    end
    return x, w
end

function barcode_widths(pattern::AbstractString)
    w = ""

    ind = findfirst(==('1'), pattern)
    while ind !== nothing
        c = pattern[ind]
        next_ind = findnext(!=(c), pattern, ind)
        next_ind !== nothing && (w *= string(next_ind - ind))
        ind = next_ind
    end
    w = w[begin:end-1] # drop the ending `11`, which is a bar with width 2
    return w
end
