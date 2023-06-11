mutable struct ConnectionPool
    host::T_HOST
    port::Int
    lock::ReentrantLock
    cur::Mods.Mod{N,Int} where N
    sockets::Vector{Sockets.TCPSocket}
    function ConnectionPool(host, port, n_connections)
        connections = [Sockets.connect(host, port) for _ in 1:n_connections] 
        new(host, port, ReentrantLock(), Mods.Mod{n_connections}(0), connections)
    end
end

function Base.write(pool::ConnectionPool, x::String)
    @async write(pool.sockets[Mods.value(pool.cur)+1], x)
    pool.cur += 1
end
