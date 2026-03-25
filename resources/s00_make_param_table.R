library(yaml)
library(dplyr)

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
#params = data.frame(
#  ID = 1:K, # unique ID for each simulation
#  Q = 1,
#  N = sample(5000:20000, size = K, replace = T), # initial population size
#  h = runif(K, min = 0, max = 1), # dominance coefficient
#  mu = 10^runif(K, min = -8.5, max = -7.5),
#  R = 10^runif(K, min = -9, max = -7),
#  tau = round(10^runif(K, min = 0, max = 2)), # sweep ages
#  L = sample(c(1e6, 5e6), size = K, replace = T),
#  m = sample(c(51, 121, 241), size = K, replace = T),
#  n = sample(c(51, 121, 241), size = K, replace = T),
#  kappa = 10
#)

params <- expand.grid(
  Q = 1,
  L = c(1e6, 5e6),
  m = c(51, 121, 241),
  n = c(51, 121, 241),
  kappa = 10,
  rep = 1:2700
)

K <- nrow(params)

params$N <- sample(5000:20000, size = K, replace = T), # initial population size
params$h <- runif(K, min = 0, max = 1), # dominance coefficient
params$mu <- 10^runif(K, min = -8.5, max = -7.5)
params$R <- 10^runif(K, min = -9, max = -7)
params$tau <- round(10^runif(K, min = 0, max = 2)), # sweep ages

# selection coefficient of sweep
print("Sampling sweep selection coefficient...")

sample_sel_coeff = function(x){
  10^runif(1, min = log10(1/x), max = 0)
}

params$sweepS = unlist(lapply(params$N, FUN = sample_sel_coeff))

all(params$sweepS > 1/params$N)

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

# If there are multiple parameters, make sure they're not correlated by chance
print("Correlations between parameters across simulations:")
cor(params[,-1])

# save result
print("Saving table of parameter results...")
write.table(params, "../config/parameters.tsv", quote = F, row.names = F, sep = "\t")

print("Done! :)")
