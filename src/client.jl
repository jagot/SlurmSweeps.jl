using Logging

function client(master, port, log_dir)
    jobid = ENV["SLURM_JOB_ID"]
    nodeid = parse(Int,ENV["SLURM_NODEID"])
    localid = parse(Int,ENV["SLURM_LOCALID"])

    client_logger = Logger("client")
    Logging.configure(client_logger,
                      level=DEBUG,
                      filename="$(log_dir)/client-$(jobid)-$(nodeid)-$(localid).log")
    debug(client_logger, "Client $(nodeid)#$(localid) starting")
    debug(client_logger, "Master at $(master):$(port)")
    debug(client_logger, "What is thy bidding, my master?")
    run_id = -1
    while true
        try
            cl = connect(master, port)
            write(cl, "$(run_id)\n")
            run_id = parse(Int, strip(readline(cl)))
            run_id == -1 && break
            cmd = replace(strip(readline(cl)), "[local-id]", "$(localid)")
            debug(client_logger, "Supposed to do $(cmd), why not.")
            for c in split(cmd, ";")
                cc = split(c)
                run(`$(cc)`)
            end
            debug(client_logger, "I'm all done, gimme more.")
        catch e
            error(client_logger, "$(e)")
            break
        end
    end
end
