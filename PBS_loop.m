for log_p = -6:-2
    iter = 10^(-log_p + 2);
    name = sprintf("TriLDPC_n_256_p_1e%d_R_05_iter_%g",log_p, iter);
    system(sprintf("qsub -N %s -v log_p=%d ./PBS_main.sh", name, log_p));
end