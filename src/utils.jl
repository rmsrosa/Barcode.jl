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
