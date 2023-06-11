mutable struct Viewer <: AbstractUI
    socket::Sockets.TCPSocket
    buffer::Matrix{UInt32}
    title::String
    window::Ptr
    function Viewer(socket, size, title)
        window = MiniFB.mfb_open(title, size...)
        buffer = zeros(UInt32, size...)
        new(socket, buffer, title, window)
    end
end

function Viewer(host, port; title="PixelFlut.jl Viewer")
    socket = Sockets.connect(host, port) 
    @info "Connected to $host"
    size = query_size(socket)
    @info "$host has size ($(size[1]), $(size[2]))"
    Viewer(socket, size, title)
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

function request_loop(viewer::Viewer)
    @info "Starting request loop"
    w, h = size(viewer)
    coordinates = [(x, y) for x in 1:w, y in 1:h]
    while true
        for (x, y) in coordinates
            send_pixel(viewer.socket, x, y)
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
    errormonitor(Threads.@spawn response_handler(viewer.socket, viewer.buffer))
    @async update_loop(viewer)
    request_loop(viewer)
    # Continually  request new pixel information
end
