function sbatch(file; kwargs...)
    for (k,v) in kwargs
        k = replace(string(k), "_"=>"-")
        v = string(v)
        kw = if length(k) == 1
            "-$(k) $(v)"
        elseif length(v) == 0
            "--$(k)"
        else
            "--$(k)=$(v)"
        end
        write(file, "#SBATCH $(kw)\n")
    end
end

function setup_sweep(tasks::AbstractVector{String}, name::String;
                     port=12385, log_dir="logs",
                     extra_cmds = [],
                     kwargs...)
    open("tasks", "w") do file
        write(file, join(tasks, "\n"))
    end
    mkpath(log_dir)
    
    open("slurm.sh", "w") do file
        write(file, "#!/bin/sh\n")
        sbatch(file;
               J=name,
               o="$(log_dir)/$(name)_%j.out",
               e="$(log_dir)/$(name)_%j.out",
               kwargs...)

        write(file, "set -e\n")
        for cmd in extra_cmds
            write(file, "$(cmd)\n")
        end

        write(file, "srun -Q -N \${SLURM_NNODES} -n \${SLURM_NPROCS} julia -e 'using Pkg; Pkg.activate(\".\"); import SlurmSweeps; SlurmSweeps.instance(port=$(port), log_dir=\"$(log_dir)\")'")
    end
end

export setup_sweep
