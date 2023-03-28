This workflow trains a convolutional neural network using population genetics data simulated with SLiM. 

My specific purpose is to train a model that can predict demographic parameters and parameters for the distribution of fitness effects at a locus.

# How to replicate my results

## 0. Set-up workflow

```
# clone repo
git clone https://github.com/milesroberts-123/selection-demography-cnn.git

# go to source code folder
cd src
```

## 1. Create table of simulation parameters

`Rscript s00_createParamTable.R`

## 2. Run simulations and train neural network on outputs

`sbatch s01_snakemake.bash`

# How to use a different SLiM model

Just replace the script in `workflow/scripts/simulation.slim` with your own SLiM script. Your new script must be named `simulation.slim`.

# To-do

- [ ] add rule for fitting neural network

- [ ] re-write neural network as a function with hyperparameters

- [ ] add a table of hyperparameters combinations to test for neural network

