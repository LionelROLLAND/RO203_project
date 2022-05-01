# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

function remComment(line)
    indComm = findfirst(isequal('#'), line)
    if indComm === nothing
        return line
    else
        return line[1:indComm-1]
    end
end

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    line = remComment(data[1])
    ls = split(line, " ")
    n = parse(Int64, ls[1])
    p = parse(Int64, ls[2])
    regionSize = parse(Int64, ls[3])
    t = Array{Int64}(undef, n, p)
    horiz = Array{Int64}(undef, n-1, p)
    vertic = Array{Int64}(undef, n, p-1)
    fill!(t, -1)
    fill!(horiz, 0)
    fill!(vertic, 0)

    # For each line of the input file
    k = 2
    line = remComment(data[k])
    while line != ""
        #println(k)
        #println(line)
        ls = split(line, " ")
        x = parse(Int64, ls[1])
        y = parse(Int64, ls[2])
        v = parse(Int64, ls[3])
        t[y,x] = v
        k += 1
        line = remComment(data[k])
    end
    k += 1
    line = remComment(data[k])
    while line != ""
        ls = split(line, " ")
        x = parse(Int64, ls[1])
        y = parse(Int64, ls[2])
        horiz[y, x] = 1
        k += 1
        line = remComment(data[k])
    end
    k += 1
    for line in data[k:end]
        line = remComment(line)
        if line != ""
            ls = split(line, " ")
            x = parse(Int64, ls[1])
            y = parse(Int64, ls[2])
            vertic[y, x] = 1
        end
    end
    
    #println("In file io.jl, in method readInputFile(), TODO: read a line of the input file")
    return t, horiz, vertic, regionSize

end

function writeOutputFile(OutputFile::String, t::Array{Int64, 2}, horiz::Array{Int64, 2},
    vertic::Array{Int64, 2}, cell_size::Int64=-1)
    file_des = open(OutputFile, "w")
    n = size(t,1)
    p = size(t,2)
    
    print(file_des, n)
    print(file_des, " ")
    print(file_des, p)
    print(file_des, " ")
    println(file_des, cell_size)
    
    for y in 1:n
        for x in 1:p
            if t[y,x] >= 0
                print(file_des, x)
                print(file_des, " ")
                print(file_des, y)
                print(file_des, " ")
                println(file_des, t[y,x])
            end
        end
    end
    print(file_des, "\n")
    for y in 1:n-1
        for x in 1:p
            if horiz[y,x] != 0
                print(file_des, x)
                print(file_des, " ")
                println(file_des, y)
            end
        end
    end
    
    print(file_des, "\n")
    for y in 1:n
        for x in 1:p-1
            if vertic[y,x] != 0
                print(file_des, x)
                print(file_des, " ")
                println(file_des, y)
            end
        end
    end
    close(file_des)
end

##version IOStream
function writeOutputFile(file_des::IOStream, t::Array{Int64, 2}, horiz::Array{Int64, 2},
    vertic::Array{Int64, 2}, cell_size::Int64=-1)
    
    n = size(t,1)
    p = size(t,2)
    
    print(file_des, n)
    print(file_des, " ")
    print(file_des, p)
    print(file_des, " ")
    println(file_des, cell_size)
    
    for y in 1:n
        for x in 1:p
            if t[y,x] >= 0
                print(file_des, x)
                print(file_des, " ")
                print(file_des, y)
                print(file_des, " ")
                println(file_des, t[y,x])
            end
        end
    end
    print(file_des, "\n")
    for y in 1:n-1
        for x in 1:p
            if horiz[y,x] != 0
                print(file_des, x)
                print(file_des, " ")
                println(file_des, y)
            end
        end
    end
    
    print(file_des, "\n")
    for y in 1:n
        for x in 1:p-1
            if vertic[y,x] != 0
                print(file_des, x)
                print(file_des, " ")
                println(file_des, y)
            end
        end
    end
end


function b_to_i(b::Bool)
    if b
        return 1
    else
        return 0
    end
end

function displayGrid(t::Array{Int64, 2}, horiz::Array{Int64, 2}, vertic::Array{Int64, 2}, w_limits::Bool=false)
    #GDHB
    if w_limits
        smartTab = [[[["┼", "?"], ["?", "┼"]], [["?", "┼"], ["┼", "┼"]]], [[["?", "┼"], ["┼", "┼"]], [["┼", "┼"], ["┼", "┼"]]]]
    else
        smartTab = [[[[" ", "╷"], ["╵", "│"]], [["╶", "╭"], ["╰", "├"]]], [[["╴", "╮"], ["╯", "┤"]], [["─", "┬"], ["┴", "┼"]]]]
    end
    n = size(t, 1)
    p = size(t, 2)

    cT = Array{String}(undef, 2*n+1, 2*p+1)
    fill!(cT, " ")
    cT[1,1] = "╭"
    cT[1,2*p+1] = "╮"
    cT[2*n+1,1] = "╰"
    cT[2*n+1,2*p+1] = "╯"
    for j in 1:p
        cT[1, 2*j] = "─"
        cT[2*n+1, 2*j] = "─"
    end
    for i in 1:n
        cT[2*i, 1] = "│"
        cT[2*i, 2*p+1] = "│"
    end

    for y in 1:n
        for x in 1:p
            if t[y,x] == -1
                cT[2*y, 2*x] = " "
            else
                cT[2*y, 2*x] = string(t[y,x])
            end
        end
    end

    for y in 1:n-1
        for x in 1:p
            if horiz[y, x] != 0
                cT[2*y+1,2*x] = "─"
            else
                cT[2*y+1,2*x] = " "
            end
        end
    end

    for y in 1:n
        for x in 1:p-1
            if vertic[y, x] != 0
                cT[2*y,2*x+1] = "│"
            else
                cT[2*y,2*x+1] = " "
            end
        end
    end

    for y in 1:n-1
        for x in 1:p-1
            g = 1 + b_to_i(cT[2*y+1, 2*x] == "─")
            d = 1 + b_to_i(cT[2*y+1, 2*x+2] == "─")
            h = 1 + b_to_i(cT[2*y, 2*x+1] == "│")
            b = 1 + b_to_i(cT[2*y+2, 2*x+1] == "│")
            cT[2*y+1, 2*x+1] = smartTab[g][d][h][b]
        end
    end

    if w_limits
        for y in 1:n-1
            cT[2*y+1, 1] = "├"
            cT[2*y+1, 2*p+1] = "┤"
        end

        for x in 1:p-1
            cT[1, 2*x+1] = "┬"
            cT[2*n+1, 2*x+1] = "┴"
        end
    else
        for y in 1:n-1
            d = 1 + b_to_i(cT[2*y+1, 2] == "─")
            cT[2*y+1, 1] = smartTab[1][d][2][2]
            g = 1 + b_to_i(cT[2*y+1, 2*p] == "─")
            cT[2*y+1, 2*p+1] = smartTab[g][1][2][2]
        end

        for x in 1:p-1
            b = 1 + b_to_i(cT[2, 2*x+1] == "│")
            cT[1, 2*x+1] = smartTab[2][2][1][b]
            h = 1 + b_to_i(cT[2*n, 2*x+1] == "│")
            cT[2*n+1, 2*x+1] = smartTab[2][2][h][1]
        end
    end

    print("\n")
    for i in 1:2*n+1
        for j in 1:2*p+1
            print(cT[i,j])
        end
        print("\n")
    end
end


"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->!occursin("res_", x), readdir(path))

                fileCount += 1
                include(path * "/" * resultFile)

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 

    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)

    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf

            # Number of elements which have the value previousX
            identicalValues = 1

             # While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
            
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)

        # Otherwise 
        else
            # Add the new curve to the created plot
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->!occursin("res_", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    solvedInstances = unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=5), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
