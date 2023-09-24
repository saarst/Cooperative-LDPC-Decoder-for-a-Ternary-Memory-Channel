#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il
#PBS -l select=4:ncpus=12
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

# Run MATLAB command and redirect output to the output file
"/usr/local/matlab/bin/matlab" -nodisplay -r "BSC_simulation_main(${n}, ${log_p}, ${Rate}, ${numIter}, './Results/${experimentName}' )" 
