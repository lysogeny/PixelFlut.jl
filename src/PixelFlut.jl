module PixelFlut

import Mods
import MiniFB
import Sockets
import ArgParse

T_HOST = Union{String,Sockets.IPAddr}

include("helpers.jl")
include("protocol.jl")
include("ui.jl")
include("network.jl")
include("server.jl")
include("viewer.jl")

end # module PixelFlut
