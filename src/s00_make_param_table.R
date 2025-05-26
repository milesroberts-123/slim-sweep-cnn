library(yaml)

# parse out yaml path
args = commandArgs(trailingOnly=TRUE)
yamlpath = args[1]

# load yaml file
yamlfile = yaml.load_file(yamlpath)

# parse out individual parameters in yaml file
K = yamlfile[["K"]]
demography = yamlfile[["demography"]]

# build table of paramters
print("Building table of parameters...")
params = data.frame(
  ID = 1:K, # unique ID for each simulation
  Q = 1,
  N = sample(5000:20000, size = K, replace = T), # initial population size
  h = runif(K, min = 0, max = 1), # dominance coefficient
  sigma = 0,
  mu = 10^runif(K, min = -8.5, max = -7.5),
  R = 10^runif(K, min = -9, max = -7),
  tau = round(10^runif(K, min = 0, max = 4)),
  kappa = 1,
  f0 = 0,
  f1 = 1,
  n = 1,
  ncf = 0
)

# selection coefficient of sweep
print("Sampling sweep selection coefficient...")

sample_sel_coeff = function(x){
  10^runif(1, min = log10(1/x), max = 0)
}

params$sweepS = unlist(lapply(params$N, FUN = sample_sel_coeff))

all(params$sweepS > 1/params$N)

# spacing between beneficial mutations
print("Sampling lambda...")
params$lambda[(params$n == 1)] = 999999999 # use 9999 instead of NA
params$lambda[(params$n > 1)] = runif(sum(params$n > 1), min = 0, max = 10000) # average waiting time between beneficial mutations

# mean length of copies in cross over events
print("Sampling cl...")
params$cl[(params$ncf == 0)] = 99
params$cl[(params$ncf > 0)] = sample(100:1000, size = K/2, replace = T)

# fraction of tracts that are "simple" as opposed to complex
print("Sampling fsimple...")
params$fsimple[(params$ncf == 0)] = 0.999999999
params$fsimple[(params$ncf > 0)] = runif(K/2, min = 0, max = 1) 
  
# carrying capacity
# determine which samples will be shrinking, the growth rate for shrinking samples can't be too high, or else you'll get negative population sizes
print("Sampling r and K based on demography...")

if(demography == "constant"){
  params$r = 0 
  params$K = params$N
  params$custom_demography = 0
}

if(demography == "growth"){
  params$r = runif(K, min = 0, max = 0.5)
  params$K = round(params$N*runif(K, min = 1.01, max = 2))
  params$custom_demography = 0
}

if(demography == "decay"){
  params$r = runif(K, min = 0, max = 0.5)
  params$K = round(params$N*runif(K, min = 0.5, max = 0.99))
  params$custom_demography = 0
}

if(demography == "cycle"){
  params$r = runif(K, min = 2, max = sqrt(6))
  params$K = round(params$N*runif(K, min = 0.8, max = 1.2))
  params$custom_demography = 0
}

if(demography == "chaos"){
  params$r = runif(K, min = sqrt(6), max = 3)
  params$K = round(params$N*runif(K, min = 0.8, max = 1.2))
  params$custom_demography = 0
}

if(demography == "custom"){
  params$r = 0
  params$K = 0
  params$Q = runif(K, min = 10, max = 20)
  params$custom_demography = 1
}

# proportions of deleterious, beneficial, neutral mutations
# neutral mutation > deleterious mutation > beneficial mutation
print("Sampling B, U, and M...")
#params$B = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 0.03)), size = K, replace = F) # beneficial mutations
params$B = 0
#params$U = sample(c(rep(0, times = K/2), runif(K/2, min = 0, max = 0.03)), size = K, replace = F) # deleterious mutations
params$U = 0
params$M = 1 - params$B - params$U # neutral mutations

# dominance for deleterious mutations
print("Sampling DFE parameters...")
params$hU[(params$U > 0)] = runif(K/2)
params$hU[(params$U == 0)] = 0.999999999

# dominance for beneficial mutations
params$hB[(params$B > 0)] = runif(K/2)
params$hB[(params$B == 0)] = 0.999999999

# average effect of beneficial mutation
params$bBar[(params$B > 0)] = 10^runif(K/2, min = -7, max = -5)
params$bBar[(params$B == 0)] = 0.999999999

# average effect of linked deleterious mutation
params$uBar[(params$U > 0)] = (10^runif(K/2, min = -7, max = -5))*(-1)
params$uBar[(params$U == 0)] = -0.999999999

# shape parameter for deleterious DFE
params$alpha[(params$U > 0)] = runif(K/2, min = 0, max = 5) 
params$alpha[(params$U == 0)] = 0.999999999

# check that all proportions add to one
print("Checking that all proportions add to one...")
all.equal(rep(1, times = nrow(params)),c(params$M + params$U + params$B))

# show distributions of parameters
summary(params)

# If there are multiple parameters, make sure they're not correlated by chance
print("Correlations between parameters across simulations:")
cor(params[,-1])

# save result
print("Saving table of parameter results...")
write.table(params, "../config/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
