#!/bin/sh
#PBS -q zeus_all_q
#PBS -m abe
#PBS -M saar.stern@campus.technion.ac.il
#PBS -l select=2:ncpus=12
#PBS -l select=mem=20GB
#PBS -l walltime=24:00:00
#PBS -o ./logs/${PBS_JOBNAME}.o${PBS_JOBID}
#PBS -e ./logs/${PBS_JOBNAME}.e${PBS_JOBID}

logs_dir="./logs"
if [ ! -d "$logs_dir" ]; then
  mkdir "$logs_dir"
fi

PBS_O_WORKDIR=$HOME/project_1/TriLDPC
cd $PBS_O_WORKDIR

"/usr/local/matlab/bin/matlab" -nodisplay -r "ternary_batch_simulation_main(256, ${log_p}, 0.5, 50, 10)"
    