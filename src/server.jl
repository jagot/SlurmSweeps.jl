using Logging

function server(port, log_dir; task_file="tasks", finished_tasks_file="finished_tasks")
    # Load tasks
    tasks = open(tasks_file) do file
        map(readlines(file)) do line
            strip(line)
        end
    end

    # Load finished tasks and filter out those from the todo list
    finished_tasks = isfile(finished_tasks_file) ? readdlm(finished_tasks_file) : []
    todo = filter(1:length(tasks)) do i
        !(i in finished_tasks)
    end

    # Order is randomized to balance load in case of unequal task
    # execution time
    todo = todo[randperm(length(todo))]

    jobid = ENV["SLURM_JOB_ID"]

    server_logger = Logger("server")
    Logging.configure(server_logger,
                      level=DEBUG,filename="$(log_dir)/server-$(jobid).log")

    debug(server_logger, "Starting server at $(gethostname()), $(getipaddr())")
    debug(server_logger, "$(length(tasks)) tasks total, $(length(todo)) unfinished")
    
    @async begin
        server = listen(IPv4(0), port)
        clients_running = 0
        todo_id = 0
        while true
            try
                sock = accept(server)
                debug(server_logger, "got connection")
                cl_query = strip(readline(sock))
                debug(server_logger, "got query: $(cl_query)")
                if cl_query == "-1"
                    clients_running += 1
                else
                    run_id = parse(Int, cl_query)
                    debug(server_logger,
                          "client claims $(run_id) is finished")
                    push!(finished_tasks, run_id)
                    writedlm(finished_tasks_file, finished_tasks)
                    sleep(0.1)
                end
                todo_id += 1
                if todo_id > length(todo)
                    write(sock, "-1\n")
                    clients_running -= 1
                    clients_running <= 0 && break
                else
                    run_id = todo[todo_id]
                    write(sock, "$(run_id)\n")
                    cmd = tasks[run_id]
                    debug(server_logger, "telling client to run $(cmd)")
                    write(sock, cmd)
                end
                close(sock)
            catch e
                error(server_logger, "$(e)")
                break
            end
        end
        close(server)
        debug(server_logger, "Server finished")
    end
end
