Ds = [2, 10, 20, 32, 64]
Ks = [5, 10, 25, 50, 100, 200]
Ns = ["10k"]
programs = ["F", "Flux", "Zygote", "F_vectorized", "Flux_vectorized", "Zygote_vectorized"]

base_path = @__DIR__

for d in Ds, k in Ks, n in Ns, program in programs
    cmd = `julia $(base_path)/gmm_$(program).jl $(base_path)/../../data/gmm/$(n)/ $(base_path)/../../tmp/Debug/gmm/$(n)/Julia/ gmm_d$(d)_K$(k) 2 5 180`
    @show cmd
    process = run(cmd, wait=false)
    timedwait(() -> process_exited(process), 60*9.)
    if process_running(process)
        kill(process)
        println("killed process")
        @show cmd
    end
end
