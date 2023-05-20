for logscale = -8:-1
    p = 10^(logscale);
    system(sprintf("qsub -v p=%f ./PBS_main.sh",p));
end