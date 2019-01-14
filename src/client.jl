function client(master, port, log_dir)
    jobid = ENV["SLURM_JOB_ID"]
    nodeid = parse(Int,ENV["SLURM_NODEID"])
    localid = parse(Int,ENV["SLURM_LOCALID"])

    open("$(log_dir)/client-$(jobid)-$(nodeid)-$(localid).log", "w+") do log_file
        client_logger = SimpleLogger(log_file, Logging.Debug)
        @debug "Client $(nodeid)#$(localid) starting"
        @debug "Master at $(master):$(port)"
        @debug "What is thy bidding, my master?"
        run_id = -1
        while true
            try
                cl = connect(master, port)
                write(cl, "$(run_id)\n")
                run_id = parse(Int, strip(readline(cl)))
                run_id == -1 && break
                cmd = replace(strip(readline(cl)), "[local-id]"=>"$(localid)")
                @debug "Supposed to do $(cmd), why not."
                for c in split(cmd, ";")
                    cc = split(c)
                    run(`$(cc)`)
                end
                @debug "I'm all done, gimme more."
            catch e
                @error "$(e)"
                break
            end
        end
    end
end
