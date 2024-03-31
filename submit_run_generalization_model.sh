#!/bin/bash
#SBATCH -n 1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --array=1-486%1000
#SBATCH --partition=use-everything
#SBATCH --requeue

source run_generalization_simulation_openmind.sh $SLURM_ARRAY_TASK_ID
