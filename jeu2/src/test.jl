include("io.jl")
include("generation.jl")

function test(n::Int64, p::Int64, size::Int64)
    t = Array{Int64}(undef, n, p)
    fill!(t, -1)
    n_regions = div(n*p, size)
    buildRegion(t, n, p, size, n_regions)
    horiz, vertic = generatePali(t)
    displayGrid(t, horiz, vertic)
end


#test(4, 6, 8)
generateInstance(4, 6, 8, 0.2)