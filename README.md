This workflow trains a convolutional neural network using population genetics data simulated with SLiM. 

This code corresponds to the following publication: XXX

# Contents

(How to replicate my results)[#how-to-replicate-my-results]

(How to use a different SLiM model)[#how-to-use-a-different-slim-model]

(To do)[#to-do]

# How to replicate my results

## 0. Set-up workflow

```
# clone repo
git clone https://github.com/milesroberts-123/selection-demography-cnn.git

# go to source code folder
cd src
```

## 1. Choose workflow parameters

All parameters can be found in `config/config.yaml`. Each parameter is described below.

| Parameter | Description | Default |
|-----------|-------------|---------|
| K | number of simulations to run | 5000 |
| train | Proportion of simulations to use for training | 0.8 |
| test | Proportion of simulations to use for testing | 0.1 |
| val | Proportion of simulations to use for validation | 0.1 |
| gff | Path to gff file, which will be used to construct gene models | "../config/genome/Osativa_323_v7.0.gene.gff3" |
| nidv | Number of individual genomes to sample from each simulation | 128 |
| nloc | Number of loci to sample from each simulation | 128 |
| distMethod | Method for measuring genetic distance between loci | "manhattan" |
| clustMethod | Method used to cluster genomes based on genetic distance | "complete " |

## 2. Create table of simulation parameters

`Rscript s00_createParamTable.R`

## 3. Run simulations and train neural network on outputs

`sbatch s01_snakemake.bash`

# How to use a different SLiM model

Just replace the script in `workflow/scripts/simulation.slim` with your own SLiM script. Your new script must be named `simulation.slim`.

# To do

- [x] add rule for fitting neural network

- [x] perform hierarchical clustering of genotypes before image generation

- [x] add a burn-in period

- [x] remove multiallelic sites

- [x] Add config file to define workflow parameters

- [x] Add rule for generating table of parameters?

- [x] Calculate heterozygosity periodically to see if population reaches an equilibrium

- [x] Add simulation length as parameter

- [x] Add mutation rate as parameter

- [x] Add recombination rate as parameter

- [x] include polymorphism position information as another input to the network, output position table at the same time as image creation

- [x] differentiate time of fixation from time of observation

- [x] add soft sweeps

- [x] add partial sweeps

- [ ] add recurrent mutation

- [ ] refine burn-in, calculate expected equilibrium diversity and stop once population gets within 1 % of the equilibrium

- [ ] add hill-robertson interference

- [ ] add new types of demography

- [ ] re-write neural network as a function with hyperparameters

- [ ] add a table of hyperparameters combinations to test for neural network


