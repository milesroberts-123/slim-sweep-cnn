

This workflow trains a convolutional neural network using population genetics data simulated with SLiM. 

This code corresponds to the following publication: XXX

# Contents

[How to replicate my results](#how-to-replicate-my-results)

[To do](#to-do)

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

- [x] add recurrent mutation

- [x] refine burn-in, calculate expected equilibrium diversity and stop once population gets within 1 % of the equilibrium

- [x] add new types of demography

- [x] draw parameters from log uniform distribution

- [x] tweak growth rate, add shrinking populations

- [x] subset data to have a more uniform distribution of fixation times, then train your model

- [x] add linkage to deleterious mutations (model beneficial mutation in the center of a functional region under purifying selection)

- [x] add hill-robertson interference

- [x] track the number of sweeps lost (i.e. number of simulation restarts) before you get a simulation that ends in a fixed sweep

- [x] add gene conversion

- [x] add simulation id to prediction vs actual values output

- [x] add monte carlo dropout

- [x] re-do burn-in to stop once simulations reach equilibrium levels of diversity (within 5 % say of expected value), instead of 10N?

- [x] output harmonic mean of population size

- [x] decrease burn-in based on selfing rate

- [x] add parameter to adjust when sweep is introduced relative to burn-in start

- [x] add parameter Q for scaling demographic factors

- [x] expand ranges of simulation parameters
 
- [x] include both neutral (s < 1/N) and selection (s > 1/N) scenarios

- [x] modify slim rule to append output of failure count and fixation times into single files

- [x] investigate recombination rate * selfing rate interaction

- [x] add rule to extract outputs of simulations from log files, so that I don't have to make lots of intermediate files?

- [x] add R script to do stratified sampling of simulations

- [ ] calculate fixation time error from scaled and non-scaled simulations, 100 replicates

- [ ] modify simulation to continue until the present day, restart if sweep is not fixed by present day (add parameter G for Generations post-burn in to run simulation)

- [ ] add script to tune hyperparameters

- [ ] modify fitting script to use best hyperparameters found during tuning. Hyperparameters: dropout rate (0 - 0.8), number of convolution + pooling layers, number of neurons for dense layers

- [ ] add clonal reproduction?

- [ ] include polyploidy?

- [ ] include population structure? (track time for mutation to fix when it needs to migrate to another population first)

- [ ] use gpu instead of cpu for training model

- [ ] re-write neural network as a function with hyperparameters

- [ ] add a table of hyperparameters combinations to test for neural network


