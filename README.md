

This workflow trains a convolutional neural network using population genetics data simulated with SLiM. 

This code corresponds to the following publication: XXX

# Contents

[Inputs](#inputs)

[Run workflow](#run-workflow)

[Outputs](#outputs)

[To do](#to-do)

# Inputs

My workflow requires 3 files, a yaml file of workflow parameters (`config/config.yaml`), a tsv file of SLiM parameters (`config/parameters.tsv`), and a csv file describing a demographic pattern for the SLiM simulations (`config/demography.csv`). I describe each of these inputs below.

## `config/config.yaml`

The workflow parameters can be found in `config/config.yaml`. Each parameter is described below.

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

## 2. Specify demographic pattern 

Another required input is `config/demography.csv`. This is a headerless csv file with two columns

| Population size | Time point |
|-----------------|------------|
| Column of population sizes | Column of time points, starting with 1 as the generation after burn-in, at which the population size changes |

For example, a file like the following:

```
1000,10
2000,15
3000,20
```

means that 10 generations after burn-in the population size will change to 1000, at 15 generations post-burn-in the population size will change to 2000, and at 20 generations post-burn-in the population size will change to 3000.

## `config/parameters.tsv`

There's a simple R script in `src/` to generate this input for you:

`Rscript src/s00_createParamTable.R`

Here is a description of each parameter in the table:

| Parameter | Description | 
|-----------|-------------|
| ID | Number from 1:K, used as a unique ID for each simulation |
| Q | scaling factor |
| N | ancestral population size, used for burn-in |
| sweepS | selection coefficient for sweep mutation |
| h | dominance coefficient of sweep mutation |
| sigma | selfing rate |
| mu | mutation rate |
| R | recombination rate |
| tau | time when population is sampled (cycles post-burn-in when simulation ends) | 
| kappa | time when sweep is introduced (simulation will restart here if sweep fails) |
| f0 | threshold frequency to convert sweep from neutral -> beneficial (for soft sweeps) |
| f1 | threshold frequency to convert sweep from beneficial -> neutral (for partial sweeps) |
| n | number of sweep mutations to introduce (recurrent mutation) |
| lambda | average waiting time between sweep mutations (poisson distribution) |
| ncf | proportion of cross over events that are gene conversions |
| cl | length of gene conversion crossover events |
| fsimple | fraction of crossover events that are simple |
| B | proportion of non-sweep mutations that are beneficial |
| U | proportion of non-sweep mutations that are deleterious |
| M | proportion of non-sweep mutations that are neutral |
| hU | dominance coefficient for deleterious non-sweep mutations |
| hB | dominance coefficient for beneficial non-sweep mutations |
| bBar | average selection coefficient for beneficial non-sweep mutations | 
| uBar | average selection coefficient for deleterious non-sweep mutations |
| alpha | shape parameter for distribution of fitness effects for deleterious non-sweep mutations |

Supported sweep types:

| Sweep type | f0 | f1 | n |
|------------|----|----|---|
| hard | 0 | 1 | 1 |
| soft | 0< | 1 | 1 |
| partial | 0 | <1 | 1 |
| recurrent | 0 | 1 | >1 |
| soft + partial | 0< | <1 | 1 |
| soft + recurrent | 0< | 1 | >1 |
| partial + recurrent | 0 | <1 | >1 |
| soft + partial + recurrent | 0< | <1 | >1 |


# Run workflow

`sbatch s01_snakemake.bash`

# Outputs

* One image per SLiM simulation
* One model `best_cnn.h5` trained on a stratified sample of SLiM simulations
* Comparisons between predicted and true values for testing data
* Comparisons between predicted and true values for training data
* Comparisons between predicted and true values for validation data

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

- [x] modify simulation to continue until the present day, restart if sweep is not fixed by present day (add parameter G for Generations post-burn in to run simulation)

- [ ] add error checking to slim script (tau should be less than kappa for example)

- [ ] add creation of parameter table to workflow

- [ ] calculate fixation time error from scaled and non-scaled simulations, 100 replicates

- [ ] add script to tune hyperparameters

- [ ] modify fitting script to use best hyperparameters found during tuning. Hyperparameters: dropout rate (0 - 0.8), number of convolution + pooling layers, number of neurons for dense layers

- [ ] add clonal reproduction?

- [ ] include polyploidy?

- [ ] include population structure? (track time for mutation to fix when it needs to migrate to another population first)

- [ ] use gpu instead of cpu for training model

- [ ] re-write neural network as a function with hyperparameters

- [ ] add a table of hyperparameters combinations to test for neural network


