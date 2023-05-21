#!/bin/bash

for ((log_p=-8; log_p>-1; log_p--))
do
    name="TriLDPC_n_256_p_1e${log_p}_R_05_iter_1000"
    qsub -N "$name" -v log_p="$log_p" ./PBS_main.sh
done