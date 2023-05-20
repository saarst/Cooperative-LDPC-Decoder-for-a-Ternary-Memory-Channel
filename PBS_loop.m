for logscale = -8:-1
    p = 10^(logscale);
    system(sprintf("qsub ./PBS_main.sh %f",p));
end