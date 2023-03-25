Goal: predict demography and distribution of fitness effects at a locus from alignment images using a convolutional neural network

# How to replicate my results

`cd src`

## 1. Create table of simulation parameters

`Rscript s00_createParamTable.R`

## 2. Run simulations

`sbatch s01_snakemake.bash`

## 3. Train neural network
