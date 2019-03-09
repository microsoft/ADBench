using Plots

OUT_DIR = "$(@__DIR__)/../../tmp/Debug/gmm/"

function get_n_params(d, k)
    n_alphas = k
    n_means = d * k
    n_icf = k * div(d * (d+1), 2)
    n_alphas + n_means + n_icf
end

function unzip(tuples)
    map(1:length(first(tuples))) do i
        map(tuple -> tuple[i], tuples)
    end
end

function plot_benchmarks()
    plot_data = Dict()
    DIR_1K = "$(OUT_DIR)/1k/Julia/"
    for filename in readdir(DIR_1K)
        @show filename
        m = match(r"gmm_d(\d*)_K(\d*)_times_(.*)[.]txt", filename)
        if m == nothing continue end
        d = parse(Int, m.captures[1])
        k = parse(Int, m.captures[2])
        program_name = m.captures[3]
        n_params = get_n_params(d, k)
        execution_time_string = first(eachline(open("$(DIR_1K)$(filename)")))
        execution_time = parse(Float64, split(execution_time_string)[2])
        get!(plot_data, program_name, Dict())[n_params] = execution_time
    end
    for (name, data) in plot_data
        data_array = unzip(sort(collect(data)))
        plot!(label=name, data_array..., xaxis = ("# parameters", :log10), yaxis = ("Runtime [seconds]", :log10), legend = :bottomright, title="1K data points")
    end
    savefig("plot.png")
end
plot_benchmarks()

