## 1. Configure workflow with `config/config.yaml`

The parameters that are held constant across all simulations in a workflow are in  `config/config.yaml`. These are:

| Parameter | Description | Default |
|-----------|-------------|---------|
| K | number of simulations to run | 5000 |
| nidv | Number of individual genomes to sample from each simulation | 128 |
| nloc | Number of loci to sample from each simulation | 128 |
| distMethod | Method for measuring genetic distance between loci | "manhattan" |
| clustMethod | Method used to cluster genomes based on genetic distance | "complete " |

## 2. Generate table of simulation parameters `config/parameters.tsv`

The parameters that vary across simulations are within `config/parameters.tsv`. Each row of this file represents a different simulation and each simulation gets a unique number as an ID.

There's an example simple R script in `resources/s00_make_param_table.R` that generates a parameters table, but you don't need to use that script. However you choose to generate a parameters table, it needs to have the following columns:

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
| custom_demography | whether to use custom demography in config/demography.csv or a logistic model |

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

If your demography follows a logistic growth rate model, then you can simulate a wide range of demographies:

| Demography | Description | r | K |
|------------|-------------|---|---|
| constant | Population size does not change | 0 | N |
| growth | Population size increases until K | 0 < r < 2 | N < K | 
| decay | Population size decreases until K | 0 < r < 2 | N > K |
| cycle | Population size cycles between two values | 2 < r < sqrt(6) | anything |
| chaotic | Population size changes chaotically* | sqrt(6) < r < 3 | anything | 

Note that for the chaotic demography, because our population sizes are discrete a population that randomly changes back to a size it had during a previous simulation tick will just cycle. So a chaotic demography will probably just be an arbitrarily long cycle in many cases.

## 3. (Optional) Specify a custom demographic pattern with `config/demography.csv`

For each simulation in `config/parameters.tsv` you need to define a switch called `custom_demography`. If `custom_demography != 1`, then slim will look for r and K values in `config/parameters.tsv` to use a logistic growth/death model for the population. If `custom_demography == 1`, then slim will look for `config/demography.csv` which specifies a cutom demographic pattern. It is a headerless csv file with two columns:

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