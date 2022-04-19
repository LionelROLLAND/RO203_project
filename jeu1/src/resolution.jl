# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")


TOL = 0.00001

"""
Solve an instance with CPLEX

- Argument: 
	neighborhood : matrix of black squares neigbors
"""
function cplexSolve(neighborhood::Array{Int64,2})

    # Create the model
    m = Model(CPLEX.Optimizer)
     

    # TODO
    #println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")
          
    nr = size(neighborhood,1)
    nc = size(neighborhood,2)
    
    @variable(m, 0<= x[1:nr,1:nc] <= 1, Int)
    
    for i in 1:nr
        for j in 1:nc
            ###LES OUVERTS
            #Cas : ouvert de la grille
            
            if neighborhood[i,j] != -1 && 2<=i<=nr-1 && 2<=j<= nc-1
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0 1] for h in [-1 0 1] ) == neighborhood[i,j]  )
            end
            
            #Cas : ouvert sur la première ligne d'une matrice multiligne
            if neighborhood[i,j]!=-1 && 1==i<=nr-1 && 2<=j<=nc-1
            	@constraint(m, sum(x[i+k,j+h] for k in [0 1] for h in [-1 0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas : ouvert sur la dernière ligne d'une matrice multiligne
            if neighborhood[i,j] != -1 && 2<=i==nr && 2<=j<= nc-1
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0] for h in [-1 0 1] ) == neighborhood[i,j]  )
            end
          
            #Cas : ouvert sur la première colonne d'une matrice multicolonne
            if neighborhood[i,j] != -1 && 2<=i<=nr-1 && 1==j<= nc-1
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0 1] for h in [0 1] ) == neighborhood[i,j]  )
            end
            
            #Cas ouvert sur la dernière colonne d'une matrice multicolonne
            if neighborhood[i,j] != -1 && 2<=i<=nr-1 && 2<=j== nc
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0 1] for h in [-1 0] ) == neighborhood[i,j]  )
            end
            
            ###LES BORDS            
            #Cas : première ligne et première colonne d'une matrice multiligne
            if neighborhood[i,j]!=-1 && 1==i<=nr-1 && 1==j<=nc-1
            	@constraint(m, sum(x[i+k,j+h] for k in [0 1] for h in [0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas :  première ligne et dernière colonne d'une matrice multiligne
            if neighborhood[i,j]!=-1 && 1==i<=nr-1 && 2<=j==nc
            	@constraint(m, sum(x[i+k,j+h] for k in [0 1] for h in [-1 0] ) == neighborhood[i,j]  )            
            end
            
           
            #Cas : dernière ligne et première colonne d'une matrice multiligne
            if neighborhood[i,j] != -1 && 2<=i==nr && 1==j<= nc-1
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0] for h in [0 1] ) == neighborhood[i,j]  )
            end
            
            #Cas : dernière ligne et dernière colonne d'une matrice multiligne
            if neighborhood[i,j] != -1 && 2<=i==nr && 2<=j== nc
                @constraint(m, sum(x[i+k,j+h] for k in [-1 0] for h in [-1 0] ) == neighborhood[i,j]  )
            end
            
            
            
            ###LES CAS SINGULIERS
            #Cas : ouvert Matrice ligne
            if neighborhood[i,j]!=-1 && 1==i==nr && 2<=j<=nc-1
            	@constraint(m, sum(x[i,j+h] for h in [-1 0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas : première colonne Matrice ligne
            if neighborhood[i,j]!=-1 && 1==i==nr && 1==j<=nc-1
            	@constraint(m, sum(x[i,j+h] for h in [0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas : dernière colonne Matrice ligne
            if neighborhood[i,j]!=-1 && 1==i==nr && 2<=j==nc
            	@constraint(m, sum(x[i,j+h] for h in [-1 0] ) == neighborhood[i,j]  )            
            end
            
            #Cas : ouvert Matrice colonne
            if neighborhood[i,j]!=-1 && 2<=i<=nr-1 && 1==j==nc
            	@constraint(m, sum(x[i+k,j] for k in [-1 0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas : première ligne Matrice colonne
            if neighborhood[i,j]!=-1 && 1==i<=nr-1 && 1==j==nc
            	@constraint(m, sum(x[i+k,j] for k in [0 1] ) == neighborhood[i,j]  )            
            end
            
            #Cas : dernière ligne Matrice colonne
            if neighborhood[i,j]!=-1 && 2<=i==nr && 1==j==nc
            	@constraint(m, sum(x[i+k,j] for k in [-1 0] ) == neighborhood[i,j]  )            
            end
            
            #Cas : singulier 
            if neighborhood[i,j]!=-1 && 1==i==nr && 1==j==nc
            	@constraint(m, sum(x[i,j] ) == neighborhood[i,j]  )            
            end
            
        end
    end
    
   
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    # 3 - Value of the found admissible point
   
   
   
   if JuMP.primal_status(m) != NO_SOLUTION
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,JuMP.value.(x)
   else
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,0
   end
   
    
    
    
end 

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        
        # TODO
        #println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        
        neighborhood=readInputFile(dataFolder * file)

             
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file
	  
            # If the instance has not already been solved by this method
            if !isfile(outputFile)
           
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    #println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
              
                    # Solve it and get the results
              
                    isOptimal, resolutionTime, admissible_point_x = cplexSolve(neighborhood)
                    nr=size(admissible_point_x,1)
                    nc=size(admissible_point_x,2)
                    display_x = Array{String,2}(undef,nr,nc)
                        
                    for i in 1:nr
                       for j in 1:nc
                           if(admissible_point_x[i,j]==1)
                               display_x[i,j]="X"
                           else
                               display_x[i,j]="O"
                           end
                       end
                    end
                   display(display_x)####
            
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        #println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout")
                        for i in 1:nr
                           print(fout,display_x[i,1])
                           for j in 2:nc
                               print(fout," ",display_x[i,j])
                           end
                           print(fout,"\n")
                         end                       
                      	print(fout,"\n")
                        
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                     
                    if isOptimal

                        # TODO
                        #println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end

            # Display the results obtained with the method on the current instance
            #include(outputFile)      
            
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
