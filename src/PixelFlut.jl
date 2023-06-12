module PixelFlut

import MiniFB
import Sockets
import ArgParse
import SyncBarriers
import Random

T_HOST = Union{String,Sockets.IPAddr}

include("helpers.jl")
include("protocol.jl")
include("io.jl")
include("ui.jl")
include("server.jl")
include("viewer.jl")
include("painter.jl")

end # module PixelFlut
