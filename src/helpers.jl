function slice_along(n_items::Int, n_slices::Int)
    items = 1:n_items
    slices = [Int[] for _ in 1:n_slices]
    len, rem = divrem(n_items, n_slices)
    if len > 0
        for (i, (i_first, i_last)) in enumerate(zip(1:len:n_slices*len, len:len:n_slices*len))
            for i_head = i_first:i_last
                push!(slices[i], i_head)
            end
        end
    end
    # Items missed in the first loop
    tail = items[end-rem+1:end]
    for (i, i_tail)  in enumerate(tail)
        push!(slices[i], i_tail)
    end
    return slices
end
