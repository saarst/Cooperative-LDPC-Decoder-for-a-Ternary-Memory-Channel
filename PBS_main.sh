#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il  
#PBS -l select=2:ncpus=16
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00
#PBS -o "/$HOME/project_1/TriLDPC/logs/${experimentName}/${PBS_JOBNAME}.o${PBS_JOBID}"
#PBS -e "/$HOME/project_1/TriLDPC/logs/${experimentName}/${PBS_JOBNAME}.e${PBS_JOBID}"

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

logs_dir="./logs/${experimentName}"
if [ ! -d "$logs_dir" ]; then
  mkdir -p "$logs_dir"
fi


# Run MATLAB command
"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main(${n}, ${log_p}, ${R}, ${numIter}, ${batchSize}, ${sequenceInd}, ${sequenceRes}, './Results/${experimentName}' )"