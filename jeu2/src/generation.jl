# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""

function isValidPlace(t::Array{Int64,2}, n::Int64, p::Int64, x::Int64, y::Int64)
	temp = deepcopy(t)
	
	dx = 1
	dy = 0
	temp = -1
	
	found = false
	
	i = 0
	nx = -1
	ny = -1
	while i < 4 && !found
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
		connComp(temp, n, p, nx, ny)
	
		for i in 1:4
			temp = dy
			dy = dx
			dx = -temp
		
			nx = x+dx
			ny = y+dy
			if nx >= 1 && nx <= p && ny >= 1 && ny <= n
				if t[ny,nx] == -1 && temp[ny,nx] != -2
					return false
				end
			end
		end
	end
	
	return true
end

function recRegion()
end

function buildRegion(t::Array{Int64,2}, n::Int64, p::Int64, size::Int64, i_region::Int64)
	first_cell = 1 + rem(abs(rand(Int64)), n*p - (i-1)*size) #le diviseur est le nb de cellule vides
	i_cell = 0
	x = 1
	y = 1
	while first_cell #On parcourt jusqu'a trouver la first_cell-ieme cellule vide
		x = 1 + rem(i_cell, p)
		y = 1 + div(i_cell, p)
		if t[y, x] == -1
			first_cell -= 1
		end
		i_cell += 1
	end
	t[y,x] = i #A CONTINUER
end


function generateInstance(n::Int64, p::Int64, size::Float64)

	t = Array{Int64}(undef, n, p)
	fill!(t, -1)
	n_regions = div(n*p, size)
	
	dx = 1
	dy = 0
	temp = -1
	
	for i in 1:n_regions
		x_adj = []
		y_adj = []
		
		
		#Choper une premiere cellule vide au hasard :
		first_cell = 1 + rem(abs(rand(Int64)), n*p - (i-1)*size) #le diviseur est le nb de cellule vides
		i_cell = 0
		x = 1
		y = 1
		while first_cell #On parcourt jusqu'a trouver la first_cell-ieme cellule vide
			x = 1 + rem(i_cell, p)
			y = 1 + div(i_cell, p)
			if t[y, x] == -1
				first_cell -= 1
			end
			i_cell += 1
		end
		t[y,x] = i
		#count(u->(u==-1), t[1,1:p])
		
		
		
		#Agreger toutes celles d'apres a la premiere
		for j in 2:size
		
			for i in 1:4

				temp = dy #On fait tourner dx, dy
				dy = dx
				dx = -temp

				nx = x+dx #On rajoute les voisins aux cellules adjacentes a la region
				ny = y+dy
				if nx >= 1 && nx <= p && ny >= 1 && ny <= n
					if t[ny,nx] == -1
						push!(x_adj, nx)
						push!(y_adj, ny)
					end
				end
			end ### STOP :: probleme de faisabilite
		
		
		
		
			
		end
	end
	println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    
end

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


function connComp(t::Array{Int64, 2}, n::Int64, p::Int64, x::Int64, y::Int64)
	t[y,x] = -2
	
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
				connComp(t, n, p, nx, ny)
			end
		end
	end
end



"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



