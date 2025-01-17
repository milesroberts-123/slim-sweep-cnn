#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=7-00:00:00
#SBATCH --mem-per-cpu=16G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=robe1195@msu.edu
#SBATCH --partition=josephsnodes
#SBATCH --account=josephsnodes

# output information about how this job is running using bash commands
echo "This job is running on $HOSTNAME on `date`"

# Load conda module, helps nodes find my conda path for some reason
module purge
module load Conda/3

# load snakemake
echo Loading snakemake...
conda activate snakemake

# change directory of cache to scratch, can't accumulate files in my home space
echo Changing cache directory...
export XDG_CACHE_HOME="/mnt/scratch/robe1195/cache"
echo $XDG_CACHE_HOME

# go to workflow directory with Snakefile
echo Changing directory...
cd ../workflow

# unlock snakemake if previous instance of snakemake failed
echo Unlocking snakemake...
snakemake --unlock --cores 1

# submit snakemake to HPCC
# subtract one job and one core from max to account for this submission command
# rerun-incomplete in case previous snakemake instances failed and left incomplete files
# Max cpu count for my SLURM account is 1040, subtract 1 to account for scheduler
# Max job submit count is 1000, subtract 1 to account for scheduler
echo Running snakemake...

# split snakemake workflow into batchs so that computing DAG is easier
for num in {1..50}
do
  snakemake --cluster "sbatch --time={resources.time} --cpus-per-task={threads} --mem-per-cpu={resources.mem_mb_per_cpu} --partition=josephsnodes --account=josephsnodes" --jobs 950 --cores 950 --use-conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 2 --keep-going --batch all=$num/50
done

