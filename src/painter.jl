mutable struct Sender
    sockets::Vector{Sockets.TCPSocket}
    size::Tuple{Int, Int}
    pixels::Vector{String}
    function Sender(socket, size, img)
        pixels = format_pixels(img)
        new(socket, size, pixels)
    end
end

function Sender(host::T_HOST, port::Int, img::AbstractArray)
    n_connections = Threads.nthreads()
    sockets = [Sockets.connect(host, port) for _ in 1:n_connections]
    size = query_size(sockets[1])
    Sender(sockets, size, img)
end

function Sender(host::T_HOST, port::Int, img::AbstractString)
    Sender(host, port, load_img(img))
end

function empty_listener(socket::Sockets.TCPSocket)
    @debug "Listening on socket"
    while !eof(socket)
         readline(socket)
    end
end

function socket_worker(socket::Sockets.TCPSocket, pxs::Vector{String})
    @info "Started worker for socket $socket" 
    @async empty_listener(socket)
    while isopen(socket)
        for px in pxs
            write(socket, px)
        end
        @debug "Iteration complete on socket $socket"
    end
end

function run(sender::Sender)
    @info "Starting Sender"
    n_sockets = length(sender.sockets)
    n_pixels = length(sender.pixels)
    pixels = Random.shuffle(sender.pixels)
    slices = slice_along(n_pixels, n_sockets)
    threads = map(1:n_sockets) do i 
        thread = Threads.@spawn socket_worker(sender.sockets[i], pixels[slices[i]])
        @info "Created thread for socket $i"
        errormonitor(thread)
    end
    wait.(threads)
end
