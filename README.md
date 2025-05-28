This workflow trains a convolutional neural network using simulated selective sweeps with SLiM. The workflow was developed and tested using snakemake v 9.33.0 

# Contents

[Setup](#setup)

[Inputs](#inputs)

[Run workflow](#run-workflow-with-conda-on-a-slurm-cluster)

[Explore data](#explore-data)

[Train models](#train-models)

# Setup

1. Make sure you have [mamba](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) installed. 

2. Grab repository from github

```
git clone https://github.com/milesroberts-123/slim-sweep-cnn.git
```

3. Install snakemake and the cnn software using the provided yaml files

```
mamba env create --name snakemake --file snakemake-env.yaml
mamba env create --name cnn --file cnn-env.yaml
```

Now you can activate the enviornments with either snakemake or the CNN software with `mamba activate snakemake` or `mamba activate cnn`, respectively.

# Inputs

See `config/README.md` for full details. In short, the workflow requires 2 files, a yaml file of parameters that are fixed across all simulations (`config/config.yaml`) and a tsv file of SLiM parameters (`config/parameters.tsv`). Optionally, if you want SLiM to simulate a custom demographic pattern, then you must also provide another csv file (`config/demography.csv`). 

# Run workflow with conda on a slurm cluster

Example commands for running the snakemake workflow are in `src/s01_snakemake.bash`. Make sure to change `--partition`, `--account`, `--jobs`, and `--cores` to account for your cluster's computational limits. The command below includes retrying each job twice (i.e. a total of three attempts per job, `--retries 2`) and continuing even when jobs fail (`--keep-going`). This is necessary because you can expect that not all sweep simulations will complete successfully, depending what area of parameter space you're exploring.

## Run whole workflow at once on a slurm cluster

```
snakemake --cluster "sbatch --time={resources.time} --cpus-per-task={threads} --mem-per-cpu={resources.mem_mb_per_cpu} --partition=<YOUR PARTITION HERE> --account=<YOUR ACCOUNT HERE>" --jobs 950 --cores 950 --use-conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 2 --keep-going
```

## Run workflow in batches on a slurm cluster

```
# The number of batches you want to do.
# Increase this value if you have fewer computational resources so that the workflow executes in smaller chunks
numbatch=50

for curbatch in {1..$numbatch}
do
  snakemake --cluster "sbatch --time={resources.time} --cpus-per-task={threads} --mem-per-cpu={resources.mem_mb_per_cpu} --partition=<YOUR PARTITION HERE> --account=<YOUR ACCOUNT HERE>" --jobs 950 --cores 950 --use-conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 2 --keep-going --batch all=$curbatch/$numbatch
done
```

# Explore data

The workflow will output one image per slim simulation and one table of selective sweep summary statistics per slim simulation. Before training the models further, you should import the completed simulations into R and consider how to subset the data into training, testing, and validation. An example of how we did this step is in `src/s03_data_exploration.Rmd`

# Train models

## Train ABC models

After, at minimum, partitioning your data into training, validation, and testing, you can follow `src/s03_data_exploration.Rmd` for building and evaluting ABC models.

## Train CNN models

An example of how to start training the CNN is in `src/s04_train.sh`.
