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
    #println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    
    instance = [ -1 for i in 1:(n*n)]
    instance = reshape(instance, (n,n))
    nb_coord = Int64(floor(n*n*density)) 

    marked_coord = [false for i in 1:(n*n)]
    coordinates = Array{Int64,1}(undef,0)
    
    for k in 1:nb_coord
    	new_coord = 1 + Int64(floor(n*n*rand()))
    	while(marked_coord[1+new_coord%(n*n)])
    	    new_coord+=1
    	end
    	marked_coord[1+new_coord%(n*n)] = true
    	append!(coordinates,new_coord)    	
    end
    
    for coord in coordinates
        
        if coord in [1 n n*n-n+1 n*n]
           instance[1+coord÷n, 1+coord%n] = Int64(floor(5*rand())) #4 is the max
           
        elseif coord%n in [1 0] || coord÷n in [1 0]
            
            instance[1+coord÷n, 1+coord%n] = Int64(floor(7*rand())) #6 is the max
        else
            instance[1+coord÷n, 1+coord%n] = Int64(floor(10*rand())) #10 is the max
        end
    end
    
    return instance
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



