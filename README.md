# slim-sweep-cnn

[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Snakemake](https://img.shields.io/badge/snakemake-≥9.6.0-brightgreen.svg)](https://snakemake.github.io)

This workflow trains simulates selective sweeps in SLiM and then calculates many sweep summary statistics and converts the sweep region into images. These outputs can be used to train convolutional neural networks or perform approximate bayesian computation. The workflow was developed and tested using snakemake v 9.6.0 

# Contents

[Setup](#setup)

[Inputs](#inputs)

[Usage](#usage)

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

# Usage

Example commands for running the snakemake workflow are in `src/s01_snakemake.bash`. Make sure to change `--partition`, `--account`, `--jobs`, and `--cores` to account for your cluster's computational limits. The command below includes retrying each job twice (i.e. a total of three attempts per job, `--retries 2`) and continuing even when jobs fail (`--keep-going`). This is necessary because you can expect that not all sweep simulations will complete successfully, depending what area of parameter space you're exploring.

### Run whole workflow with conda envs on slurm cluster

`snakemake --sdm conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 1 --keep-going`

### Run workflow in batches with conda envs on slurm cluster

If you're doing lots of simulations, the DAG can be large and take awhile to compute. To calculate the DAG in small batches use `--batch`. The `all` rule is the best rule to use for batching. To do 50 batches, for example, you would do this for loop:

```
for num in {1..50}
do
  snakemake --sdm conda --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 1 --keep-going --batch all=$num/50
done
```

### Run workflow whole workflow at once with singularity on slurm cluster

Instead of downloading and building all of the conda environments, you can just download a container with all of the conda environments pre-installed.

To do this, you need to pass `--sdm conda apptainer` to your snakemake command and also your snakemake working directory with `--singularity-args "--bind <SNAKEMAKE_WORKING_DIRECTORY>"`. For example, if you pulled the repo to your home directory, the command will look like:

```
snakemake --sdm conda apptainer --singularity-args "--bind ~/slim-sweep-cnn/workflow" --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 1 --keep-going
```

### Run workflow in batches with singularity on slurm cluster

To combine batching with sigularity/apptainer, you can do:

```
for num in {1..50}
do
  snakemake --sdm conda apptainer --singularity-args "--bind ~/slim-sweep-cnn/workflow" --rerun-incomplete --rerun-triggers mtime --scheduler greedy --retries 1 --keep-going --batch all=$num/50
done
```

### Run workflow on local machine

The default snakemake profile is to run on a slurm cluster, but you can take any of the above commands and run snakemake on your local machine by adding `--profile profiles/local` to your snakemake command. Make sure to edit `workflow/profiles/local/config.yaml` to reflect the hardware limits of your local machine.

# Explore data

The workflow will output one image per slim simulation and one table of selective sweep summary statistics per slim simulation. Before training the models further, you should import the completed simulations into R and consider how to subset the data into training, testing, and validation. An example of how we did this step is in `src/s03_data_exploration.Rmd`

# Train models

## Train ABC models

After, at minimum, partitioning your data into training, validation, and testing, you can follow `src/s03_data_exploration.Rmd` for building and evaluting ABC models.

## Train CNN models

An example of how to start training the CNN is in `src/s04_train.sh`.
