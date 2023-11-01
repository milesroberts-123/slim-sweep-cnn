def get_h(wildcards):
        h = parameters.loc[parameters["ID"] == wildcards.ID, "h"]
        return float(h.iloc[0])

def get_sweepS(wildcards):
        sweepS = parameters.loc[parameters["ID"] == wildcards.ID, "sweepS"]
        return float(sweepS.iloc[0])

def get_sigma(wildcards):
        sigma = parameters.loc[parameters["ID"] == wildcards.ID, "sigma"]
        return float(sigma.iloc[0])

def get_N(wildcards):
        N = parameters.loc[parameters["ID"] == wildcards.ID, "N"]
        return float(N.iloc[0])

def get_mu(wildcards):
        mu = parameters.loc[parameters["ID"] == wildcards.ID, "mu"]
        return float(mu.iloc[0])

def get_R(wildcards):
        mu = parameters.loc[parameters["ID"] == wildcards.ID, "R"]
        return float(mu.iloc[0])

rule slim:
	input:
		"../config/parameters.tsv"
	output:
		finalTable="data/tables/slim_{ID}.table",
		tmpVCF = temp("slim_{ID}.vcf"),
		fixTime = "data/fix_times/fix_time_{ID}.txt"
	log:
		"logs/slim/{ID}.log"
	params:
		sweepS=get_sweepS,
		sigma=get_sigma,
		h=get_h,
		N=get_N,
		mu=get_mu,
		R=get_R
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/slim.yml"
	shell:
		"""
		# run simulation
		slim -d ID={wildcards.ID} -d sweepS={params.sweepS} -d sigma={params.sigma} -d h={params.h} -d N={params.N} -d mu={params.mu} -d R={params.R} scripts/simulation.slim &> {log}

		# move fix time to it's own directory
		mkdir -p data/fix_times
		mv fix_time_{wildcards.ID}.txt data/fix_times/

		# convert vcf to simple table
		# remove hastag from CHROM
		# remove multiallelic sites, because most studies focus on just bialleleic SNPs
		# convert genotypes to 0s and 1s
		grep -v ^## {output.tmpVCF} | grep -v "MULTIALLELIC" | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > {output.finalTable}
		"""
