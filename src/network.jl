function void_listener(socket::Sockets.TCPSocket)
    @debug "Listening on socket"
    while !eof(socket)
         readline(socket)
    end
end
