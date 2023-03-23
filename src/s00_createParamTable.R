# hyperparameters for simulation parameters
K = 100 # number of sims 
train_test_val_split = c(0.8, 0.1, 0.1) # train/test/validation split

# build table of paramters
params = data.frame(
  ID = 1:K,
  #Nc = round(runif(K, min = 100, max = 40000)),
  #t = round(runif(K, min = 2, max = 9999)),
  #Na = round(runif(K, min = 100, max = 40000)),
  alpha = runif(K, min = -0.1, max = 0.1), # mean fitness effect of nonsynonymous DFE
  beta = runif(K, min = 0, max = 4) # shape parameter of nonsynonymous DFE
  #h = runif(K, min = 0, max = 1), # dominance of nonsynonymous mutations
  #mu = runif(K, min = 1e-9, max = 1e-8),
  #rho = runif(K, min = 1e-9, max = 1e-8)
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

# re-order parameter table so it looks nice
print("Re-ordering parameter table...")
params = params[order(params$ID),]

# save result
print("Saving table of parameter results...")
write.table(params, "../workflow/data/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
#sample(c("train", "test", "val"), replace = T, size = K, prob = train_test_val_split)
#train = params[sample(1:K, size = 0.99*K),]

#test = params[!(params$ID %in% train$ID),]

# want TRUE
#nrow(params) == nrow(train) + nrow(test)

# want FALSE
#any(test$ID %in% train$ID)
