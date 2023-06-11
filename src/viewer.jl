mutable struct Viewer <: AbstractUI
    connection::ConnectionPool
    buffer::Matrix{UInt32}
    title::String
    frame_count::Int
    window::Ptr
    function Viewer(socket, size, title)
        window = MiniFB.mfb_open(title, size...)
        buffer = zeros(UInt32, size...)
        new(socket, buffer, title, 0, window)
    end
end

function Viewer(host, port; title="PixelFlut.jl Viewer")
    connection = ConnectionPool(host, port, 8)
    @info "Connected to $host"
    size = query_size(connection.sockets[1])
    @info "$host has size ($(size[1]), $(size[2]))"
    Viewer(connection, size, title)
end

function response_handler(socket::Sockets.TCPSocket, buffer::Matrix{UInt32})
    while !eof(socket)
        line = readline(socket)
        @debug "Client Received: $line" length(line)
        if startswith(line, "PX")
            (x, y, rgb) = parse_msg_pixel(line)
            buffer[x, y] = MiniFB.mfb_rgb(rgb...)
        end
    end
end

function request_loop(socket::Sockets.TCPSocket, coordinates::Vector{Tuple{Int, Int}})
    @info "Starting request loop"
    while true
        for (x, y) in coordinates
            write(socket, msg_pixel(x, y))
        end
    end
end

function blank(viewer::Viewer, rgb::UInt32)
    w, h = size(viewer)
    coordinates = [(x, y) for x in 1:w, y in 1:h]
    for (x, y) in coordinates
        viewer.buffer[x, y] = rgb
    end
end

function run(viewer::Viewer)
    @info "Starting Viewer"
    blank(viewer, MiniFB.mfb_rgb(0xff, 0x00, 0x00))
    @async update_loop(viewer)
    w, h = size(viewer)
    coordinates = [(x, y) for x in 1:w, y in 1:h][:]
    slices = slice_along(length(coordinates), length(viewer.connection.sockets))
    threads = []
    for (i, socket) in enumerate(viewer.connection.sockets)
        thread = Threads.@spawn begin
            @async response_handler(socket, viewer.buffer)
            request_loop(socket, coordinates[slices[i]])
        end
        push!(threads, thread)
    end
    wait.(threads)
    # Continually  request new pixel information
end
