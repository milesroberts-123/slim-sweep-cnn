import msprime
import pyslim
import tskit
import numpy as np
# Source - https://stackoverflow.com/a/16713986
# Posted by Pierre GM, modified by community. See post 'Timeline' for change history
# Retrieved 2026-03-06, License - CC BY-SA 4.0
import argparse

# Define the parser
parser = argparse.ArgumentParser(description='recapitate ')

# Declare an argument (`--algo`), saying that the 
# corresponding value should be stored in the `algo` 
# field, and using a default value if the argument 
# isn't given
parser.add_argument('--ID', action="store", dest='ID', default=0)
parser.add_argument('-N', action="store", dest='N', default=0)
parser.add_argument('-n', action="store", dest='n', default=0)
parser.add_argument('-L', action="store", dest='L', default=0)
parser.add_argument('-R', action="store", dest='R', default=0)
parser.add_argument('--mu', action="store", dest='mu', default=0)

# Now, parse the command line arguments and store the 
# values in the `args` variable
args = parser.parse_args()

# load ts from slim
print("Loading ts from slim...")
sts = tskit.load("slim_results/" + args.ID + ".trees")

print(f"The tree sequence has {sts.num_trees} trees\n"
      f"on a genome of length {sts.sequence_length},\n"
      f"{sts.num_individuals} individuals, {sts.num_samples} 'sample' genomes,\n"
      f"and {sts.num_mutations} mutations.")

individual_times = sts.individuals_time
for t in np.unique(individual_times):
    print(f"There are {np.sum(individual_times == t)} individuals from time {t}.")

# recapitate ts
print("Recapitating...")
rts = pyslim.recapitate(sts,
             recombination_rate=args.R,
             ancestral_Ne=int(args.N))

# sample individuals
rng = np.random.default_rng(seed=3)
alive_inds = pyslim.individuals_alive_at(rts, 0)
keep_indivs = rng.choice(alive_inds, int(args.n), replace=False)
keep_nodes = []
for i in keep_indivs:
  keep_nodes.extend(rts.individual(i).nodes)

nts = rts.simplify(keep_nodes, keep_input_roots=True)

print(f"Before, there were {rts.num_samples} sample nodes (and {rts.num_individuals} individuals)\n"
      f"in the tree sequence, and now there are {sts.num_samples} sample nodes\n"
      f"(and {sts.num_individuals} individuals).")

# Get all sample node IDs
#all_samples = rts.samples()

# Pick a random subset
#rng = np.random.default_rng()
#nodes_to_keep = rng.choice(all_samples, size=int(args.n), replace=False)

#nodes_to_keep = []
#for ind_id in keep_individual_ids:
#    individual = rts.individual(ind_id)
#    nodes_to_keep.extend(individual.nodes)

# Simplify the tree sequence to these nodes
#print("Simplifying...")
#nts = rts.simplify(nodes_to_keep)
#print(f"Sampled {nts.num_individuals} individuals and {nts.num_samples} nodes.")

# add mutations to ts
print("Adding mutations...")
next_id = pyslim.next_slim_mutation_id(nts)

mts = msprime.sim_mutations(
  nts,
  rate=args.mu,
  model=msprime.SLiMMutationModel(type=0, next_id=next_id),
  keep=True,
)

# output vcf
print("Output vcf...")
with open('msprime_results/' + args.ID + ".vcf", "w") as vcf_file:
    mts.write_vcf(vcf_file)

print("Done! :)")

