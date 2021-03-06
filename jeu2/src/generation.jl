# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

#count(u->(u==-1), t[1,1:p])

#Affiche un tableau de maniere potable
function printTab(t::Array{Int64, 2})
    n = size(t, 1)
    p = size(t, 2)
    for y in 1:n
        println(t[y, 1:p])
    end
    print("\n")
end

function numNbEqI(t::Array{Int64, 2}, n::Int64, p::Int64, x::Int64, y::Int64, i_r::Int64) #Nombre de voisins egaux a i
    res = 0

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
            if t[ny,nx] == i_r
                res += 1
            end
        end
    end
    return res
end


#Traite t selon la composante connexe (basee sur reference, cases egales a comp)
#a laquelle appartient la case (x, y) 
function connComp(reference::Array{Int64, 2}, t::Array{Int64, 2}, n::Int64, p::Int64,
    x::Int64, y::Int64, comp::Int64=-1, newVal::Int64=-2)
    t[y,x] = newVal
    stoRef = reference[y, x]
    reference[y, x] = comp + 1
    
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
            if reference[ny,nx] == comp
                connComp(reference, t, n, p, nx, ny, comp, newVal)
            end
        end
    end
    reference[y, x] = stoRef
end

#Verifie que c'est legal (pas casser la connexite des cases vides) de placer une case a cet endroit
function isValidPlace(t::Array{Int64,2}, n::Int64, p::Int64, x::Int64, y::Int64)
    t_copy = deepcopy(t)
    
    dx = 1
    dy = 0
    temp = -1
    
    found = false
    
    i = 0
    nx = -1
    ny = -1
    while i < 4 && !found #On chope une case vide autour de l'emplacement prevu
        temp = dy #On fait "tourner" (dx, dy)
        dy = dx
        dx = -temp
        
        nx = x+dx
        ny = y+dy
        if nx >= 1 && nx <= p && ny >= 1 && ny <= n
            if t[ny,nx] == -1
                found = true
            end
        end
        i += 1
    end

    if found
        t_copy[y,x] = -3
        connComp(t_copy, t_copy, n, p, nx, ny, -1, -2)

        #=
        print("--\n")
        printTab(t)
        println(y, ", ", x)
        printTab(t_copy)
        print("--\n\n\n")
        =#

        #On checke que toutes les cases vides autour de l'emplacement sont dans la meme composante connexe
        for i in 1:4
            temp = dy
            dy = dx
            dx = -temp
        
            nx = x+dx
            ny = y+dy
            if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                if t[ny,nx] == -1 && t_copy[ny,nx] != -2
                    return false
                end
            end
        end
    end
    
    return true
end


#Construit une region dont certaines cases ont deja ete placees + appelle buildRegion
#pour continuer la generation
function recRegion(t::Array{Int64, 2}, n::Int64, p::Int64, full_size::Int64, remSize::Int64,
    i_region::Int64, x_adj::Array{Int64, 1}, y_adj::Array{Int64, 1}, n_adj::Int64)
    if remSize == 0
        return buildRegion(t, n, p, full_size, i_region-1)
    end

    if n_adj == 0
        return false
    end
    dx = 1
    dy = 0
    temp = -1

    next_cell = 1 + rem(abs(rand(Int64)), n_adj)

    I = 0
    while I < n_adj
        x = x_adj[next_cell]
        y = y_adj[next_cell]
        if isValidPlace(t, n, p, x, y)
            t[y,x] = i_region

            new_x_adj = deepcopy(x_adj)
            new_y_adj = deepcopy(y_adj)
            deleteat!(new_x_adj, next_cell)
            deleteat!(new_y_adj, next_cell)
            new_n_adj = n_adj-1

            for i in 1:4 #Rajoute les nouvelles cases adjacentes
                temp = dy
                dy = dx
                dx = -temp
        
                nx = x+dx
                ny = y+dy
                if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                    if t[ny,nx] == -1 && numNbEqI(t, n, p, nx, ny, i_region) == 1
                        push!(new_x_adj, nx)
                        push!(new_y_adj, ny)
                        new_n_adj += 1
                    end
                end
            end
            finished = recRegion(t, n, p, full_size, remSize-1, i_region, new_x_adj, new_y_adj, new_n_adj)
            if finished
                #println("+ ", y, ", ", x, "  : ", i_region, " -> ", remSize)
                return true
            end
            t[y,x] = -1
        end
        I += 1
        next_cell = 1 + rem(next_cell, n_adj)
    end
    return false
end


#Place la premiere case d'une region puis appelle recRegion pour finir
function buildRegion(t::Array{Int64,2}, n::Int64, p::Int64, full_size::Int64, i_region::Int64)
    if i_region == 0
        return true
    end

    dx = 1
    dy = 0
    temp = -1

    empty_cells = i_region*full_size
    first_cell = 1 + rem(abs(rand(Int64)), empty_cells) #le diviseur est le nb de cellule vides
    i_cell = 0
    x = 1
    y = 1
    
    I = 0
    while I < empty_cells
        #On parcourt jusqu'a trouver la first_cell-ieme cellule vide >= a l'actuelle
        while first_cell > 0
            x = 1 + rem(i_cell, p)
            y = 1 + div(i_cell, p)
            if t[y, x] == -1
                first_cell -= 1
            end
            i_cell = rem(i_cell+1, n*p)
        end
        if isValidPlace(t, n, p, x, y)
            t[y,x] = i_region


            x_adj = Array{Int64}(undef, 0)
            y_adj = Array{Int64}(undef, 0)
            n_adj = 0

            for i in 1:4
                temp = dy
                dy = dx
                dx = -temp
            
                nx = x+dx
                ny = y+dy
                if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                    if t[ny,nx] == -1
                        push!(x_adj, nx)
                        push!(y_adj, ny)
                        n_adj += 1
                    end
                end
            end

            finished = recRegion(t, n, p, full_size, full_size-1, i_region, x_adj, y_adj, n_adj)

            if finished
                #println("+ ", y, ", ", x, "  : ", i_region, " -> ", full_size)
                return true
            end
            t[y,x] = -1
        end
        first_cell = 1
        I += 1
    end
    return false
end

#Construit un tableau dont les cases comptent le nombre de palissades autour des cases du tableau argument
function countPali(t::Array{Int64,2})
    n = size(t,1)
    p = size(t,2)
    palis = Array{Int64}(undef, n, p)
    
    dx = 1
    dy = 0
    temp = -1

    for y in 1:n
        for x in 1:p
            n_pali = 0
            for i in 1:4
                temp = dy
                dy = dx
                dx = -temp
            
                nx = x+dx
                ny = y+dy
                if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                    if t[ny,nx] != t[y,x]
                        n_pali += 1
                    end
                else
                    n_pali += 1
                end
            end
            palis[y,x] = n_pali
        end
    end
    return palis
end


function diviseurs(n::Int64)
    if n == 0
        return [-1], -1
    end
    if n == 1
        return [1], 1
    end

    d = 2
    while rem(n, d) != 0
        d += 1
    end
    p = 1
    rest = div(n, d)
    while rem(rest, d) == 0
        p += 1
        rest = div(rest, d)
    end
    new_div, new_n = diviseurs(rest)
    res = Array{Int64}(undef, 0)
    for i in 0:p
        for new_d in new_div
            push!(res, (d^i)*new_d)
        end
    end
    return res, (p+1)*new_n
end


"""
Generate an n*p grid with a given density

Argument
- n: height of the grid
- p: width of the grid
- size: size of each region (number of cells)
- density: probability in [0, 1] of a cell to have an initial value in the grid
"""

function generateInstance(n::Int64, p::Int64, regionSize::Int64, density::Float64)

    t = Array{Int64}(undef, n, p)
    fill!(t, -1)
    n_regions = div(n*p, regionSize)
    buildRegion(t, n, p, regionSize, n_regions)
    pali = countPali(t)

    res = Array{Int64}(undef, n, p)
    fill!(res, -1)
    for y in 1:n
        for x in 1:p
            if rand(Float64) < density
                res[y,x] = pali[y,x]
            end
        end
    end

    horiz = Array{Int64}(undef, n-1, p)
    vertic = Array{Int64}(undef, n, p-1)
    fill!(horiz, 0)
    fill!(vertic, 0)
    
    #=
    displayGrid(t, horiz, vertic)
    displayGrid(res, horiz, vertic)

    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    =#
    
    return res, horiz, vertic
    
end


#Construit les tableaux des palissades en fonction du tableau des regions
function generatePali(t::Array{Int64, 2})
    n = size(t,1)
    p = size(t,2)
    horiz = Array{Int64}(undef, n-1, p)
    vertic = Array{Int64}(undef, n, p-1)
    fill!(horiz, 0)
    fill!(vertic, 0)
    
    dx = 1
    dy = 0
    temp = -1

    for y in 1:n
        for x in 1:p
            for i in 1:4
                temp = dy
                dy = dx
                dx = -temp
            
                nx = x+dx
                ny = y+dy
                if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                    if dx != 0 && t[y, x] != t[ny, nx]
                        vertic[y, div(x+nx, 2)] = 1
                    end
                    if dy != 0 && t[y,x] != t[ny,nx]
                        horiz[div(y+ny, 2), x] = 1
                    end
                end
            end
        end
    end
    return horiz, vertic
end



"""
Generate all the instances
"""
function generateDataSet(nbInstance::Int64, sizeMax::Int64, pref::String="instance_", suff::String=".txt",
    randSize::Bool=false)
    print("\n0 % done")
    for i in 1:nbInstance
        n = 1 + rem(abs(rand(Int64)), sizeMax)
        p = 1 + rem(abs(rand(Int64)), sizeMax)
        l_div, n_div = diviseurs(n*p)
        cellSize = n
        if randSize
            cellSize = l_div[1+rem(abs(rand(Int64)), n_div)]
        end
        t, horiz, vertic = generateInstance(n, p, cellSize, rand(Float64))
        writeOutputFile("../data/"*pref * string(i) * suff, t, horiz, vertic, cellSize)
        print("\r"*string(div(100*i, nbInstance))*" % done")
    end
    print("\n")
    #println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end

#Genere des instances pour des tests specifiques
function testDensity(nbInstance::Int64=15, pref::String="densInstance_", suff::String=".txt")
    print("\n0 % done")
    for i in 1:nbInstance
        n = 3
        p = 5
        cellSize = 3
        t, horiz, vertic = generateInstance(n, p, cellSize, i/nbInstance)
        writeOutputFile("../data/"*pref * string(i) * suff, t, horiz, vertic, cellSize)
        print("\r"*string(div(100*i, nbInstance))*" % done")
    end
    print("\n")
    #println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
end

#Genere des instances pour des tests specifiques
function testSize(nbInstance::Int64, density::Float64, pref::String="sizeInstance_", suff::String=".txt")
    print("\n0 % done")
    for i in 1:nbInstance
        n = 5
        p = 5
        cellSize = 5
        t, horiz, vertic = generateInstance(n, p, cellSize, density)
        writeOutputFile("../data/"*pref * string(i) * suff, t, horiz, vertic, cellSize)
        print("\r"*string(div(100*i, nbInstance))*" % done")
    end
    print("\n")
end