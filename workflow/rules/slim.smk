rule slim:
    group: "simulation"
    output:
        temp("slim_results/{ID}.trees"),
    params:
        failmax=config["failmax"],
        #mu=lookup(query="ID == '{ID}'", within=parameters, cols="mu"),
        R=lookup(query="ID == '{ID}'", within=parameters, cols="R"),
        N=lookup(query="ID == '{ID}'", within=parameters, cols="N"),
        L=config["L"],
        #L=lookup(query="ID == '{ID}'", within=parameters, cols="L"),
        sweepS=lookup(query="ID == '{ID}'", within=parameters, cols="sweepS"),
        h=lookup(query="ID == '{ID}'", within=parameters, cols="h"),
        Q=lookup(query="ID == '{ID}'", within=parameters, cols="Q"),
        ta=lookup(query="ID == '{ID}'", within=parameters, cols="ta"),
        kappa=lookup(query="ID == '{ID}'", within=parameters, cols="kappa"),
        r=lookup(query="ID == '{ID}'", within=parameters, cols="r"),
        K=lookup(query="ID == '{ID}'", within=parameters, cols="K"),
        custom_demography=lookup(query="ID == '{ID}'", within=parameters, cols="custom_demography"),
    conda:
        "../envs/msprime.yaml"
    shell:
        """
        # run simulation
        slim -d ID={wildcards.ID} -d failmax={params.failmax} -d L={params.L} -d demog={params.custom_demography} -d Q={params.Q} -d sweepS={params.sweepS} -d h={params.h} -d N={params.N} -d mu=0 -d R={params.R} -d tau={params.ta} -d kappa={params.kappa} -d r={params.r} -d K={params.K} scripts/simulation_custom_demography_any_age.slim
        """

rule msprime:
    group: "simulation"
    input:
        "slim_results/{ID}.trees"
    output:
        temp("msprime_results/{ID}.vcf")
    conda:
        "../envs/msprime.yaml"
    params:
        mu=lookup(query="ID == '{ID}'", within=parameters, cols="mu"),
        R=lookup(query="ID == '{ID}'", within=parameters, cols="R"),
        N=lookup(query="ID == '{ID}'", within=parameters, cols="N"),
        L=config["L"],
        #L=lookup(query="ID == '{ID}'", within=parameters, cols="L"),
        #n=lookup(query="ID == '{ID}'", within=parameters, cols="n"),
        n=500
    shell:
        """
        python scripts/burnin.py --mu {params.mu} -n {params.n} -N {params.N} -L {params.L} -R {params.R} --ID {wildcards.ID}
        """

rule random_subset_individuals:
    group: "simulation"
    input: "msprime_results/{ID}.vcf"
    output: 
        vcf=temp("random_subset/{ID}_{n}.vcf"),
        subset=temp("random_subset/{ID}_{n}.txt")
    conda: "../envs/bcftools.yaml"
    shell:
        """
        bcftools query -l {input} | shuf | head -n {wildcards.n} > {output.subset}
        bcftools view -S {output.subset} {input} > {output.vcf}
        """

rule pi_windows:
    group: "simulation"
    input: "random_subset/{ID}_{n}.vcf"
    output: 
        "vcftools_results/{ID}_{n}.windowed.pi",
    conda: 
        "../envs/vcftools.yaml"
    params:
        window=config["window"],
        step=config["step"],
        prefix="vcftools_results/{ID}_{n}"
    shell:
        """
        vcftools --vcf {input} --window-pi {params.window} --window-pi-step {params.step} --out {params.prefix}
        """

rule vcf_to_table:
    group: "plotting"
    input:
        "random_subset/{ID}_{n}.vcf"
    output:
        temp("tables/{ID}_{n}.txt")
    shell:
        """
        # convert vcf to simple table
        # remove hastag from CHROM
        # remove multiallelic sites, because most studies focus on just bialleleic SNPs
        # convert genotypes to 0s and 1s
        grep -v ^## {input} | grep -v "MULTIALLELIC" | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > {output}
        """

rule create_image:
    group: "plotting"
    input:
        table="tables/{ID}_{n}.txt",
    output:
        image="images/{ID}_{n}_{m}.png",
        pos="positions/{ID}_{n}_{m}.pos",
    params:
        distMethod=config["distMethod"],
        clustMethod=config["clustMethod"],
        #nidv=lookup(query="ID == '{ID}'", within=parameters, cols="n"),
        #nloc=lookup(query="ID == '{ID}'", within=parameters, cols="m"),
    conda:
        "../envs/R.yml"
    shell:
        "Rscript scripts/create-images.R {input.table} {output.image} {output.pos} {params.distMethod} {params.clustMethod} {wildcards.n} {wildcards.m}"

def get_focus(wildcards):
    return int(config["L"]/2)

rule sweep_stats:
    group: "plotting"
    input:
        "random_subset/{ID}_{n}.vcf",
    output:
        "sweep_stats/{ID}_{n}_{m}.tsv",
    params:
        prefix="sweep_stats/{ID}_{n}_{m}",
        #nloc=lookup(query="ID == '{ID}'", within=parameters, cols="m"),
        focus=get_focus
    conda:
        "../envs/sweeps.yml"
    shell:
        """
        python3 scripts/sweep_stats.py --vcf {input} --window-length {wildcards.m} --focus {params.focus} --output-prefix {params.prefix}
        """
