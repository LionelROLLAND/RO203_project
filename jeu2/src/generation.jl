# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    # TODO
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    
end

function deepSearch(t::Array{Int64, 2}, n::Int64, p::Int64, x_dep::Int64, y_dep::Int64, x_arr::Int64, y_arr::Int64)
	dx = 1
	dy = 0
end




"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



