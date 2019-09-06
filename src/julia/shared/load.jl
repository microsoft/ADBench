dir = @__DIR__
if !(dir ∈ LOAD_PATH)
    push!(LOAD_PATH, dir)
end