#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il
#PBS -l select=1:ncpus=12
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

n=256  # Replace with the desired value of n
run_name="TriLDPC_n_${n}_p_1e${log_p}_R_05"

"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main(256, ${log_p}, 0.5, 50, 10)" > "${run_name}_output.log" 2>&1
    