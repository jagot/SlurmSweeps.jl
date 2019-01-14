module SlurmSweeps
using Logging
using DelimitedFiles
using Random
using Sockets

include("server.jl")
include("client.jl")
include("instance.jl")
include("setup.jl")

end # module
