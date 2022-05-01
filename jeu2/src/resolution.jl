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
    @variable(m, 0<= horiz[1:(nr+1),1:nc]<=1, Int) #horizontal palisades
    @variable(m, 0<= vertic[1:nr,1:(nc+1)]<=1, Int) #vertical palisades
    
    @variable(m, 0<= horiz_test_pos[1:(nr+1),1:nc,1:K]<=1, Int)
    @variable(m, 0<= horiz_test_neg[1:(nr+1),1:nc,1:K]<=1, Int)
    
    @variable(m, 0<= vertic_test_pos[1:(nr+1),1:nc,1:K]<=1, Int)
    @variable(m, 0<= vertic_test_neg[1:(nr+1),1:nc,1:K]<=1, Int)
    
    #les serpents servant à vérifier la connexité
    cellSize= div(nr*nc,K)
    passage = min(4,cellSize-1)
    @variable(m, 0<=snakes[1:K,1:(cellSize*passage),1:nr, 1:nc, 1:nr, 1:nc]<=1, Int)
    
    
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
        @constraint(m,horiz[1,j]==1)
        @constraint(m,horiz[nr+1,j]==1)
    end
    
    for i in 1:nr
        @constraint(m,vertic[i,1]==1)
        @constraint(m,vertic[i,nc+1]==1)
    end
        
    #contraintes de placement des palissades
    
    for i in 2:nr
       for j in 1:nc
           for k in 1:K
                @constraint(m, horiz[i,j] + cases[i-1,j,k] + cases[i,j,k] <=2) 
                
                @constraint(m, horiz_test_pos[i,j,k] - horiz_test_neg[i,j,k] == cases[i,j,k] + sum( cases[i-1,j,h] for h in filter(x->x !=k, 1:K)) -1 )
                @constraint(m, horiz_test_pos[i,j,k] + horiz_test_neg[i,j,k] <= 1)
                @constraint(m, 1-horiz[i,j] + horiz_test_pos[i,j,k] + horiz_test_neg[i,j,k] <=1)
           end
       end
    end
    
    for i in 1:nr
       for j in 2:nc
           for k in 1:K
                @constraint(m, vertic[i,j] + cases[i,j-1,k] + cases[i,j,k] <=2) 
                
                @constraint(m, vertic_test_pos[i,j,k] - vertic_test_neg[i,j,k] == cases[i,j,k] + sum( cases[i,j-1,h] for h in filter(x->x !=k, 1:K)) -1 )
                @constraint(m, vertic_test_pos[i,j,k] + vertic_test_neg[i,j,k] <= 1)
                @constraint(m, 1-vertic[i,j] + vertic_test_pos[i,j,k] + vertic_test_neg[i,j,k] <=1)
           end
       end
    end
    #contraintes sur le nombre de palissades autour des cases
    for i in 1:nr
        for j in 1:nc
            if(t[i,j] > 0)
                @constraint(m, vertic[i,j] + vertic[i,j+1] + horiz[i,j] + horiz[i+1,j] == t[i,j])
            end
        end
    end
    
    
    ##serpents
    
    
    for k in 1:K
        for step in 1:(cellSize*passage)
           for i in 1:nr
               for j in 1:nc
                   for u in 1:nr
                       for v in 1:nc
                           if ( (u!=i-1 && u!=i+1) || v!=j ) && ( u!=i || (v!=j-1 && v!=j+1) )
                               @constraint(m,snakes[k,step,i,j,u,v]==0) #un serpent ne peut se déplacer que sur une case adjacente  
                           end
                           
                           @constraint(m,2*(1-snakes[k,step,i,j,u,v]) + cases[i,j,k] + cases[u,v,k] >=2) # un serpent ne peut pas sortir d'une zone
                           if step >=2
                               @constraint(m, 1 - snakes[k,step,i,j,u,v] + sum( snakes[k,step-1,x,y,i,j] for x in 1:nr for y in 1:nc) >=1) #si un serpent sort d'une case, il doit y être venu
                           end
                       end
                   end
               end
           end
        end
    end
    
    
    for k in 1:K
        for step in 1:(cellSize*passage)
            @constraint(m, sum( snakes[k,step,i,j,u,v] for i in 1:nr for j in 1:nc for u in 1:nr for v in 1:nc ) == 1)  # à chaque step et pour chaque zone, on veut un unique déplacement de serpent
        end
    end
    
    #pour chaque case d'une zone k, le serpent k doit y passager
    
    for k in 1:K
  
        for i in 1:nr
            for j in 1:nc
                @constraint(m, cases[i,j,k] <= sum(snakes[k,step,i,j,u,v] + snakes[k,step,u,v,i,j] for u in 1:nr for v in 1:nc for step in 1:(cellSize*passage) ) )
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
    if JuMP.primal_status(m) != NO_SOLUTION
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,JuMP.value.(cases), JuMP.value.(horiz), JuMP.value.(vertic)
   else
   	return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start,-1,-1,-1
   end
    
end


function initGrids(t::Array{Int64,2}, n::Int64, p::Int64)
    regions = Array{Int64}(undef, n, p)
    for y in 1:n
        for x in 1:p
            regions[y,x] = (y-1)*p + x
        end
    end
    sizes = Array{Int64}(undef, n, p)
    fill!(sizes, 1)
    exceed = Array{Int64}(undef, n, p)
    fill!(exceed, 5)
    for y in 1:n
        for x in 1:p
            if t[y, x] != -1
                exceed[y, x] = 4 - t[y, x]
            end
        end
    end
    return regions, sizes, exceed
end


function firstHeuristic(regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64, x::Int64, y::Int64, maxSize::Int64)
    if exceed[y, x] == 0 || sizes[y, x] == maxSize
        return -1
    end
    if exceed[y, x] == 5
        return sizes[y, x]
    else
        return maxSize*(exceed[y, x] + numNbEqI(regions, n, p, x, y, regions[y, x])) + sizes[y, x]
    end
end


function secondHeuristic(regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64, x::Int64, y::Int64, maxSize::Int64)
    if exceed[y, x] == 0 || sizes[y, x] == maxSize
        return -1
    end

    score = div(firstHeuristic(regions, sizes, exceed, n, p, x, y, maxSize), 2)

    dx = 1
    dy = 0
    temp = -1

    for i in 1:4
        temp = dy
        dy = dx
        dx = -temp
    
        nx = x+dx
        ny = y+dy
        if nx >= 1 && nx <= p && ny >= 1 && ny <= n
            score += sizes[ny, nx]
        else
            score += maxSize
        end
    end
    return score
end


function voisins(regions::Array{Int64, 2}, sizes::Array{Int64, 2}, exceed::Array{Int64, 2},
    n::Int64, p::Int64, x::Int64, y::Int64, maxSize::Int64)
    res = Array{Array{Int64, 1}}(undef, 4)

    dx = 1
    dy = 0
    temp = -1
    for i in 1:4
        temp = dy
        dy = dx
        dx = -temp
    
        nx = x+dx
        ny = y+dy
        res[i] = [nx, ny, -1]
        if nx >= 1 && nx <= p && ny >= 1 && ny <= n
            if regions[y, x] == regions[ny, nx]
                res[i][3] = -1
            else
                res[i][3] = secondHeuristic(regions, sizes, exceed, n, p, nx, ny, maxSize)
            end
        else
            res[i][3] = -1
        end
    end
    return res
end


function paliEnlevable(regions::Array{Int64, 2}, sizes::Array{Int64, 2}, exceed::Array{Int64, 2},
    n::Int64, p::Int64, x::Int64, y::Int64, maxSize::Int64)
    tailleFus = Array{Int64}(undef, 0) #tailles rajoutees avec fusion avec region concerne
    corr_reg = Array{Int64}(undef, 0) #regions correspondantes
    minusPali = Array{Int64}(undef, 0) #palissades en moins en fusionnant avec region concerne
    indPlus = -1 #Indice d'une region avec plusieurs frontieres communes

    vois = voisins(regions, sizes, exceed, n, p, x, y, maxSize)
    for v in vois
        if v[3] >= 0
            vx = v[1]
            vy = v[2]
            knownReg = indexin(regions[vy, vx], corr_reg)[1]
            if knownReg === nothing
                push!(corr_reg, regions[vy, vx])
                push!(tailleFus, sizes[vy, vx])
                push!(minusPali, 1)
            else
                minusPali[knownReg] += 1
                indPlus = knownReg
            end
        end
    end

    ordTaille = sortperm(tailleFus)
    lessPali1 = 0
    actTaille = sizes[y, x]

    for i in 1:size(corr_reg, 1)

        realInd = ordTaille[i]
        if actTaille + tailleFus[realInd] <= maxSize #Si fusion avec region fait pas region trop grande
            lessPali1 += minusPali[realInd] #Alors fusion et enlevement des palissades
            actTaille += tailleFus[realInd]
        end
    end

    lessPali2 = -1
    if indPlus != -1

        actTaille = sizes[y, x] + tailleFus[indPlus]
        if actTaille <= maxSize

            lessPali2 = minusPali[indPlus]
            for i in 1:size(corr_reg, 1)

                realInd = ordTaille[i]
                if realInd != indPlus && actTaille + tailleFus[realInd] <= maxSize
                    lessPali2 += minusPali[realInd]
                    actTaille += tailleFus[realInd]
                end
            end
        end
    end

    return max(lessPali1, lessPali2)
end


function oncologist(regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64, maxSize::Int64)
    for y in 1:n #On traque les impossibilites une premiere fois
        for x in 1:p

            #Base sur la taille de la region et des regions adjacentes, checke si on pourrait
            #encore supprimer assez de palissades
            if exceed[y, x] != 5
                lessPali = paliEnlevable(regions, sizes, exceed, n, p, x, y, maxSize)
                if exceed[y, x] - lessPali > 0 || exceed[y, x] < 0 #Arrive jamais maintenant normalement
                    return true
                end
            end

        end
    end
    return false
end


function fusion(regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    n::Int64, p::Int64, x1::Int64, y1::Int64, x2::Int64, y2::Int64)
    connComp(regions, regions, n, p, x2, y2, regions[y2, x2], regions[y1, x1]) #Fusion des regions
    totSize = sizes[y1, x1] + sizes[y2, x2]
    connComp(regions, sizes, n, p, x1, y1, regions[y1, x1], totSize) #Update des tailles
end


function fixExceed(t::Array{Int64, 2}, regions::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64)
    for y in 1:n
        for x in 1:p
            if t[y, x] != -1
                exceed[y, x] = 4 - numNbEqI(regions, n, p, x, y, regions[y, x]) - t[y, x]
                if exceed[y, x] < 0
                    return false
                end
            end
        end
    end
    return true
end


function fixHeuristic(regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64, states::Array{Array{Int64, 1}, 1}, maxSize::Int64)
    for e in states
        x = e[1]
        y = e[2]
        e[3] = firstHeuristic(regions, sizes, exceed, n, p, x, y, maxSize)
    end
end


function checkSizes(sizes::Array{Int64, 2}, n::Int64, p::Int64, maxSize::Int64)
    for y in 1:n
        for x in 1:p
            if sizes[y, x] != maxSize
                return false
            end
        end
    end
    return true
end

function checkExceed(exceed::Array{Int64, 2}, n::Int64, p::Int64)
    for y in 1:n
        for x in 1:p
            if exceed[y, x] != 0 && exceed[y, x] != 5
                return false
            end
        end
    end
    return true
end


function debugGrids(regions::Array{Int64, 2}, sizes::Array{Int64, 2}, exceed::Array{Int64, 2})
    printTab(regions)
    printTab(sizes)
    printTab(exceed)
end


#Stocker regions et sizes pour le backtracking
function updateGrids(t::Array{Int64, 2}, regions::Array{Int64, 2}, sizes::Array{Int64, 2},
    exceed::Array{Int64, 2}, n::Int64, p::Int64, states::Array{Array{Int64, 1}, 1}, maxSize::Int64)

    if oncologist(regions, sizes, exceed, n, p, maxSize)
        return false
    end

    stoRegions = deepcopy(regions)
    stoSizes = deepcopy(sizes)

    kyloRen = sortperm(states, by=(x->x[3]), rev=true) #aurait du s'appeler firstOrder (on s'amuse comme on peut)
    indice = 1
    while indice <= n*p
        e = states[kyloRen[indice]]
        x = e[1]
        y = e[2]
        vois = voisins(regions, sizes, exceed, n, p, x, y, maxSize)
        sort!(vois, by=(x->x[3]), rev=true)
        for v in vois
            if v[3] >= 0
                vx = v[1]
                vy = v[2]
                if sizes[vy, vx] + sizes[y, x] <= maxSize #Fusion a priori permise
                    fusion(regions, sizes, n, p, x, y, vx, vy)
                    if fixExceed(t, regions, exceed, n, p)
                        if sizes[y, x] == maxSize
                            if checkSizes(sizes, n, p, maxSize) && checkExceed(exceed, n, p)
                                return true
                            end
                        end
                        fixHeuristic(regions, sizes, exceed, n, p, states, maxSize)
                        finished = updateGrids(t, regions, sizes, exceed, n, p, states, maxSize)
                        if finished
                            return true
                        end
                    end
                    copyto!(regions, stoRegions)
                    copyto!(sizes, stoSizes)
                    fixExceed(t, regions, exceed, n, p)
                    fixHeuristic(regions, sizes, exceed, n, p, states, maxSize)
                end
            end
        end
        if exceed[y, x] != 5 && exceed[y, x] > 0 #On ne reussit plus a diminuer le nb de palissades autour de x, y
            return false
        end
        indice += 1
    end
    if maxSize == 1
        return checkSizes(sizes, n, p, maxSize) && checkExceed(exceed, n, p)
    else
        return false
    end
end


function normalizing(t::Array{Int64})
    n = size(t, 1)
    p = size(t, 2)
    corres = Array{Int64}(undef, 0)
    res = Array{Int64}(undef, n, p)
    for y in 1:n
        for x in 1:p
            numReg = indexin(t[y, x], corres)[1]
            if numReg === nothing
                push!(corres, t[y, x])
                numReg = size(corres, 1)
            end
            res[y, x] = numReg
        end
    end
    return res
end


"""
Heuristically solve an instance
"""
function heuristicSolve(t::Array{Int64, 2}, regionSize::Int64)
    n = size(t, 1)
    p = size(t, 2)
    regions, sizes, exceed = initGrids(t, n, p)

    states = Array{Array{Int64, 1}}(undef, n*p)

    for y in 1:n
        for x in 1:p
            indice = (y-1)*p + x
            states[indice] = [x, y, -1]
        end
    end
    fixHeuristic(regions, sizes, exceed, n, p, states, regionSize)

    solved = updateGrids(t, regions, sizes, exceed, n, p, states, regionSize)

    isOpti = false
    if solved
        isOpti = true
        #println("Instance solved !")
    else
        #println("Not solved :/")
    end


    corrige = normalizing(regions)
    horiz, vertic = generatePali(corrige)
    #displayGrid(corrige, horiz, vertic)
    return isOpti, corrige, horiz, vertic

    # TODO
    # println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end


function wrapSolve(fname::String)
    t, horiz, vertic, regionSize = readInputFile(fname)
    return heuristicSolve(t, regionSize)
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
        t, horiz, vertic, cellSize= readInputFile(dataFolder * file)
        
        solved_t = copy(t)
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
            
            outputFile = resolutionFolder[methodId] * "/stats_" * file
            solFile = resolutionFolder[methodId] * "/res_" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")
                sout = open(solFile, "w")

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    #println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime, cases, hori, verti = cplexSolve(t,nr,nc,K)
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        #println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout")
                        for i in 1:nr
                            for j in 1:nc
                                for k in 1:K
                                   if cases[i,j,k]!=0
                                       solved_t[i,j]=k
                                   end
                                end  
                            end
                        end

                        for i in 1:(nr-1)
                            for j in 1:nc
                                horiz[i,j]=hori[1+i,j]                                
                            end
                        end

                        for i in 1:nr
                            for j in 1:(nc-1)                                
                                vertic[i,j]=verti[i,1+j]                                   
                            end
                        end
                    end
                    
                    writeOutputFile(sout, solved_t, horiz, vertic, cellSize)
                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    
                    # TODO 
                    #println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, solved_t, horiz, vertic = heuristicSolve(t, cellSize)
                    
                    # Stop the chronometer
                    resolutionTime = time() - startingTime

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        # println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        writeOutputFile(sout, solved_t, horiz, vertic, cellSize)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                # println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
                close(sout)
            end


            # Display the results obtained with the method on the current instance
            #include(outputFile)
            displayGrid(t, horiz, vertic, true)
            displayGrid(solved_t, horiz, vertic, false)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
