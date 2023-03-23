library(ggplot2)
library(reshape2)
library(ggnewscale)
library(cowplot)

# load simulation output
simvar = read.table("slim.table", header = T)

# label syn and nonsyn sites
simvar$INFO[grepl("MT=0;", simvar$INFO)] = "s"
simvar$INFO[grepl("MT=4;", simvar$INFO)] = "n"

# melt sorted matrix to dataframe
simvar = melt(simvar, id.vars = c("CHROM", "POS", "INFO"))

# create new position column where monomorphic sites are collapsed
simvar$POS2 = NA
i = 1
for (j in sort(unique(simvar$POS))) {
	simvar$POS2[simvar$POS == j] = i
	i = i + 1
}

# split variants by type
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

ggsave("slim-no-monomorphisms.jpg", width = 128, height = 128, units = "px", dpi = 300)
  
  #theme_void()
# plot alignments separately, then combine them
#ggplot(simvar) +
#	geom_tile(simvar[(simvar$INFO == "s"),], aes(x = POS2, y = variable, fill = value)) +

#splot = ggplot(svar, aes(x = POS2, y = variable, fill = value)) +
#        geom_tile() +
#        scale_fill_gradient(low="black", high="white") +
#        theme_classic()

#nplot = ggplot(nvar, aes(x = POS2, y = variable, fill = value)) +
#        geom_tile() +
#        scale_fill_gradient(low="black", high="green") +
#        theme_classic()

#splot + nplot

#ggsave("slim-no-monomorphisms.jpg")

# plot alignments, compare sorted and unsorted
# ggplot(simvar, aes(x = POS, y = variable, fill = value, color = INFO)) +
#	geom_tile() +
#	scale_fill_gradient(low="black", high="white") +
#	scale_color_manual(values=c("#0000FF", "#00FF00")) +
#	theme_classic()


#ggsave("slim.jpg")

#ggplot(simvar, aes(x = POS2, y = variable, fill = value, alpha = as.integer(as.factor(INFO)))) +
#       geom_tile() +
#	scale_fill_gradient(low="black", high="white") +
	#scale_color_manual(values=c("#0000FF", "#00FF00")) +
#	scale_alpha_continuous(name = "INFO", range = c(0.25, 0.75)) +
#	theme_classic()


# print(simvar)
