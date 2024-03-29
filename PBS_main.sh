#!/bin/sh
#PBS -q zeus_combined_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il
#PBS -l select=4:ncpus=12
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

# Run MATLAB command and redirect output to the output file
"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main('${decoder}',${loadWords}, ${id}, ${n}, ${log_p}, ${log_q}, ${RateInd}, ${RateRes}, ${numIter}, ${sequenceInd}, ${sequenceRes}, './Results/${experimentName}' )" 
