def get_gene(wildcards):
	# for some reason, ID will be included in output if I use loc subsetting 
	index = int(wildcards.ID) - 1
	gene = parameters.iloc[index, 1]
	gene = str(gene)
	return gene

def get_meanS(wildcards):
        meanS = parameters.loc[parameters["ID"] == wildcards.ID, "meanS"]
        return float(meanS)

def get_alpha(wildcards):
        alpha = parameters.loc[parameters["ID"] == wildcards.ID, "alpha"]
        return float(alpha)

def get_h(wildcards):
        h = parameters.loc[parameters["ID"] == wildcards.ID, "h"]
        return float(h)

def get_sweepS(wildcards):
        sweepS = parameters.loc[parameters["ID"] == wildcards.ID, "sweepS"]
        return float(sweepS)

def get_N(wildcards):
        N = parameters.loc[parameters["ID"] == wildcards.ID, "N"]
        return float(N)

def get_sigmaA(wildcards):
        sigmaA = parameters.loc[parameters["ID"] == wildcards.ID, "sigmaA"]
        return float(sigmaA)

def get_sigmaC(wildcards):
        sigmaC = parameters.loc[parameters["ID"] == wildcards.ID, "sigmaC"]
        return float(sigmaC)

def get_tsigma(wildcards):
        tsigma = parameters.loc[parameters["ID"] == wildcards.ID, "tsigma"]
        return float(tsigma)

def get_tsweep(wildcards):
        tsweep = parameters.loc[parameters["ID"] == wildcards.ID, "tsweep"]
        return float(tsweep)

rule slim:
	input:
		"data/Osativa_04Sites.bed"
	output:
		"data/tables/slim_{ID}.table"
	params:
		gene=get_gene,
		meanS=get_meanS,
		alpha=get_alpha,
		sweepS=get_sweepS,
		h=get_h,
		N=get_N,
		sigmaA=get_sigmaA,
		sigmaC=get_sigmaC,
		tsigma=get_tsigma,
		tsweep=get_tsweep
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/slim.yml"
	shell:
		"""
		echo Parameter values for this simulation:
		echo {params.gene}
		echo {params.meanS}
		echo {params.alpha}

		# get individual 0 and 4 sites for each gene
		echo Getting 0 and 4-fold degenerate sites for {params.gene}...
		grep "{params.gene}" {input} > slim_{wildcards.ID}_04sites.bed

		# get just single vector of positions and types because this is all SLiM can read
		cut -f 2 slim_{wildcards.ID}_04sites.bed > starts_{wildcards.ID}.txt
		cut -f 5 slim_{wildcards.ID}_04sites.bed > types_{wildcards.ID}.txt

		# run simulation
		slim -d ID={wildcards.ID} -d meanS={params.meanS} -d alpha={params.alpha} -d sweepS={params.sweepS} -d h={params.h} -d N={params.N} -d sigmaA={params.sigmaA} -d sigmaC={params.sigmaC} -d tsigma={params.tsigma} -d tsweep={params.tsweep} -d G=25000 scripts/simulation.slim
		
		# convert vcf to simple table
		# remove hastag from CHROM
		# remove multiallelic sites, because most studies focus on just bialleleic SNPs
		# convert genotypes to 0s and 1s
		grep -v ^## slim_{wildcards.ID}.vcf | grep -v "MULTIALLELIC" | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > slim_{wildcards.ID}.table
		
		# remove intermediate files
		rm slim_{wildcards.ID}.vcf
		rm starts_{wildcards.ID}.txt
		rm types_{wildcards.ID}.txt
		rm slim_{wildcards.ID}_04sites.bed

		# move table into folder so things stay organized
		mv slim_{wildcards.ID}.table {output}
		"""
