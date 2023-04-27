library(yaml)

# parse out yaml path
args = commandArgs(trailingOnly=TRUE)
yamlpath = args[1]

# load yaml file
yamlfile = yaml.load_file(yamlpath)

# parse out individual parameters in yaml file
K = yamlfile[["K"]]
train_test_val_split = c(yamlfile[["train"]], yamlfile[["test"]], yamlfile[["val"]])
gff = yamlfile[["gff"]]

#K = args[1] # number of sims 
#train_test_val_split = c(args[2], args[3], args[4]) # train/test/validation split
#gff = args[5] # path to genome annotation
#G = 100000 # Length of simulations post burn-in

# load list of genes
print("Reading genome annotation...")
genome = read.table(gff, skip = 3, sep = "\t", header = F)

# head(genome)

# extract gene names
print("Extracting gene IDs...")
genome = genome[(genome[,3] == "mRNA"),]

genes = genome[,9]
genes = gsub(";.*", "", genes)
genes = gsub("ID=", "", genes)

# head(genes)

# build table of paramters
print("Building table of parameters...")
params = data.frame(
  ID = 1:K, # unique ID for each simulation
  #gene = sample(genes, size = K, replace = T), # name of gene to be used as locus model in simulation
  gene = "LOC_Os01g01010.1.MSUv7.0", # name of gene to be used as locus model in simulation
  #meanS = runif(K, min = -0.05, max = 0), # mean fitness effect of nonsynonymous DFE
  meanS = -0.01, # mean fitness effect of nonsynonymous DFE
  #alpha = c(runif(K/2, min = 0, max = 1), runif(K/2, min = 1, max = 24)), # shape parameter of nonsynonymous DFE
  alpha = 0.5, # shape parameter of nonsynonymous DFE
  #h = runif(K, min = 0, max = 1), # dominance coefficient
  h = 0.1, # dominance coefficient
  sweepS = runif(K, min = 0, max = 0.02), # effect of beneficial mutation
  #N = round(runif(K, min = 500, 10000)), # population size
  N = 1000, # population size
  #sigmaA = runif(K, min = 0, max = 1), # ancestral selfing rate
  sigmaA = 0, # ancestral selfing rate
  #sigmaC = runif(K, min = 0, max = 1), # current selfing rate
  sigmaC = 0.25, # current selfing rate
  #tsigma = round(runif(K, min = 0, max = G)), # generation of selfing rate transition
  tsigma = 5000, # generation of selfing rate transition
  #tsweep = round(runif(K, min = 0, max = G)) # generation where beneficial mutation introduced
  tsweep = 10000 # generation where beneficial mutation introduced
  #mu = runif(K, min = 1e-9, max = 1e-8) # mutation rate
)

# If there are multiple parameters, make sure they're not correlated by chance
print("Correlations between parameters across simulations:")
cor(params[,c(-1,-2)])

# split into training and testing sets
params_split = c(
	rep("train", times = train_test_val_split[1]*K),
	rep("test", times = train_test_val_split[2]*K),
	rep("val", times = train_test_val_split[3]*K)
)

# summarize number of simulations in each split class
print("Number of sims in each split class:")
table(params_split)

# shuffle rows of dataset, then add split class vector
# this should randomly assign rows to testing, training, or validation
print("Randomly assinging parameter sets to split class...")
params = params[sample(1:K, size = K, replace = F),]
params$split = params_split

# re-order parameter table so it looks nice
print("Re-ordering parameter table...")
params = params[order(params$ID),]

# save result
print("Saving table of parameter results...")
write.table(params, "../config/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
