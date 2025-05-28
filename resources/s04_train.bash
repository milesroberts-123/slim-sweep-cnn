#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-node=1
#SBATCH --time=7-00:00:00
#SBATCH --mem-per-cpu=16G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=robe1195@msu.edu
#SBATCH --partition=josephsnodes
#SBATCH --account=josephsnodes
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
$CONDA_PREFIX/bin/python scripts/cnn_univariate.py
