mutable struct Viewer <: AbstractUI
    connection::Vector{Sockets.TCPSocket}
    buffer::Matrix{UInt32}
    title::String
    frame_count::Int
    window::Ptr
    pixels::Vector{String}
    function Viewer(connection, size, title)
        window = MiniFB.mfb_open(title, size...)
        w, h = size
        pixels = [msg_pixel(x, y) for x in 1:w, y in 1:h][:]
        buffer = zeros(UInt32, size...)
        new(connection, buffer, title, 0, window, pixels)
    end
end

function Viewer(host, port; title="PixelFlut.jl Viewer")
    connection = [Sockets.connect(host, port) for _ in 1:8]
    @info "Connected to $host"
    size = query_size(connection.sockets[1])
    @info "$host has size ($(size[1]), $(size[2]))"
    Viewer(connection, size, title)
end

function writing_listener(viewer::Viewer, socket::Sockets.TCPSocket)
    while !eof(socket)
        line = readline(socket)
        @debug "Client Received: $line" length(line)
        if startswith(line, "PX")
            (x, y, rgb) = parse_msg_pixel(line)
            viewer.buffer[x, y] = MiniFB.mfb_rgb(rgb...)
        end
    end
end

function socket_worker(viewer::Viewer, socket::Sockets.TCPSocket, pxs::Vector{String})
    @async writing_listener(viewer, socket)
    while isopen(socket)
        #???? slice???
        for px in pxs
            write(socket, px)
        end
    end
end

function run(viewer::Viewer)
    @info "Starting Viewer"
    @async update_loop(viewer)
    blank(viewer, MiniFB.mfb_rgb(0xff, 0x00, 0x00))
    n_sockets = length(viewer.connection.sockets)
    n_pixels = length(viewer.pixels)
    pixels = Random.shuffle(viewer.pixels)
    slices = slice_along(n_pixels, n_sockets)
    threads = map(1:n_sockets) do i
        socket = viewer.connection.sockets[i]
        thread = Threads.@spawn socket_worker(viewer, socket, pixels[slices[i]])
        errormonitor(thread)
    end
    wait.(threads)
end
