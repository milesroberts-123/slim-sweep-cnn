print("Parsing arguments...")
args = commandArgs(trailingOnly=TRUE)
input = args[1]
output = args[2]

print(input)
print(output)

# load fix times
fix_times = read.table(input, sep = " ", header = F, col.names = c("ID", "tf"))

width = 0.05
max_bin_height = 1000

# bin fixation times
breaks = seq(from = min(log10(fix_times$tf)) - width, to = max(log10(fix_times$tf)) + width, by = width)
fix_times$bin = cut(log10(fix_times$tf), breaks = breaks)
table(fix_times$bin)

# adjust max bin height to it's highest possible value
# if the minimum bin height is 1000 and the next smallest bin is 1007, adjust max height to 1007
max_bin_height = min(table(fix_times$bin)[table(fix_times$bin) >= max_bin_height])

# loop through each bin and randomly downsample simulations to the max bin height
strat_sample = NULL
for(bin in unique(fix_times$bin)){
  fix_times_bin = fix_times[(fix_times$bin == bin),]
  if(nrow(fix_times_bin) >= max_bin_height){
    down_sampled_bin = fix_times_bin[sample(1:nrow(fix_times_bin), replace = F, size = max_bin_height),]
    strat_sample = rbind(strat_sample, down_sampled_bin)
  }
}

# summarize size of stratified sample
table(strat_sample$bin)
nrow(strat_sample)

# randomly partition data into training, testing, and validation sets
train_n = round(nrow(strat_sample)*0.8)
test_n = round(nrow(strat_sample)*0.1)
val_n = round(nrow(strat_sample)*0.1)

excess = (train_n + test_n + val_n) - nrow(strat_sample) # remove excess sims from partitioning
train_n = train_n - excess

train_n + test_n + val_n == nrow(strat_sample) # output should be TRUE

split_column = c(rep("train", times = train_n), rep("test", times = test_n), rep("val", times = val_n))

strat_sample$split = sample(split_column, replace = F, size = nrow(strat_sample))

table(strat_sample$split)

# What mean squared error would you expect if model predicted the mean for every image?
# This naive model would result in a loss equal to the variance of the response
var(log10(strat_sample$tf))

# save stratified sample
write.table(output, strat_sample, sep = "\t", quote = F, row.names = F)