#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=7-0:00:00
#SBATCH --mem-per-cpu=128G
#SBATCH --partition=josephsnodes
#SBATCH --account=josephsnodes
#SBATCH --mail-type=ALL
#SBATCH --mail-user=robe1195@msu.edu

# output information about how this job is running using bash commands
echo "This job is running on $HOSTNAME on `date`"

# go to workflow directory
echo Changing directory...
cd ../workflow

# load packages for model training
echo Activating conda environment...
mamba activate mycnn2

# start model training script
$CONDA_PREFIX/bin/python --version
$CONDA_PREFIX/bin/python scripts/mycnn.py
