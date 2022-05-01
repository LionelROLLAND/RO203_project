include("io.jl")
include("generation.jl")
include("resolution.jl")

#Teste la generation d'instances
function test_gene(n::Int64, p::Int64, regionSize::Int64)
    t = Array{Int64}(undef, n, p)
    fill!(t, -1)
    n_regions = div(n*p, regionSize)
    buildRegion(t, n, p, regionSize, n_regions)
    horiz, vertic = generatePali(t)
    displayGrid(t, horiz, vertic)
    return t, horiz, vertic
end

#teste l'ecriture/lecture d'instances
function test_rw(n::Int64, p::Int64, regionSize::Int64, fname::String)
    t, horiz, vertic = test_gene(n, p, regionSize)
    writeOutputFile(fname, t, horiz, vertic)

    print("\n")

    r_t, r_horiz, r_vertic = readInputFile(fname)
    displayGrid(r_t, r_horiz, r_vertic)
end

#teste la generation d'instance
function testInstance(n::Int64, p::Int64, regionSize::Int64, density::Float64)
    t, horiz, vertic = generateInstance(n, p, regionSize, density)
    displayGrid(t, horiz, vertic, true)
end

#teste la resolution heuristique
function testHeuristic(fname::String)
    start = time()
    println("Tip --")
    t, horiz, vertic, regionSize = readInputFile(fname)
    displayGrid(t, horiz, vertic, true)
    isOpti, regions, horiz, vertic = heuristicSolve(t, regionSize)
    println("\n-- Top")
    stop = time()
    println(string(stop-start)*" secondes ecoulees")
    displayGrid(regions, horiz, vertic)
end

#=
for i in 1:60
    test_gene(4, 6, 6)
end

testInstance(4, 6, 8, 0.2)
test_rw(4, 6, 6, "Jean-Claude.txt")
generateDataSet(10, 10, "big_instance_", ".txt")
testHeuristic("../data/big_instance_1.txt")

resultsArray("../resultsArray.tex")
performanceDiagram("../results.png")
testSize(5, 0.5, "sizeInstance_", ".txt")
=#
generateDataSet(5, 6, "instance_", ".txt")
solveDataSet()


#testHeuristic("../data_test/instance_expl.txt")