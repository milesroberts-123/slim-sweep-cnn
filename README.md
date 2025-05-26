This workflow trains a convolutional neural network using simulated selective sweeps with SLiM. The workflow was developed and tested using snakemake v 7.25.0 

# Contents

[Setup](#setup)

[Inputs](#inputs)

[Run workflow](#run-workflow-with-conda-on-a-slurm-cluster)

[Outputs](#outputs)

[To do](#to-do)

# Setup

1. Make sure you have [mamba](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) installed. 

2. Grab repository from github

```
git clone https://github.com/milesroberts-123/selection-demography-cnn.git
```

3. Install snakemake and the cnn software using the provided yaml files

```
mamba env create --name snakemake --file snakemake-env.yaml
mamba env create --name cnn --file cnn-env.yaml
```

Now you can activate the enviornments with either snakemake or the CNN software with `mamba activate snakemake` or `mamba activate cnn`, respectively.

# Inputs

The workflow requires 2 files, a yaml file of workflow parameters (`config/config.yaml`) and a tsv file of SLiM parameters (`config/parameters.tsv`). Optionally, if you want SLiM to simulate a custom demographic patter, then you must also provide another csv file (`config/demography.csv`). Each input is described below.

## 1. Configure workflow with `config/config.yaml`

The workflow parameters can be found in `config/config.yaml`. Each parameter is described below.

| Parameter | Description | Default |
|-----------|-------------|---------|
| K | number of simulations to run | 5000 |
| nidv | Number of individual genomes to sample from each simulation | 128 |
| nloc | Number of loci to sample from each simulation | 128 |
| distMethod | Method for measuring genetic distance between loci | "manhattan" |
| clustMethod | Method used to cluster genomes based on genetic distance | "complete " |

## 2. Generate table of simulation parameters `config/parameters.tsv`

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
| r | logistic growth rate |
| K | logistic carrying capacity |
| demog | whether to use custom demography in config/demography.csv or a logistic model |

Depending on your parameter choices, you can simulate lots of different sweep types. Here is a table summarizing what parameter values produce what sweep types:

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

## 3. (Optional) Specify demographic pattern 

For each simulation in `config/parameters.tsv` you need to define a switch called `demog`. If `demog != 1`, then slim will look for r and K values in to use a logistic growth/death model for the population. If `demog == 1`, then slim will look for `config/demography.csv`. This is a file specifying a cutom demographic pattern. It is a headerless csv file with two columns:

| Population size | Time point |
|-----------------|------------|
| Column of population sizes | Column of time points, starting with 1 as the generation after burn-in, at which the population size changes |

For example, a file like the following:

```
1000,10
2000,15
3000,20
```

means that 10 generations after burn-in the population size will change to 1000 (burn-in population size is defined by N), at 15 generations post-burn-in the population size will change to 2000, and at 20 generations post-burn-in the population size will change to 3000.

# Run workflow with conda on a slurm cluster

Example commands for running the snakemake workflow are in `src/s01_snakemake.bash`. Make sure to change `--partition`, `--account`, `--jobs`, and `--cores` to account for your cluster's computational limits. The command below includes retrying each job twice (i.e. a total of three attempts per job, `--retries 2`) and continuing even when jobs fail (`--keep-going`). This is necessary because you can expect that not all sweep simulations will complete successfully, depending what area of parameter space you're exploring.

## Run whole workflow at once on a slurm cluster

```
snakemake --cluster "sbatch --time={resources.time} --cpus-per-task={threads} --mem-per-cpu={resources.mem_mb_per_cpu} --partition=<YOUR PARTITION HERE> --account=<YOUR ACCOUNT HERE>" --jobs 950 --cores 950 --use-conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 2 --keep-going
```

## Run workflow in bathes on a slurm cluster

```
# The number of batches you want to do.
# Increase this value if you have fewer computational resources so that the workflow executes in smaller chunks
numbatch=50

for curbatch in {1..$numbatch}
do
  snakemake --cluster "sbatch --time={resources.time} --cpus-per-task={threads} --mem-per-cpu={resources.mem_mb_per_cpu} --partition=<YOUR PARTITION HERE> --account=<YOUR ACCOUNT HERE>" --jobs 950 --cores 950 --use-conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 2 --keep-going --batch all=$curbatch/$numbatch
done
```

# Outputs

* One image per SLiM simulation
* One model `best_cnn.h5` trained on a stratified sample of SLiM simulations
* Comparisons between predicted and true values for testing data
* Comparisons between predicted and true values for training data
* Comparisons between predicted and true values for validation data
