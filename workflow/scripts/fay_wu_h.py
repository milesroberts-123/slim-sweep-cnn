import click
from cyvcf2 import VCF
import itertools
from collections import Counter
from collections import deque
from itertools import islice
import numpy as np

#from itertools import zip_longest

# https://stackoverflow.com/questions/3415072/pythonic-way-to-iterate-over-sequence-4-items-at-a-time
def grouper(n, iterable, fillvalue=None):
    "grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return zip_longest(fillvalue=fillvalue, *args)

# https://stackoverflow.com/questions/952914/how-do-i-make-a-flat-list-out-of-a-list-of-lists
def flatten(xss):
    return [x for xs in xss for x in xs]

# https://napsterinblue.github.io/notes/python/internals/itertools_sliding_window/
def sliding_window(iterable, n):
    iterables = itertools.tee(iterable, n)
    for iterable, num_skipped in zip(iterables, itertools.count()):
        for _ in range(num_skipped):
            next(iterable, None)
    return zip(*iterables)

#
def sliding_window_with_skip(iterable, window_size, skip_size=1):
    """
    Generates sliding windows over an iterable with a specified skip size.

    Args:
        iterable: The input iterable.
        window_size: The size of each sliding window.
        skip_size: The number of elements to skip after yielding each window.
                   Defaults to 1 for a standard sliding window.

    Yields:
        A tuple representing a sliding window.
    """
    if not isinstance(window_size, int) or window_size <= 0:
        raise ValueError("window_size must be a positive integer.")
    if not isinstance(skip_size, int) or skip_size <= 0:
        raise ValueError("skip_size must be a positive integer.")

    it = iter(iterable)
    window = deque(islice(it, window_size))

    # Yield initial window if it's full
    if len(window) == window_size:
        yield tuple(window)

    # Continue yielding windows with the specified skip
    while True:
        # Advance the iterator by skip_size
        for _ in range(skip_size):
            try:
                window.popleft()
                window.append(next(it))
            except StopIteration:
                return # End of iterable

        # Yield the current window if it's full
        if len(window) == window_size:
            yield tuple(window)
        else:
            return # Not enough elements to form a full window

def allele_counts(window):
       # get genotypes and flatten into list
       genotypes = [variant.genotypes for variant in window]
       fg = flatten(genotypes)
       # remove phase info
       fg = [item for item in fg if type(item) == int]
       # count number of alleles of each type
       ac_dict = Counter(fg)
       ac = list(ac_dict.values())
       return(ac)

def allele_frequencies(acs):
       count_total = sum(acs)
       return([ac/count_total for ac in acs])

def theta_pi(afs, acs):
    n = sum(acs)
    sqaf = [af**2 for af in afs]
    return(1 - sum(sqaf))

# define click options
@click.command(context_settings={'show_default': True})
@click.option("-v", "--vcf-file", default=None, help="Path to VCF file", multiple=False)
@click.option("-w","--window-length", default=129, help="number of snps to include in window", type = click.INT)
@click.option("-s","--skip-length", default=1, help="number of snps to skip between windows", type = click.INT)
@click.option("-o", "--output-prefix", default="sweep_stats", help="Prefix for output files")

# Main function that combines all other functions
def main(vcf_file, window_length, skip_length, output_prefix):


#    for window in grouper(window_length, VCF(vcf_file)):
#       CHROM = [variant.CHROM for variant in window]
#       print(CHROM)
#       print([variant.__dir__ for variant in window])

    i = 0
    for window in sliding_window_with_skip(VCF(vcf_file), window_length, skip_length):
       print("Window: " + str(i))

       POS = [variant.POS for variant in window]
       start = min(POS)
       start = max(POS)
#AAF = [variant.aaf for variant in window]
       #RAF = [1 - x for x in AAF]

       # extract genotypes for every variant
       genotypes = [variant.genotypes for variant in window]

       # create genotype array from window
       genotype_array = np.array(genotypes, dtype=str)

       # get allele counts

       # get allele frequencies
       print(genotype_array)
       #fg = flatten(genotypes)
       #fg = [item for item in fg if type(item) == int]
       #print(fg)
       #ac_dict = Counter(fg)
       #print(ac.keys())
       #ac = list(ac_dict.values())
       #count_total = sum(ac)
       #print([x/count_total for x in ac])

       #acs = allele_counts(window)
       #afs = allele_frequencies(acs)
       #print(acs)
       #print(afs)
       #print(theta_pi(afs))

       i += 1

if __name__ == '__main__':
    main()
