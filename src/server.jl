SERVER_ADDR = Sockets.IPv4(0)
SERVER_PORT = 1337

mutable struct Server
    size::Tuple{Int, Int}
    buffer::Matrix{UInt32}
    title::String
    window::Ptr
    server::Sockets.TCPServer
    function Server(size::Tuple{Int, Int}, addr, port, title)
        buffer = zeros(UInt32, size...)
        window = MiniFB.mfb_open(title, size...)
        server = Sockets.listen(addr, port)
        new(size, buffer, title, window, server)
    end
end

function Server(size::Tuple{Int, Int}; title="PixelFlut.jl")
    Server(size, SERVER_ADDR, SERVER_PORT, title)
end

function update_fb!(server::Server)
    MiniFB.mfb_update(server.window, view(server.buffer, :))
end

function handle_pixel(server::Server, line::AbstractString)
    pixel = parse_msg_pixel(line)
    if isnothing(pixel)
        return "Bad message"
    end
    # We received a valid pixel
    x, y, rgb = pixel
    if x < 1 || y < 1 || x > server.size[1] || y > server.size[2]
        return "Bad message"
    end
    server.buffer[x, y] = MiniFB.mfb_rgb(rgb...)
    @debug "Updated pixel" x y rgb
    # Parrot the message back instead of building a new one
    return line
end

function update_loop(server::Server)
    @info "Canvas Updater Started"
    while true
        update_fb!(server)
        sleep(1/60)
    end
end

function connection_loop(server::Server, socket::Sockets.TCPSocket)
    ip = Sockets.getpeername(socket)[1]
    @info "CONNECTED $ip connected"
    while !eof(socket)
        line = readline(socket)
        @debug "RECEIVED $ip: $line "
        if startswith(line, "PX ")
            response = handle_pixel(server, line)
        elseif startswith(line, "SIZE")
            response = msg_size(server.size...)
        elseif startswith(line, "HELP")
            response = MSG_HELP
        else
            response = MSG_BAD
        end
        @debug "Sending response" response
        write(socket, response)
        write(socket, '\n')
        @debug "SENT $ip: $response"
    end
    @info "$ip disconnected"
end

function run(server::Server)
    @async update_loop(server)
    while true
        socket = Sockets.accept(server.server)
        Threads.@spawn connection_loop(server, socket)
    end
end
