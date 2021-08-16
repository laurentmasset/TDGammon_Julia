import julia
julia.install()

from julia import Main
Main.include("setup.jl")
