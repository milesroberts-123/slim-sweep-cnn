library(yaml)

# parse out yaml path
args = commandArgs(trailingOnly=TRUE)
yamlpath = args[1]

# load yaml file
yamlfile = yaml.load_file(yamlpath)

# parse out individual parameters in yaml file
K = yamlfile[["K"]]
train_test_val_split = c(yamlfile[["train"]], yamlfile[["test"]], yamlfile[["val"]])
#gff = yamlfile[["gff"]]

#K = args[1] # number of sims 
#train_test_val_split = c(args[2], args[3], args[4]) # train/test/validation split
#gff = args[5] # path to genome annotation
#G = 100000 # Length of simulations post burn-in

# load list of genes
#print("Reading genome annotation...")
#genome = read.table(gff, skip = 3, sep = "\t", header = F)

# head(genome)

# extract gene names
#print("Extracting gene IDs...")
#genome = genome[(genome[,3] == "mRNA"),]

#genes = genome[,9]
#genes = gsub(";.*", "", genes)
#genes = gsub("ID=", "", genes)

# head(genes)

# build table of paramters
print("Building table of parameters...")
params = data.frame(
  ID = 1:K, # unique ID for each simulation
  h = 0.5, # dominance coefficient
  sweepS = runif(K, min = 0.001, max = 1), # effect of beneficial mutation
  sigma = 0, # rate of selfing
  N = 1000, # population size
  mu = 1e-8, # mutation rate
  R = 1e-8 # Recombination rate
)

# If there are multiple parameters, make sure they're not correlated by chance
print("Correlations between parameters across simulations:")
cor(params[,-1])

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

table(params$split)

# re-order parameter table so it looks nice
print("Re-ordering parameter table...")
params = params[order(params$ID),]

# save result
print("Saving table of parameter results...")
write.table(params, "../config/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
