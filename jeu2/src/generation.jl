# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""

#count(u->(u==-1), t[1,1:p])

function connComp(t::Array{Int64, 2}, n::Int64, p::Int64, x::Int64, y::Int64)
    t[y,x] = -2
    
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
            if t[ny,nx] == -1
                connComp(t, n, p, nx, ny)
            end
        end
    end
end


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
        temp = dy
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
        connComp(t_copy, n, p, nx, ny)
        
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


function recRegion(t::Array{Int64, 2}, n::Int64, p::Int64, full_size::Int64, size::Int64,
    i_region::Int64, x_adj::Array{Int64, 1}, y_adj::Array{Int64, 1}, n_adj::Int64)
    if size == 0
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

            for i in 1:4
                temp = dy
                dy = dx
                dx = -temp
        
                nx = x+dx
                ny = y+dy
                if nx >= 1 && nx <= p && ny >= 1 && ny <= n
                    if t[ny,nx] == -1
                        push!(new_x_adj, nx)
                        push!(new_y_adj, ny)
                        new_n_adj += 1
                    end
                end
            end
            finished = recRegion(t, n, p, full_size, size-1, i_region, new_x_adj, new_y_adj, new_n_adj)
            if finished
                return true
            end
        end
        I += 1
        next_cell = 1 + rem(next_cell, n_adj)
    end
    return false
end


function buildRegion(t::Array{Int64,2}, n::Int64, p::Int64, size::Int64, i_region::Int64)
    if i_region == 0
        return true
    end

    dx = 1
    dy = 0
    temp = -1

    empty_cells = i_region*size
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

            finished = recRegion(t, n, p, size, size-1, i_region, x_adj, y_adj, n_adj)

            if finished
                return true
            end
            t[y,x] = -1
        end
        first_cell = 1
        I += 1
    end
    return false
end


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

function generateInstance(n::Int64, p::Int64, size::Float64)

    t = Array{Int64}(undef, n, p)
    fill!(t, -1)
    n_regions = div(n*p, size)
    buildRegion(t, n, p, size, n_regions)
    res = countPali(t)
    horiz = Array{Int64}(undef, n-1, p)
    vertic = Array{Int64}(undef, n, p-1)
    fill!(horiz, 0)
    fill!(vertic, 0)

    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    return res, horiz, vertic
    
end

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



####### INUTILE A PRIORI :

function deepSearch(t::Array{Int64, 2}, n::Int64, p::Int64, x_dep::Int64, y_dep::Int64, x_arr::Int64, y_arr::Int64)
    if x_dep == x_arr && y_dep == y_arr
        return true
    end
    dx = 1
    dy = 0
    temp = -1
    for i in 1:4
        temp = dy
        dy = dx
        dx = -temp

        nx = x_dep+dx
        ny = y_dep+dy
        if nx >= 1 && nx <= p && ny >= 1 && ny <= n
            if t[ny,nx] == -1
                t[ny,nx] = -2
                child = deepSearch(t, n, p, nx, ny, x_arr, y_arr)
                if child
                    return true
                end
            end
        end
    end
    return false
end




"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



