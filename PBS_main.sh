#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il
#PBS -l select=20:ncpus=20
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main(256, ${log_p}, 0.5, 1000, 50)"
    