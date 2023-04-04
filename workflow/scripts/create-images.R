# load packages
print("Loading packages...")
library(ggplot2)
library(reshape2)
library(ggnewscale)
library(cowplot)

# parse arguments
print("Parsing arguments...")
args = commandArgs(trailingOnly=TRUE)
input = args[1]
output = args[2]

print(input)
print(output)

# load simulation output
print("Reading in table...")
simvar = read.table(input, header = T)

# subset to only some snps, if needed
print("Number of variants:")
varCount = nrow(simvar)
print(varCount)

if(varCount > 128){
 print("Subsampling table because there are too many variants...")
 simvar = simvar[sort(sample(1:varCount, 128, replace = F)),]
}

# Add zero-padds if needed
if(varCount < 128){
 print("Zero-padding image because there are not enough variants...")
 lastVar = simvar[varCount,"POS"]
 print("Last variant position is:")
 print(lastVar)
 for(i in 1:(128 - varCount)){
  simvar = rbind(simvar, c(1, lastVar + i, "MT=0;", rep(0, times = 128)))
 }
}

print("What genotype matrix looks like:")
print("Head:")
head(simvar[,1:6])
print("Tail:")
tail(simvar[,1:6])

# label syn and nonsyn sites
print("Labeling mutations by type...")
simvar$INFO[grepl("MT=0;", simvar$INFO)] = "s"
simvar$INFO[grepl("MT=4;|MT=5;", simvar$INFO)] = "n"

# collapse monomorphic sites
print("Collapsing monomorphic sites...")
simvar$POS2 = 1:128

# melt sorted matrix to dataframe, so you can use ggplot
print("Melting matrix to frame for plotting...")
simvar = melt(simvar, id.vars = c("CHROM", "POS", "POS2", "INFO"))

print("Head of frame:")
head(simvar)

print("Tail of frame:")
tail(simvar)

# create new position column where monomorphic sites are collapsed
#print("Collapsing monomorphic sites...")
#simvar$POS2 = NA
#i = 1
#for (j in sort(unique(simvar$POS))) {
#	simvar$POS2[simvar$POS == j] = i
#	i = i + 1
#}

# split variants by type, so that you can color them differently
print("Spliting data by variant type...")
svar = simvar[(simvar$INFO == "s"),]
nvar = simvar[(simvar$INFO == "n"),]

# Convert variant sites into an image for CNN
# using multiple color/fill scales in a single plot:
# https://stackoverflow.com/questions/58362432/how-merge-two-different-scale-color-gradient-with-ggplot
# removing margins from plot area:
# https://stackoverflow.com/questions/31254533/when-using-ggplot-in-r-how-do-i-remove-margins-surrounding-the-plot-area
print("Plotting data...")

ggplot(mapping = aes(POS2, variable)) +
  geom_tile(data = svar, aes(x = POS2, y = variable, fill = as.numeric(value), width = 1)) +
  #scale_fill_gradient(low = "black", high = "white") +
  scale_fill_gradient2(low = "black", mid = "grey", high = "white", midpoint = 0.5) +
  # Important: define a colour/fill scale before calling a new_scale_* function
  new_scale_fill() +
  geom_tile(data = nvar, aes(x = POS2, y = variable, fill = as.numeric(value), width = 1)) +
  scale_fill_gradient2(low = "blue", mid = "cyan", high = "green", midpoint = 0.5) +
  theme_nothing() +
  labs(x = NULL, y = NULL) +
  scale_x_discrete(expand=c(0,0)) +
  scale_y_discrete(expand=c(0,0))

print("Saving plot...")
ggsave(output, width = 128, height = 128, units = "px", dpi = 600)

print("Done! :)")
