abstract type AbstractSender end

Base.size(sender::AbstractSender) = sender.size

connect(host::T_HOST, port::Int, n::Int) = [Sockets.connect(host, port) for _ in 1:n]

mutable struct StaticSender <: AbstractSender
    sockets::Vector{Sockets.TCPSocket}
    server_size::Tuple{Int, Int}
    pixels::Vector{String}
    function StaticSender(socket, server_size, img)
        pixels = format_pixels(img)
        new(socket, server_size, pixels)
    end
end

function StaticSender(host::T_HOST, port::Int, img::AbstractArray)
    sockets = connect(host, port, Threads.nthreads())
    server_size = query_size(sockets[1])
    StaticSender(sockets, server_size, img)
end

function StaticSender(host::T_HOST, port::Int, img::AbstractString)
    StaticSender(host, port, load_img(img))
end

function socket_worker(::StaticSender, socket::Sockets.TCPSocket, pxs::Vector{String})
    @info "Started worker for socket $socket" 
    @async void_listener(socket)
    while isopen(socket)
        for px in pxs
            write(socket, px)
        end
        @debug "Iteration complete on socket $socket"
    end
end

function run(sender::StaticSender)
    @info "Starting StaticSender"
    n_sockets = length(sender.sockets)
    n_pixels = length(sender.pixels)
    pixels = Random.shuffle(sender.pixels)
    slices = slice_along(n_pixels, n_sockets)
    threads = map(1:n_sockets) do i 
        thread = Threads.@spawn socket_worker(sender, sender.sockets[i], pixels[slices[i]])
        @info "Created thread for socket $i"
        errormonitor(thread)
    end
    wait.(threads)
end

mutable struct State
    x::Int
    y::Int
    v::Int
    u::Int
    max_x::Int
    max_y::Int
    function State(max_x, max_y) 
        x = rand(1:max_x)
        y = rand(1:max_y)
        v = 10
        u = 10
        new(x, y, v, u, max_x, max_y)
    end
end

function update!(s::State)
    s.x += s.u
    if s.x > s.max_x
        s.x = s.max_x
        s.u *= -1
    elseif s.x < 1
        s.x = 1
        s.u *= -1
    end
    s.y += s.v
    if s.y > s.max_y
        s.y = s.max_y
        s.v *= -1
    elseif s.y < 1
        s.y = 1
        s.v *= -1
    end
end

mutable struct BounceSender <: AbstractSender
    sockets::Vector{Sockets.TCPSocket}
    server_size::Tuple{Int, Int}
    img_size::Tuple{Int, Int}
    pixels::Vector{Tuple{Int, Int, UInt32}}
    barrier::SyncBarriers.Barrier
    state::State
    function BounceSender(socket, server_size, img)
        img_size = size(img)[2:3]
        pixels = gather_pixels(img)
        state = State((server_size .- reverse(img_size))...)
        new(socket, server_size, img_size, pixels, SyncBarriers.Barrier(length(socket)), state)
    end
end

function BounceSender(host::T_HOST, port::Int, img::AbstractArray)
    sockets = connect(host, port, Threads.nthreads())
    server_size = query_size(sockets[1])
    BounceSender(sockets, server_size, img)
end

function BounceSender(host::T_HOST, port::Int, img::AbstractString)
    BounceSender(host, port, load_img(img))
end

function socket_worker(sender::BounceSender, i::Int, pxs::Vector{Tuple{Int, Int, UInt32}})
    @info "Started worker for socket $i" 
    @async void_listener(sender.sockets[i])
    socket = sender.sockets[i]
    barrier = sender.barrier[i]
    while isopen(socket)
        if i == 1
            update!(sender.state)
            @debug "Update state on socket $i" sender.state
        else
            @debug "Waiting on state update for $i"
        end
        SyncBarriers.cycle!(barrier)
        for px in pxs
            write(socket, msg_pixel(px[1] + sender.state.x, px[2] + sender.state.y, px[3]))
        end
        @debug "Completed write on socket $i"
        SyncBarriers.cycle!(barrier)
    end
end

function run(sender::BounceSender)
    @info "Starting BounceSender"
    n_sockets = length(sender.sockets)
    n_pixels = length(sender.pixels)
    pixels = Random.shuffle(sender.pixels)
    slices = slice_along(n_pixels, n_sockets)
    threads = map(1:n_sockets) do i 
        thread = Threads.@spawn socket_worker(sender, i, pixels[slices[i]]) 
        @info "Created thread for socket $i"
        errormonitor(thread)
    end
    wait.(threads)
end


