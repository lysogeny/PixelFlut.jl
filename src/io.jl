function load_img(img::AbstractString)
    img = FileIO.load(img)
    reinterpret(reshape, UInt8, img) |> collect
end

function gather_pixels(img::AbstractArray)
    _, w, h = size(img)
    [(y, x, MiniFB.mfb_rgb(img[1:3,x,y]...))
     for x in 1:w, y in 1:h if img[1,x,y]>0]
end
function format_pixels(img::AbstractArray)
    map(x -> msg_pixel(x...), gather_pixels(img))
end
