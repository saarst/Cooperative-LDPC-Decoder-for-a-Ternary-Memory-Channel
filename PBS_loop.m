for log_p = -8:-1
    name = sprintf("TriLDPC_n_256_p_1e%d_R_05_iter_1000",log_p);
    system(sprintf("qsub -N %s -v log_p=%d ./PBS_main.sh", name, log_p));
end