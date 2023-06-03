for log_p = -4.5
    name = sprintf("TriLDPC_logp_%g_n_256_R_05",log_p);
    system(sprintf("qsub -N %s -v log_p=%g ./PBS_main.sh", name, log_p));
end