for log_p = -4.5
    name = sprintf("TriLDPC_logp_%g_n_256_R_05",log_p);
    system(sprintf("qsub -N %s -j oe -o ./logs/%s.log -v log_p=%g ./PBS_main.sh", name, name, log_p));
end