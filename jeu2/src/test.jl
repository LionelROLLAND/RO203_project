include("io.jl")
include("generation.jl")

function test_gene(n::Int64, p::Int64, size::Int64)
    t = Array{Int64}(undef, n, p)
    fill!(t, -1)
    n_regions = div(n*p, size)
    buildRegion(t, n, p, size, n_regions)
    horiz, vertic = generatePali(t)
    displayGrid(t, horiz, vertic)
    return t, horiz, vertic
end

function test_rw(n::Int64, p::Int64, size::Int64, fname::String)
    t, horiz, vertic = test_gene(n, p, size)
    writeOutputFile(fname, t, horiz, vertic)

    print("\n")

    r_t, r_horiz, r_vertic = readInputFile(fname)
    displayGrid(r_t, r_horiz, r_vertic)
end

function testInstance(n::Int64, p::Int64, size::Int64, density::Float64)
    t, horiz, vertic = generateInstance(n, p, size, density)
    displayGrid(t, horiz, vertic, true)
end

#=
for i in 1:60
    test_gene(4, 6, 6)
end
testInstance(4, 6, 8, 0.2)
test_rw(4, 6, 6, "Jean-Claude.txt")
=#
generateDataSet(5, 10, "test_test__", ".txt")