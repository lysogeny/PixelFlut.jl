function load_img(img::AbstractString)
    img = FileIO.load(img)
    reinterpret(reshape, UInt8, img) |> collect
end

function format_pixels(img::AbstractArray)
    _, w, h = size(img)
    pxs = [(y, x, img[1:3,x,y]) for x in 1:w, y in 1:h if img[1,x,y]>0]
    map(x -> msg_pixel(x...), pxs)
end
