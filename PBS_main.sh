#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il  
#PBS -l select=2:ncpus=12
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00

logs_dir="./logs"
output_file="${logs_dir}/${PBS_JOBNAME}.o${PBS_JOBID}"
error_file="${logs_dir}/${PBS_JOBNAME}.e${PBS_JOBID}"



PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR


if [ ! -d "$logs_dir" ]; then
  mkdir "$logs_dir"
fi

"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main(${n}, ${log_p}, ${R}, ${numIter}, ${batchSize}, ${sequenceInd}, ${sequenceRes}, './Results/${experimentName}' )" > "$output_file" 2> "$error_file"