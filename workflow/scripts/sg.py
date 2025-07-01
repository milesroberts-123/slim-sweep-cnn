print("Loading packages...")
import sgkit as sg
import click
import xarray as xr
import numpy as np

print("Defining functions...")
def wattersons_theta(ds):
    """
    Wattersons theta
    """
    # sample size = number of chromosomes
    # assume no missing data for now
    num_chrom = ds.variant_allele_total.values[0]
    #print(f"Number of chromosomes: {num_chrom}")
    
    # number of segregating sites per window
    num_seg_sites_per_win = ds.window_stop.values - ds.window_start.values
    
    # sample size correction factor
    a_n = np.sum(1/np.arange(1, num_chrom))
    #print(f"n-1th harmonic number: {a_n}")
    
    # add wattersons theta to dataset
    #ds.assign(Wattersons_Theta = num_seg_sites_per_win/a_sub_n)
    ds["Wattersons_Theta"] = num_seg_sites_per_win/a_n
    
    return(ds)
    
def theta_l(ds):
    """
    Zeng's theta L, used as part of calculating normalized Fay and Wu's H
    Reference: https://doi.org/10.1534/genetics.106.061432
    """
    num_chrom = ds.variant_allele_total.values[0]
    #print(f"Number of chromosomes: {num_chrom}")
    
    mut_allele_counts = ds.variant_allele_count.values[:,1]
    
    # empty list to store results
    result = []
    
    # loop over each window
    for win_start, win_stop in zip(ds.window_start.values, ds.window_stop.values):
    
        # mutant allele counts per window
        mut_allele_counts_win = mut_allele_counts[win_start:win_stop]
        
        unique, counts = np.unique(mut_allele_counts_win, return_counts=True)
        uniq_allele_counts = dict(zip(unique, counts))

        #print(uniq_allele_counts)
        #print(sum(uniq_allele_counts.values()))
        
        sum_ie_i = 0
        for i in range(1, num_chrom):
            # let e_i be the number of segregating sites where the mutant type occurs i times in the sample
            if i in uniq_allele_counts:
                e_i = uniq_allele_counts[i]
            else:
                e_i = 0
            
            # weight each e_i by i
            sum_ie_i += i*e_i
        
        # calculate final theta_l for window
        theta_l = (1/(num_chrom-1))*sum_ie_i
        
        # keep track of all windows
        result.append(theta_l)
        
    # add theta L to dataset
    ds["Theta_L"] = np.array(result)
    
    return(ds)
    

def fay_wu_h(ds):
    """
    Calculate normalized Fay and Wu's H
    Reference: https://doi.org/10.1093/genetics/155.3.1405
    Reference: https://doi.org/10.1534/genetics.106.061432
    """
    # get diversity values per window
    n = ds.variant_allele_total.values[0]
    #print(n)
    
    s = ds.window_stop.values - ds.window_start.values
    #print(s)
    
    theta_pi = ds.stat_diversity.values.flatten()
    #print(theta_pi)
    
    theta_l = ds.Theta_L.values
    #print(theta_l)
    
    theta = ds.Wattersons_Theta.values
    #print(theta)
    
    a_n = np.sum(1/np.arange(1, n))
    
    b_n = np.sum( 1/(np.arange(1, n)**2) )
    
    b_n_plus_1 = np.sum( 1/(np.arange(1, n+1)**2) )
    
    theta_2 = s*(s-1)/(a_n**2+b_n)
    
    # calculate variance per window
    a = (n-2)/(6*(n-1)) * theta
    
    b = ( 18*(n**2)*(3*n+2)*b_n_plus_1 - (88*(n**3)+9*(n**2)-13*n+6) ) * theta_2
    
    c = 9*n*((n-1)**2) 
    
    var_theta_pi_minus_theta_l = a + b/c
    
    # final calculation
    ds["Fay_Wu_H_Normalized"] = (theta_pi - theta_l)/np.sqrt(var_theta_pi_minus_theta_l)
    #print(ds.Fay_Wu_H_Normalized.values)
    
    return(ds)
    
def zengs_e(ds):
    """
    Reference: https://doi.org/10.1534/genetics.106.061432
    """
    # get diversity values per window
    n = ds.variant_allele_total.values[0]
    #print(n)
    
    s = ds.window_stop.values - ds.window_start.values
    #print(s)
    
    theta_pi = ds.stat_diversity.values.flatten()
    #print(theta_pi)
    
    theta_l = ds.Theta_L.values
    #print(theta_l)
    
    theta = ds.Wattersons_Theta.values
    #print(theta)
    
    a_n = np.sum(1/np.arange(1, n))
    
    b_n = np.sum( 1/(np.arange(1, n)**2) )
    
    theta_2 = s*(s-1)/(a_n**2+b_n)
    
    # calculate variance per window
    a = ( n/(2*(n-1)) - (1/a_n) )*theta
    
    b = ( b_n/(a_n**2) + 2*( (n/(n-1))**2 )*b_n - (2*(n*b_n - n + 1))/((n-1)*a_n) - (3*n + 1)/(n-1) )*theta_2
    
    var_theta_l_minus_theta_w = a + b
    
    # final calculation
    ds["Zengs_E"] = (theta_l - theta)/np.sqrt(var_theta_l_minus_theta_w)

    return(ds)
    
# kelly's zns
def kellys_zns(ld_by_win, starts, stops):

    results = []

    for start, stop in zip(starts, stops):

        ld_sub = ld_by_win.loc[(ld_by_win["i"] >= start) & (ld_by_win["i"] < stop) & (ld_by_win["j"] >= start) & (ld_by_win["j"] < stop)]

        ld_sub = ld_sub.compute()

        result = ld_sub.loc[:, 'value'].mean()
        
        results.append(result)

    return(np.array(results))

# kim's omega
# def kims_omega(ld_by_win, starts, stops):

# messer's hscan
# def hscan():

# define click options
@click.command(context_settings={'show_default': True})
@click.option("-v", "--vcz-file", default=None, help="Path to VCZ file", multiple=False)
@click.option("-t", "--test", is_flag=True, help="Simulate a testing dataset")
@click.option("-w","--window-length", default=129, help="number of snps to include in window", type = click.INT)
@click.option("-s","--skip-length", default=1, help="number of snps to skip between windows", type = click.INT)
@click.option("-o", "--output", default="sweeps.txt", help="Prefix for output files")

# Main function that combines all other functions
def main(vcz_file, test, window_length, skip_length, output):

    if test:
        print("Generating test dataset...")
        ds = sg.simulate_genotype_call_dataset(n_variant=150, n_sample=25, n_contig=1)
    else:
        print("Loading vcz...")
        ds = sg.load_dataset(vcz_file)

    # define single cohort for all samples
    ds["sample_cohort"] = xr.DataArray(np.full(ds.dims['samples'], 0), dims="samples")

    # create windows
    print("Creating windows...")
    ds = sg.window_by_variant(ds, size=window_length, step=skip_length)
    #print(ds)
    #print(ds.window_start.values)
    #print(ds.window_stop.values)
    
    # get window bounds in terms of bp instead of variant index
    ds["window_pos_start"] = ds.variant_position[ds.window_start.values]
    ds["window_pos_stop"] = ds.variant_position[(ds.window_stop.values - 1)]

    # The diversity statistic is now computed for every window
    print("Calculate variant stats...")
    ds = sg.variant_stats(ds)
    #print("Allele counts per site:")
    #print(ds.variant_allele_count.values)
    #print("Number chromosomes per site:")
    #print(ds.variant_allele_total.values)
    
    print("Calculate sample stats...")
    ds = sg.sample_stats(ds)
    #print(ds.sample_n_called.values)

    print("Calculating diversity...")
    ds = sg.diversity(ds)
    #print(ds.stat_diversity.values)

    print("Calculating Tajima's D...")
    ds = sg.Tajimas_D(ds)

    print("Calculating Garud's H statistics...")
    ds = sg.Garud_H(ds)
    
    print("Calculating Watterson's theta...")
    ds = wattersons_theta(ds)
    #print(ds.Wattersons_Theta.values)
    
    print("Calculating Theta L...")
    ds = theta_l(ds)
    #print(ds.Theta_L.values)
    
    print("Calculating Normalized Fay and Wu's H...")
    ds = fay_wu_h(ds)
    
    print("Calculating Zeng's E...")
    ds = zengs_e(ds)

    #print(ds.data_vars)
    #print(ds.variant_allele_count.values)
    #print(ds.variant_allele_count.values[:, 1])
    #print(sg.count_call_alleles(ds)["call_allele_count"].values)
    #print(sg.count_call_alleles(ds)["call_allele_count"].values[:, :, 1])
    #ds["call_dosage"] = (["variants", "samples"], sg.count_call_alleles(ds, merge = False)["call_allele_count"].values[:, :, 1])
    # Calculate dosage
    print("Calculating dosage...")
    ds["call_dosage"] = ds["call_genotype"].sum(dim="ploidy")
    
    print("Calculating LD...")
    ld_by_win = sg.ld_matrix(ds, dosage = 'call_dosage', threshold = 0.001)
    #print(ld_by_win)
    #print(ld_by_win.compute())
    #print(ld_by_win.loc[(ld_by_win["i"] > 1) & (ld_by_win["i"] < 10) & (ld_by_win["j"] > 1) & (ld_by_win["j"] < 10)])

    print("Averaging LD by window...")
    ds["kellys_zns"] = kellys_zns(ld_by_win, ds.window_start.values, ds.window_stop.values)
    
    print("Column binding statistics...")
    final_table = np.column_stack((ds.window_contig.values,ds.window_start.values, ds.window_stop.values, ds.window_pos_start.values, ds.window_pos_stop.values, ds.stat_diversity.values, ds.Wattersons_Theta.values, ds.Theta_L.values, ds.stat_Tajimas_D.values, ds.Fay_Wu_H_Normalized.values, ds.Zengs_E.values, ds.stat_Garud_h1.values, ds.stat_Garud_h12.values, ds.stat_Garud_h123.values, ds.stat_Garud_h2_h1.values, ds.kellys_zns.values))
    
    print("Saving table...")
    np.savetxt(output, final_table, delimiter='\t', header="Contig\tVar_Start\tVar_Stop\tPos_Start\tPos_Stop\tTheta_Pi\tTheta_W\tTheta_L\tTajimas_D\tFay_Wus_H\tZengs_E\tGarud_H1\tGarud_H12\tGarud_H123\tGarud_H2_H1\tKellys_Zns", comments="")
    print("Done! :D")

if __name__ == '__main__':
    main()
