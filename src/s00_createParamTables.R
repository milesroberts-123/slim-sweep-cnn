# hyperparameters for simulation parameters
K = 5000 # number of sims 
train_test_val_split = c(0.9, 0.05, 0.05) # train/test/validation split
gff = "../workflow/data/genome/Osativa_323_v7.0.gene.gff3" # path to genome annotation

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
  ID = 1:K,
  gene = sample(genes, size = K, replace = T),
  meanS = runif(K, min = -0.05, max = 0), # mean fitness effect of nonsynonymous DFE
  alpha = c(runif(K/2, min = 0, max = 1), runif(K/2, min = 1, max = 24)), # shape parameter of nonsynonymous DFE
  h = runif(K, min = 0, max = 1), # dominance coefficient
  sweepS = runif(K, min = 0, max = 0.05), # effect of beneficial mutation
  N = round(runif(K, min = 500, 30000)), # population size
  sigmaA = runif(K, min = 0, max = 1), # ancestral selfing rate
  sigmaC = runif(K, min = 0, max = 1), # current selfing rate
  tsigma = round(runif(K, min = 100, 25000)), # generation of selfing rate transition
  tsweep = round(runif(K, min = 100, max = 25000)) # generation where beneficial mutation introduced
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
write.table(params, "../workflow/data/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
