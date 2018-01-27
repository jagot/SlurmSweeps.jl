function instance(;port=12385, log_dir="logs")
    procid = parse(Int,ENV["SLURM_PROCID"])
    nodes = ENV["SLURM_NODELIST"]
    nodes = split(strip(readstring(`scontrol show hostname $(nodes)`)), "\n")
    master_node = nodes[1]

    procid == 0 && mkpath(log_dir)

    @sync begin
        procid == 0 && server(port, log_dir)
        sleep(2)
        client(master_node, port, log_dir)
    end
end
