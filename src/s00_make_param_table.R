

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
  h = runif(K, min = 0, max = 1), # dominance coefficient
  sweepS = sample(c(rep(0, times = K/2), 10^runif(K/2, min = -2, max = 0)), size = K, replace = F), # effect of beneficial mutation
  sigma = runif(K, min = 0, max = 1), # rate of selfing
  N = sample(1000:1500, size = K, replace  = T), # population size
  mu = 10^runif(K, min = -8, max = -7.25), # mutation rate
  R = 10^runif(K, min = -10, max = -7), # recombination rate
  tau = round(runif(K, min = 0, max = 500)), # time between fixation and observation
  f0 = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 0.2)), size = K, replace = F), # establishment frequency
  f1 = sample(c(rep(1, times = K/2), runif(K/2, min = 0.8, max = 1)), size = K, replace = F), # threshold frequency for partial sweep
  n = sample(c(rep(1, times = K/2), rep(2, times = K/2)), replace = F, size = K), # number of genomes to introduce beneficial mutations to after burn-in
  lambda = runif(K, min = 5, max = 20), # average waiting time between beneficial mutations
  r = sample(c(rep(0, times = K/5), runif(2*K/5, min = 0, max = 0.5), runif(K/5, min = 2, max = sqrt(6)), runif(K/5, min = sqrt(6), max = 3)), size = K, replace = F), # growth rate
  ncf = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 1)), size = K, replace = F), # fraction of recombination events that are not cross overs
  cl = sample(100:1000, size = K, replace = T), # mean length of copies in cross over events
  fsimple = runif(K, min = 0, max = 1) # fraction of tracts that are "simple" as opposed to complex
)

# carrying capacity
# determine which samples will be shrinking, the growth rate for shrinking samples can't be too high, or else you'll get negative population sizes
decID = sample(params$ID[( (params$r > 0) & (params$r < 0.5) )], size = K/5, replace = F)
params$K = NA
params$K[(params$ID %in% decID)] = params$N[(params$ID %in% decID)]*runif(length(decID), min = 0.5, max = 0.9)
params$K[!(params$ID %in% decID)]  = params$N[!(params$ID %in% decID)]/runif(K - length(decID), min = 0.5, max = 0.9)

#params$K = 1000

# proportions of deleterious, beneficial, neutral mutations
# neutral mutation > deleterious mutation > beneficial mutation
params$B = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 0.01)), size = K, replace = F) # beneficial mutations
params$U = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 0.04)), size = K, replace = F) # deleterious mutations
params$M = 1 - params$B - params$U # neutral mutations

#bisect_interval = function(x){
#  runif(1, min = x, max = 1)
#}
#bisect = unlist(lapply(params$B, bisect_interval))
#params$M = pmax(bisect - params$B, 1 - bisect) # neutral mutations
#params$U = pmin(bisect - params$B, 1 - bisect) # deleterious mutations

params$hU = runif(K) # dominance for deleterious mutations
params$hB = runif(K) # dominance for beneficial mutations

params$bBar = runif(K, min = 0, max = 1e-3) # average effect of beneficial mutation
params$uBar = runif(K, min = -0.02, max = 0) # average effect of deleterious mutation
params$alpha = runif(K) # shape parameter for deleterious DFE

# check that all proportions add to one
print("Checking that all proportions add to one...")
all.equal(rep(1, times = nrow(params)),c(params$M + params$U + params$B))

# show distributions of parameters
summary(params)

print("Table of number of mutations:")
table(params$n)

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
