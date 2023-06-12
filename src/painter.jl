function gather_pixels(img::AbstractMatrix)
    # GHather non-transparent pixels into pre-built strings that get sent to the server
end

mutable struct Sender
    sockets::Vector{Sockets.TCPSocket}
    size::Tuple{Int, Int}
    offset::Vector{Int, Int}
    img::Matrix{UInt32}
    pixels::Vector{Tuple{Int, Int}, UInt32}
    title::String
    function Sender(socket, size, img, title)
        offset = [rand(1:size[1]), rand(1:size[2])]
        pixels = gather_pixels(img)
        new(socket, size, offset, img, pixels, title)
    end
end

function Sender(host::T_HOST, port::Int, img::AbstractString; title="PixelFlut.jl sender", n_connections=8)
    sockets = [Sockets.connect(host, port) for _ in 1:n_connections]
    size = query_size(sockets[1])
    Sender(sockets, size, img, title=title)
end

function Sender(host::T_HOST, port::Int, img::AbstractString; title="PixelFlut.jl sender", n_connections=8)
    Sender(host, port, load_img(img), title=title, n_connections=n_connections)
end

function run(sender::Sender)
    @info "Starting Sender"
    n_sockets = length(sender.sockets)
    n_pixels = length(sender.pixels)
    pixels = Random.shuffle(sender.pixels)
    slices = slice_along(n_pixels, n_sockets)
    #barrier = SyncBarriers.Barrier(n_sockets)
    threads = []
    for (i, socket) in enumerate(sender.sockets)
        thread = Threads.@spawn begin
            #b = barrier[i]
            pxs = pixels[slices[i]]
            while !eof(socket)
                @debug "Sending pixels in socket $i"
                for px in pxs
                    write(socket, px)
                end
                @debug "Thread $i waiting for other tasks"
                #SyncBarriers.cycle!(b)
            end
        end
        push!(thread)
    end
    wait.(threads)
end
