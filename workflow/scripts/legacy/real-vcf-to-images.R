# load packages
print("Loading packages...")
library(ggplot2)
library(reshape2)
library(ggnewscale)
library(cowplot)

# parse arguments
print("Parsing arguments...")
args = commandArgs(trailingOnly=TRUE)
distMethod = args[1]
clustMethod = args[2]
vcfs = args[3:length(args)]

print(vcfs)
print(distMethod)
print(clustMethod)

# function to min-max normalize vector of variant postions
minmaxnorm = function(x){
  x = as.numeric(x)
  (x - min(x))/(max(x) - min(x))
}

# load in vcfs one at a time
v = 1
for(vcf in vcfs){
    # load simulation output
    print("Reading in table...")
    varTab = read.table(vcf, header = T)

    # subset to only some snps, if needed
    print("Number of variants:")
    varCount = nrow(varTab)
    print(varCount)

    # loop over vcf in chunks
    i = 1
    j = 128

    while(j <= varCount){
        print(paste("Processing chunk:", i, j))

        # subset one vcf chunk
        window = varTab[i:j,]
        start = varTab[i, "POS"]
        end = varTab[j, "POS"]
 
        # output table of min-max normalized variant positions
        print("Outputing table of positions...")
        write.table(data.frame(POSNORM = minmaxnorm(window[,"POS"])), paste(v, "_", start, "_", end, ".txt", sep = ""), row.names = F, quote = F, sep = "\t")

        # cluster rows of dataframe
        print("Grouping genetically similar individuals...")
        window_nopos = window[,c(-1:-3)] # remove position info
        window_clusters = hclust(dist(t(window_nopos), method = distMethod), method = clustMethod) # transpose matrix, then measure dis>

        print("Re-ordering columns to reflect groupings...")
        window = window[,c(1:3, 3 + window_clusters$order)] # keep first three columns unchanged, then add orderings

        #print("What genotype matrix looks like:")
        #head(window[,1:6])

        # renumber sites
        print("Renumber sites...")
        window$POS2 = 1:128

        # melt sorted matrix to dataframe, so you can use ggplot
        print("Melting matrix to frame for plotting...")
        window = melt(window, id.vars = c("CHROM", "POS", "POS2", "INFO"))

        #print("Head of frame:")
        #head(window)

        #print("Tail of frame:")
        #tail(window)

        print("Plotting data...")

        ggplot(mapping = aes(POS2, variable)) +
            geom_tile(data = window, aes(x = POS2, y = variable, fill = as.numeric(value), width = 1)) +
            scale_fill_gradient2(low = "black", mid = "grey", high = "white", midpoint = 0.5) +
            theme_nothing() +
            labs(x = NULL, y = NULL) +
            scale_x_discrete(expand=c(0,0)) +
            scale_y_discrete(expand=c(0,0))

        # low resolution plots for model training
        print("Saving plot...")
        ggsave(paste(v, "_", start, "_", end, ".png", sep = ""), width = 128, height = 128, units = "px", dpi = 600)

        # move to next chunk
        i = i + 128
        j = j + 128
    }
    # increment vcf counter
    v = v + 1
}

print("Done! :)")
