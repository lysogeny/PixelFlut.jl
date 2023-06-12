mutable struct Sender
    sockets::Vector{Sockets.TCPSocket}
    size::Tuple{Int, Int}
    pixels::Vector{String}
    function Sender(socket, size, img)
        pixels = format_pixels(img)
        new(socket, size, pixels)
    end
end

function Sender(host::T_HOST, port::Int, img::AbstractArray; n_connections=8)
    sockets = [Sockets.connect(host, port) for _ in 1:n_connections]
    size = query_size(sockets[1])
    Sender(sockets, size, img)
end

function Sender(host::T_HOST, port::Int, img::AbstractString;)
    Sender(host, port, load_img(img), n_connections=Threads.nthreads())
end

function empty_listener(socket::Sockets.TCPSocket)
    @debug "Listening on socket"
    while !eof(socket)
         readline(socket)
    end
end

function run(sender::Sender)
    @info "Starting Sender"
    n_sockets = length(sender.sockets)
    n_pixels = length(sender.pixels)
    pixels = Random.shuffle(sender.pixels)
    slices = slice_along(n_pixels, n_sockets)
    threads = []
    for i in 1:n_sockets
        thread = Threads.@spawn begin
            @info "Started worker for socket $i" 
            socket = sender.sockets[i]
            @async empty_listener(socket)
            pxs = pixels[slices[i]]
            while true
                for px in pxs
                    write(socket, px)
                end
                @debug "Iteration complete on socket $i"
            end
        end
        errormonitor(thread)
        push!(threads, thread)
    end
    wait.(threads)
end
