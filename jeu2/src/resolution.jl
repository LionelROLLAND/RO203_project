# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Array{Int64, 2}, nr::Int64,nc::Int64,K::Int64)

    # Create the model
    m = Model(CPLEX.Optimizer)
	
    # TODO
    #println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")
    

    
    @variable(m, 0<= cases[1:nr,1:nc,1:K] <= 1, Int) #cases
    @variable(m, 0<= palissades[1:(nr+1), 1:(nc+1), 1:(nr+1), 1:(nc+1)]<=1, Int) #palissades
    
    
    #variable utilitaire servant à décider où mettre une palissade
    @variable(m, 0<=east_pos[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    @variable(m, 0<=east_neg[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    
    @variable(m, 0<=north_pos[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    @variable(m, 0<=north_neg[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)

    @variable(m, 0<=west_pos[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    @variable(m, 0<=west_neg[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
  
    @variable(m, 0<=south_pos[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    @variable(m, 0<=south_neg[1:(nr+1), 1:(nc+1), 1:K]<=1, Int)
    
    #les serpents servant à vérifier la connexité
    cellSize= div(nr*nc,K)
    @variable(m, 0<=snakes[1:K,1:(cellSize*(cellSize-1)),1:(nr+1), 1:(nc+1), 1:(nr+1), 1:(nc+1)]<=1, Int)
    
    
    ###CONSTRAINTS
    for i in 1:nr
        for j in 1:nc
            #Une seule zone par case
            @constraint(m, sum(cases[i,j,k] for k in 1:K) == 1) 
        end     
    end
    
    for k in 1:K
        #Dans chaque zone on a nr*nc/K cases
        @constraint(m, sum(cases[i,j,k] for i in 1:nr for j in 1:nc) == cellSize) 
    end
    
    ##palissades
    
    #les bords de la grille
    for j in 1:nc
        @constraint(m,palissades[1,j,1,j+1]==1)
        @constraint(m,palissades[nr+1,j,nr+1,j+1]==1)
    end
    
    for i in 1:nr
        @constraint(m,palissades[i,1,i+1,1]==1)
        @constraint(m,palissades[i,nc+1,i+1,nc+1]==1)
    end
    
    #une palissade ne se place que dans les directions des 4 points cardinaux
    for i in 1:(nr+1)
        for j in 1:(nc+1)
            for u in 1:(nr+1)
                for v in 1:(nc+1)
                    if ( (u!=i-1 && u!=i+1) || v!=j ) && ( u!=i || (v!=j-1 && v!=j+1) )        
                        @constraint(m,palissades[i,j,u,v]==0)
                    end
                end
            end
        end
    end
    
    #contraintes de placement des palissades
    
    for i in 2:nr
        for j in 2:nc
            for k in 1:K
                @constraint(m,east_pos[i,j,k] - east_neg[i,j,k]== cases[i,j,k] + sum( cases[i-1,j,h] for h in filter(x->x != k, 1:K)) -1 ) # -1 et 1, il faut mettre une palissade; 0, indeterminé
                @constraint(m,east_pos[i,j,k] + east_neg[i,j,k]<=1)
                @constraint(m, 1-palissades[i,j,i,j+1] + east_pos[i,j,k] + east_neg[i,j,k] <=1) #condition : -1 ou 1 => palissade
                @constraint(m, cases[i,j,k] + cases[i-1,j,k] + palissades[i,j,i,j+1] <= 2)# condition : palissade => ij et i(j+1) pas dans la même zone
                
                @constraint(m,north_pos[i,j,k] - north_neg[i,j,k]== cases[i-1,j-1,k] + sum( cases[i-1,j,h] for h in filter(x->x != k, 1:K)) -1 )
                @constraint(m,north_pos[i,j,k] + north_neg[i,j,k]<=1)
                @constraint(m, 1-palissades[i,j,i-1,j] + north_pos[i,j,k] + north_neg[i,j,k] <=1)
                @constraint(m, cases[i-1,j-1,k] + cases[i-1,j,k] + palissades[i,j,i-1,j] <= 2)
                
                @constraint(m,west_pos[i,j,k] - west_neg[i,j,k]== cases[i-1,j-1,k] + sum( cases[i,j-1,h] for h in filter(x->x != k, 1:K)) -1 )
                @constraint(m,west_pos[i,j,k] + west_neg[i,j,k]<=1)
                @constraint(m, 1-palissades[i,j,i,j-1] + west_pos[i,j,k] + west_neg[i,j,k] <=1)
                @constraint(m, cases[i-1,j-1,k] + cases[i,j-1,k] + palissades[i,j,i,j-1] <= 2)
                
                @constraint(m,south_pos[i,j,k] - south_neg[i,j,k]== cases[i,j,k] + sum( cases[i,j-1,h] for h in filter(x->x != k, 1:K)) -1 )
                @constraint(m,south_pos[i,j,k] + south_neg[i,j,k]<=1)
                @constraint(m, 1-palissades[i,j,i+1,j] + south_pos[i,j,k] + south_neg[i,j,k] <=1)
                @constraint(m, cases[i,j,k] + cases[i,j-1,k] + palissades[i,j,i+1,j] <= 2)
               
            end
        end
    end
    
    #contraintes sur le nombre de palissades autour des cases
    for i in 1:nr
        for j in 1:nc
            if(t[i,j] > 0)
                @constraint(m, palissades[i,j,i,j+1] + palissades[i,j,i+1,j] + palissades[i+1,j,i+1,j+1] + palissades[i+1,j+1,i,j+1] == t[i,j])
            end
        end
    end
    
    
    ##serpents
    
    
    for k in 1:K
        for step in 1:(cellSize*(cellSize-1))
           for i in 1:nr
               for j in 1:nc
                   for u in 1:nr
                       for v in 1:nc
                           if ( (u!=i-1 && u!=i+1) || v!=j ) && ( u!=i || (v!=j-1 && v!=j+1) )   
                               @constraint(m,snakes[k,step,i,j,u,v]==0) #un serpent ne peut se déplacer que sur une case adjacente  
                           end
                           
                           @constraint(m,2*(1-snakes[k,step,i,j,u,v]) + cases[i,j,k] + cases[u,v,k] >=2) # un serpent ne peut pas sortir d'une zone
                           if step >=2
                               @constraint(m, 1 - snakes[k,step,i,j,u,v] + sum( snakes[k,step-1,x,y,u,v] for x in 1:nr for y in 1:nc) >=1) #si un serpent sort d'une case, il doit y être venu
                           end
                       end
                   end
               end
           end
        end
    end
    
    
    for k in 1:K
        for step in 1:(cellSize*(cellSize-1))
            @constraint(m, sum( snakes[k,step,i,j,u,v] for i in 1:nr for j in 1:nc for u in 1:nr for v in 1:nc ) == 1)  # à chaque step et pour chaque zone, on veut un unique déplacement de serpent
        end
    end
    
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    if JuMP.primal_status(m) != NO_SOLUTION
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,JuMP.value.(cases), JuMP.value.(palissades)
   else
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,-1,-1
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
        t, horiz, vertic,cellSize= readInputFile(dataFolder * file)
        
        nr = size(t,1)
        nc = size(t,2)
    
       #number of regions
    
       if cellSize > 0
          K=div(nr*nc,cellSize)
       else
          K=nc
       end
        
       
        # TODO
        #println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
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
                    isOptimal, resolutionTime, cases, palissades = cplexSolve(t,nr,nc,K)
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        #println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout")
                        for i in 1:nr
                            for j in 1:nc
                                for k in 1:K
                                   if cases[i,j,k]!=0
                                       t[i,j]=k
                                   end
                                end  
                            end
                        end

                        for i in 1:(nr-1)
                            for j in 1:nc
                                if palissades[1+i,j,1+i,j+1] == 1
                                    horiz[i,j]=1
                                end
                            end
                        end

                        for i in 1:nr
                            for j in 1:(nc-1)
                                if palissades[i,1+j,i+1,1+j]==1
                                    vertic[i,j]=1    
                                end
                            end
                        end
                    end
                    
                    writeOutputFile(fout,t,horiz,vertic,cellSize)
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
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
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
            displayGrid(t, horiz, vertic, true)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
