import os
import numpy
import datetime
import pandas
import allel
import math
import hashlib
import tqdm
import click
import scipy

# Make output directories
os.makedirs("data/sweep_stats/", exist_ok=True)

# function to load a VCF and make numpy array
def load_vcf(vcf):
    # load vcf
    print(datetime.datetime.now(), "Loading " + vcf + "...")
    callset = allel.read_vcf(vcf)

    # parse out different components
    gt = callset['calldata/GT']
    chrom = callset['variants/CHROM']
    pos = callset['variants/POS']
    samples = callset['samples']

    # combine all information vectors
    gt_all = numpy.concatenate((gt_all,gt), axis = 1) if 'gt_all' in vars() else gt
    samples_all = numpy.concatenate((samples_all,samples)) if 'samples_all' in vars() else samples

    # finally, convert gt to genotype array
    print(datetime.datetime.now(), "Converting VCF to genotype array...")
    gt_all = allel.GenotypeArray(gt_all)

    # flatten 1d vectors
    print(datetime.datetime.now(), "Flattening position information...")
    chrom = chrom.flatten()
    pos = pos.flatten()
    samples_all = samples_all.flatten()

    # final data size counts
    print(datetime.datetime.now(), "Final dataset size:")
    s,n,p = gt_all.shape
    print("Number of sites: " + str(s))
    print("Number of individuals: " + str(n))
    print("Ploidy level: " + str(p))

    return gt_all, chrom, pos, samples_all

# calculate allele frequencies
def get_allele_freqs(gt):
    allele_counts = gt.count_alleles()
    sample_sizes = numpy.sum(allele_counts, axis = 1)
    allele_freqs = allele_counts.to_frequencies()
    return(allele_freqs, sample_sizes)

# get variant sites
def get_variant_sites(gt):
    allele_counts = gt.count_alleles()
    var_sites = allele_counts.is_variant()
    return(var_sites)

# calculate harmonic sum
def harmonic_sum(n):
    return(numpy.sum(1/numpy.arange(1,n)))

vectorized_harmonic_sum = numpy.vectorize(harmonic_sum)

# calculate squared harmonic sum
def squared_harmonic_sum(n):
    squared_terms = numpy.arange(1,n)**2
    return(numpy.sum(1/squared_terms))

vectorized_squared_harmonic_sum = numpy.vectorize(squared_harmonic_sum)

# calculate nucleotide diversity for individual sites
def nucleotide_diversity(gt):
    # get allele frequencies
    allele_freqs, sample_sizes = get_allele_freqs(gt)

    # calculate homozygote frequencies
    diversity = (sample_sizes/(sample_sizes - 1))*(1 - numpy.sum(allele_freqs**2, axis = 1))

    return(diversity)

# calculate watterson's theta for individual sites
def wattersons_theta(gt):
    # count alleles by site
    allele_counts = gt.count_alleles()

    # variant sites = at least 1 non-reference call
    var_sites = allele_counts.is_variant()

    # sample_size = number of genotype calls
    sample_sizes = numpy.sum(allele_counts, axis = 1)
    denominator = vectorized_harmonic_sum(sample_sizes)

    return(var_sites/denominator)

# Tajima's d formula for when there is missing data
# Calculate tajima's d for individual sites, then average across sites
# Reference: https://doi.org/10.1093/genetics/iyad074
def tajimasd_incomplete(gt):
    # Tajima's D is only defined for variant sites
    #gt_var = gt[get_variant_sites(gt),:,:]

    # get numerator for tajima's d
    theta_pi = nucleotide_diversity(gt)
    theta_w = wattersons_theta(gt)

    numerator = theta_pi - theta_w

    # calculate variance
    N = get_allele_freqs(gt)[1]

    a1 = vectorized_harmonic_sum(N)

    b1 = (N + 1)/(3*(N-1))

    c1 = b1 - 1/a1

    e1 = c1/a1

    denominator = numpy.sqrt(e1)

    # finally, calculate tajima's d
    return(numerator/denominator)

# Tajima's d formula for when there's no missing data
def tajimasd_complete(gt):

    # get numerator for tajima's d
    theta_pi = numpy.sum(nucleotide_diversity(gt))
    theta_w = numpy.sum(wattersons_theta(gt))

    numerator = theta_pi - theta_w

    # calculate variance
    S = numpy.sum(get_variant_sites(gt))
    N = numpy.mean(get_allele_freqs(gt)[1])

    a1 = harmonic_sum(N)
    a2 = squared_harmonic_sum(N)

    b1 = (N + 1)/(3*(N-1))
    b2 = 2*(N**2 + N + 3)/(9*N*(N-1))

    c1 = b1 - 1/a1
    c2 = b2 - (N + 2)/(a1*N) + (a2/(a1**2))

    e1 = c1/a1
    e2 = c2/(a1**2 + a2)

    denominator = numpy.sqrt(e1*S + e2*S*(S-1))

    # finally, calculate tajima's d
    return([numerator/denominator, denominator])

# hash rows of numpy array
# Created with help of chatGPT
def hash_array_rows(array):
    # Initialize an empty list to store hash values
    hash_values = []

    # Iterate through each row and calculate the hash
    for row in array:
        # Convert the row to bytes before hashing
        row_bytes = row.tobytes()

        # Calculate the hash using hashlib
        row_hash = hashlib.sha256(row_bytes).hexdigest()

        # Append the hash to the list
        hash_values.append(row_hash)

    return numpy.asarray(hash_values)

# count number of unique diplotypes or haplotypes
def garud(gt):

    # subset to only variable sites
    #print(numpy.shape(gt))
    s,n,p = numpy.shape(gt)

    if s < 3:
        return ["NA", "NA", "NA", "NA", "NA", "NA"]

    # if data are unphased, then sum across ploidy dimmension
    gt = numpy.sum(gt, axis = 2)

    # hash genotypes
    hashes = hash_array_rows(gt)

    # get unique haplotypes and count frequencies for each
    haplos, hap_counts = numpy.unique(hashes, return_counts = True)
    num_haplos_result = len(haplos)

    # calculate Garud's H1
    sample_size = numpy.sum(hap_counts)
    hap_freqs = hap_counts/sample_size
    h1_result = numpy.sum(hap_freqs**2)

    # calculate Garud's H2
    hap_freqs_ordered = -numpy.sort(-hap_freqs)
    p1 = hap_freqs_ordered[0]
    h2_result = h1_result - p1**2

    # Calculate Garud's H12
    if num_haplos_result >= 2:
        p2 = hap_freqs_ordered[1]
        h12_result = h1_result + 2*p1*p2
    else:
        h12_result = "NA"

    # Calculate Garud's H123
    if num_haplos_result >= 3:
        p3 = hap_freqs_ordered[2]
        h123_result = (p1 + p2 + p3)**2 + numpy.sum(hap_freqs_ordered[3:,]**2)
    else:
        h123_result = "NA"

    # Calculate Garud's H2/H1
    h2h1_result = h2_result/h1_result

    result = [num_haplos_result, h1_result, h2_result, h12_result, h123_result, h2h1_result]
    #print(result)

    return(result)

# kern's GKL statistics
def kerns_gkl(gt):
    # Check if there are enough variant sites
    s,n,p = numpy.shape(gt)

    if s < 3:
        return (["NA","NA","NA"])

    # If data are unphased, sum across ploidy dimension
    gt = numpy.sum(gt, axis = 2)

    # mask missing genotypes
    gt = numpy.ma.masked_where(gt < 0,gt)

    # loop over pairs of columns
    xijs = []
    for i in tqdm.tqdm(range((gt.shape[1]) - 1), desc = "Counting mismatches..."):
        gti = gt[:,i]
        for j in range(i + 1, gt.shape[1]):
            # count number of genotype mismatches
            gtj = gt[:,j]
            xijs.append(numpy.sum(gti != gtj))

    gkl_vari = numpy.ma.var(xijs)
    gkl_skew = scipy.stats.skew(xijs, axis=0, nan_policy = 'omit')
    gkl_kurt = scipy.stats.kurtosis(xijs, axis=0, nan_policy = 'omit')

    return([gkl_vari,gkl_skew,gkl_kurt])

# average correlation between alleles
def kellys_zns(gt):
    pair_cor = allel.rogers_huff_r(gt.to_n_alt(fill = -1))
    mean_cor = numpy.nanmean(pair_cor**2)
    return(mean_cor)

# kims omega, comparing LD within vs between sides of sweep
def kims_omega(gt):
    gt = gt.to_n_alt(fill = -1)
    # Check if there are enough variant sites
    s,n = numpy.shape(gt)

    if s < 5:
        return("NA")

    # divide up variants to upstream and downstream
    left_snps = gt[:(s // 2)]
    right_snps = gt[(s // 2):]

    # check that both the left and right groups have enough variants to calculate a correlation
    sl,nl = numpy.shape(left_snps)
    sr,nr = numpy.shape(right_snps)
    if sl < 2 or sr < 2:
        return("NA")

    # calculate correlations between variants within groups
    left_cor = allel.rogers_huff_r(left_snps)
    right_cor = allel.rogers_huff_r(right_snps)

    # convert to coefficient of variation
    left_cor = numpy.nanmean(left_cor**2)
    right_cor = numpy.nanmean(right_cor**2)

    # calculate correlations between variants across groups
    bw_cor = allel.rogers_huff_r_between(left_snps, right_snps)
    bw_cor = numpy.nanmean(bw_cor.flatten()**2)

    return((left_cor + right_cor)/bw_cor)

# calculate average length of match between two haplotypes around a focal SNP
# I'll also min-max normalize hscan such that 1 = maximum possible match length, which would be the size of the total window in bp
# Reference: https://messerlab.org/resources/
def hscan(gt, pos, focus):
    print(datetime.datetime.now(), "Calculating hscan...")

    gt = gt.to_n_alt(fill=0)
    s,n = numpy.shape(gt)

    # Loop over each pair of haplotypes
    results = []
    for i in tqdm.tqdm(range(n-1)):
        for j in range(i, n):
            # Look at mismatches in the neighborhood of the site
            gti = gt[:,i]
            gtj = gt[:,j]
            mismatches = (gti != gtj)
            #print(gti)
            #print(gtj)
            #print(mismatches)
            if numpy.all(mismatches == False):
                results.append(1)
            else:
                # find first mismatch above and below focal site
                mismatch_pos = pos[mismatches]
                #print(mismatch_pos)
                dist_bw_mismatch_focus = focus - mismatch_pos
                #print(dist_bw_mismatch_focus)

                dist_bw_mismatch_focus_above = dist_bw_mismatch_focus[(dist_bw_mismatch_focus > 0)]
                dist_bw_mismatch_focus_below = dist_bw_mismatch_focus[(dist_bw_mismatch_focus < 0)]

                if len(dist_bw_mismatch_focus_above) == 0:
                    dist_bw_mismatch_focus_above = numpy.max(dist_bw_mismatch_focus)

                if len(dist_bw_mismatch_focus_below) == 0:
                    dist_bw_mismatch_focus_below = numpy.min(dist_bw_mismatch_focus)

                length_of_match = numpy.min(dist_bw_mismatch_focus_above) - numpy.max(dist_bw_mismatch_focus_below)
                results.append( length_of_match/(numpy.max(pos) - numpy.min(pos)) )
    return(numpy.mean(results))

# define click options
@click.command(context_settings={'show_default': True})
@click.option("-v", "--vcf", default=None, help="Path to VCF file", multiple=False)
@click.option("-w","--window-length", default=129, help="number of snps to include around focal site", type = click.INT)
@click.option("-f","--focus", default=None, help="Position where to anchor window for calculating sweep statistics", type = click.INT)
@click.option("-o", "--output-prefix", default="sweep_stats", help="Prefix for output files")

# Main function that combines all other functions
def main(vcf, window_length, focus, output_prefix):
    print(datetime.datetime.now(), "input options: vcf =", vcf, "window length =", window_length, "focus =", focus, "output prefix =", output_prefix)

    # load VCF and extract components
    print(datetime.datetime.now(),"Loading VCF...")
    gt, chrom, pos, samples = load_vcf(vcf)

    #print(pos)

    # create window of SNPs nearest to sweep site
    # if there aren't enough SNPs, just use as many as you can
    s,n,p = gt.shape
    if s > window_length:
        print(datetime.datetime.now(),"Isolating", window_length, "SNPs closest to focal site of", focus, "...")
        dist_from_focus = numpy.absolute(pos - focus)
        #print(dist_from_focus)

        sweep_idx = numpy.argpartition(dist_from_focus, window_length)
        sweep_idx = sweep_idx[:window_length]
        #print(sweep_idx)

        sweep_pos = pos[sweep_idx]
        sweep_gt = gt[sweep_idx,:,:]
    else:
        sweep_pos = pos
        sweep_gt = gt

    # print out information about focal sweep site
    print(datetime.datetime.now(),"Using SNPs at these positions:", min(sweep_pos), max(sweep_pos))
    print(datetime.datetime.now(),"Size of sweep site genotype array:")
    s,n,p = sweep_gt.shape
    print("Number of sites: " + str(s))
    print("Number of individuals: " + str(n))
    print("Ploidy level: " + str(p))

    # calculate window size in bp
    window_bp = numpy.max(sweep_pos) - numpy.min(sweep_pos)
    print(datetime.datetime.now(),"Window size of sweep site in bp:", window_bp)

    # calculate statistics
    # nucleotide diversity
    print(datetime.datetime.now(),"Calculating nucleotide diversity...")
    pi_result = numpy.sum(nucleotide_diversity(sweep_gt))/window_bp

    # watterson's theta
    print(datetime.datetime.now(),"Calculating watterson's theta...")
    thetaw_result = numpy.sum(wattersons_theta(sweep_gt))/window_bp

    # tajima's d
    print(datetime.datetime.now(),"Calcualting Tajima's D...")
    tajimasd_incomplete_result = numpy.mean(tajimasd_incomplete(sweep_gt))
    tajimasd_complete_result = tajimasd_complete(sweep_gt)

    # garud's statistics
    print(datetime.datetime.now(),"Calculating garud statistics...")
    garud_result = garud(sweep_gt)

    # gkl statistics
    print(datetime.datetime.now(),"Calculating kern's gkl statistics...")
    gkl_result = kerns_gkl(sweep_gt)

    # average zns
    print(datetime.datetime.now(),"Calculating Kelly's Zns...")
    zns_result = kellys_zns(sweep_gt)

    # kim's omega
    print(datetime.datetime.now(),"Calculating Kim's omega...")
    omega_result = kims_omega(sweep_gt)

    # messer's hscan
    print(datetime.datetime.now(),"Calculating Messer's hscan...")
    hscan_result = hscan(gt,pos,focus)

    # print results
    print(datetime.datetime.now(), "Saving results to: " + output_prefix + ".tsv")
    all_results = numpy.concatenate(([s], [pi_result], [thetaw_result], tajimasd_complete_result, [tajimasd_incomplete_result], garud_result, gkl_result, [zns_result], [omega_result], [hscan_result]))
    all_results.tofile(output_prefix + ".tsv", sep="\t")

if __name__ == '__main__':
    main()
