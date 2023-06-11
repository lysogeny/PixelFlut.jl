module PixelFlut

import MiniFB
import Sockets
import ArgParse

T_HOST = Union{String,Sockets.IPAddr}

include("helpers.jl")
include("protocol.jl")
include("ui.jl")
include("server.jl")
include("viewer.jl")

end # module PixelFlut
