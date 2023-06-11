MSG_HELP = """# PixelFlut

Query a pixel: `PX {x} {y}\\n` (yields `PX {x} {y} {rrggbb}\\n`)
Set a pixel: `PX {x} {y} {rrggbb}\\n` (yields `PX {x} {y} {rrggbb}\\n`)
Query size: `SIZE\\n` (yields `PX {w} {h}`)
This message: `HELP\\n`
"""

MSG_BAD = "Bad message"

# Size message

msg_size() = "SIZE\n"
msg_size(w::Int, h::Int) = "SIZE $w $h\n"

send_size(socket::Sockets.TCPSocket) = write(socket, msg_size())
send_size(socket::Sockets.TCPSocket, w::Int, h::Int) = write(socket, msg_size(w, h))

msg_pixel(x::Int, y::Int) = "PX $x $y\n"
msg_pixel(x::Int, y::Int, rgb::AbstractString) = "PX $x $y $rgb\n"

send_pixel(socket::Sockets.TCPSocket, x::Int, y::Int) = write(socket, msg_pixel(x, y))
send_pixel(socket::Sockets.TCPSocket, x::Int, y::Int, rgb::AbstractString) = write(socket, msg_pixel(x, y, rgb))


function parse_msg_size(msg::AbstractString)
    pattern = r"^SIZE (\d+) (\d+)$"
    msg = match(pattern, msg)
    if isnothing(msg)
        return
    end
    return parse.(Int, (msg.captures[1], msg.captures[2]))
end

function query_size(socket::Sockets.TCPSocket)
    send_size(socket)
    line = readline(socket)
    parse_msg_size(line)
end

function parse_rgb(str_rgb::AbstractString)
    parse.(UInt8, [str_rgb[1:2], str_rgb[3:4], str_rgb[5:6]], base=16)
end

function parse_msg_pixel(msg::AbstractString)
    pattern = r"^PX (\d+) (\d+) ([A-Fa-f0-9]{6,8})$"
    msg = match(pattern, msg)
    if isnothing(msg)
        return
    end
    x, y = parse.(Int, (msg.captures[1], msg.captures[2]))
    rgb = parse_rgb(msg.captures[3])
    return (x, y, rgb)
end


