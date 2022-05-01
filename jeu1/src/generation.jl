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
    	new_coord = Int64(floor(n*n*rand()))
    	while(marked_coord[1+new_coord%(n*n)])
    	    new_coord+=1
    	end
    	marked_coord[1+new_coord%(n*n)] = true
    	append!(coordinates,1+new_coord%(n*n))    	
    end
    
    for coord in coordinates
        if coord in [1 n n*n-n+1 n*n]
           instance[1+(coord-1)÷n, 1+(coord-1)%n] = Int64(floor(5*rand())) #4 is the max
           
        elseif 1+(coord-1)%n in [1 n] || 1+(coord-1)÷n in [1 n]
            
            instance[1+(coord-1)÷n, 1+(coord-1)%n] = Int64(floor(7*rand())) #6 is the max
        else
            instance[1+(coord-1)÷n, 1+(coord-1)%n] = Int64(floor(10*rand())) #10 is the max
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
    #println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    dim_min = 99
    dim_max = 99
    step_density = 0.1
    nb_repetition = 1
    
    
    
    for n in dim_min:dim_max
       
        ##Naming the file##
        if n<10
        instance_name_n= "instance_0"* string(n)* "D"
        else
        instance_name_n= "instance_"* string(n) * "D"
        end
        
        for d in 0.1:step_density:0.5
        
            ##Naming the file##
            instance_name_d = instance_name_n * string(Int64(d*10))*"_"
            for k in 1:nb_repetition
                if k<10
                    instance_name = instance_name_d *"00"*string(k)
                else
                    instance_name = instance_name_d * "0"*string(k)
                end
                 
                 ##Writing in the file##
                 if !isfile(instance_name)
                    output_file = open("../data/" * instance_name * ".txt", "w")
                    instance = generateInstance(n,d)
                    
                    for i in 1:n
                        for j in 1:(n-1)
                            if instance[i,j]!=-1
                                print(output_file,instance[i,j],",")
                            else
                               print(output_file," ,")
                            end                            
                        end
                        ##last colomn
                        if instance[i,n]!=-1
                           println(output_file,instance[i,n])
                        else
                           println(output_file," ")
                        end
                        
                    end
                    close(output_file)
                 end
                
                
            end
        end
    end
        
end



