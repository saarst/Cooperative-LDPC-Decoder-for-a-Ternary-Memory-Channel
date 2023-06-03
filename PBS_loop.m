for log_p = -5:0.25:-2
    name = sprintf("TriLDPC_logp%g_n256_R05",log_p);
    system(sprintf("qsub -N %s -v log_p=%g ./PBS_main.sh", name, log_p));
end