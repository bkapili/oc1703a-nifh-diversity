#! /bin/bash
#
#SBATCH --job-name=ppit
#
#SBATCH --partition=serc
#SBATCH --time=36:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=96GB

bash reproduce.sh
