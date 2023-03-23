library(ggplot2)
library(reshape2)
library(ggnewscale)
library(cowplot)

args = commandArgs(trailingOnly=TRUE)

input = args[1]
output = args[2]

# load simulation output
simvar = read.table(input, header = T)

# label syn and nonsyn sites
simvar$INFO[grepl("MT=0;", simvar$INFO)] = "s"
simvar$INFO[grepl("MT=4;", simvar$INFO)] = "n"

# melt sorted matrix to dataframe, so you can use ggplot
simvar = melt(simvar, id.vars = c("CHROM", "POS", "INFO"))

# create new position column where monomorphic sites are collapsed
simvar$POS2 = NA
i = 1
for (j in sort(unique(simvar$POS))) {
	simvar$POS2[simvar$POS == j] = i
	i = i + 1
}

# split variants by type, so that you can color them differently
svar = simvar[(simvar$INFO == "s"),]
nvar = simvar[(simvar$INFO == "n"),]

# Convert variant sites into an image for CNN
# using multiple color/fill scales in a single plot:
# https://stackoverflow.com/questions/58362432/how-merge-two-different-scale-color-gradient-with-ggplot
# removing margins from plot area:
# https://stackoverflow.com/questions/31254533/when-using-ggplot-in-r-how-do-i-remove-margins-surrounding-the-plot-area
ggplot(mapping = aes(POS2, variable)) +
  geom_tile(data = svar, aes(fill = value)) +
  scale_fill_gradient(low = "black", high = "white") +
  # Important: define a colour/fill scale before calling a new_scale_* function
  new_scale_fill() +
  geom_tile(data = nvar, aes(fill = value)) +
  scale_fill_gradientn(colours = c("blue", "cyan", "green")) +
  theme_nothing() +
  labs(x = NULL, y = NULL) +
  scale_x_discrete(expand=c(0,0)) +
  scale_y_discrete(expand=c(0,0))

ggsave(output, width = 128, height = 128, units = "px", dpi = 300)
