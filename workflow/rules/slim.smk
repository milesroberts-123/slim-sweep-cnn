def get_gene(wildcards):
	# for some reason, ID will be included in output if I use loc subsetting 
	index = int(wildcards.ID) - 1
	gene = parameters.iloc[index, 1]
	gene = str(gene)
	return gene

def get_meanS(wildcards):
        meanS = parameters.loc[parameters["ID"] == wildcards.ID, "meanS"]
        return float(meanS.iloc[0])

def get_alpha(wildcards):
        alpha = parameters.loc[parameters["ID"] == wildcards.ID, "alpha"]
        return float(alpha.iloc[0])

def get_h(wildcards):
        h = parameters.loc[parameters["ID"] == wildcards.ID, "h"]
        return float(h.iloc[0])

def get_sweepS(wildcards):
        sweepS = parameters.loc[parameters["ID"] == wildcards.ID, "sweepS"]
        return float(sweepS.iloc[0])

def get_N(wildcards):
        N = parameters.loc[parameters["ID"] == wildcards.ID, "N"]
        return float(N.iloc[0])

def get_sigmaA(wildcards):
        sigmaA = parameters.loc[parameters["ID"] == wildcards.ID, "sigmaA"]
        return float(sigmaA.iloc[0])

def get_sigmaC(wildcards):
        sigmaC = parameters.loc[parameters["ID"] == wildcards.ID, "sigmaC"]
        return float(sigmaC.iloc[0])

def get_tsigma(wildcards):
        tsigma = parameters.loc[parameters["ID"] == wildcards.ID, "tsigma"]
        return float(tsigma.iloc[0])

def get_tsweep(wildcards):
        tsweep = parameters.loc[parameters["ID"] == wildcards.ID, "tsweep"]
        return float(tsweep.iloc[0])

rule slim:
	input:
		"data/Osativa_04Sites.bed"
	output:
		finalTable="data/tables/slim_{ID}.table",
		tmpVCF = temp("slim_{ID}.vcf"),
		tmpStarts = temp("starts_{ID}.txt"),
		tmpTypes = temp("types_{ID}.txt"),
		tmpSites = temp("slim_{ID}_04sites.bed")
	log:
		"logs/slim/{ID}.log"
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
		#echo Parameter values for this simulation:
		#echo {params.gene}
		#echo {params.meanS}
		#echo {params.alpha}

		# get individual 0 and 4 sites for each gene
		#echo Getting 0 and 4-fold degenerate sites for {params.gene}...
		grep "{params.gene}" {input} > {output.tmpSites}

		# get just single vector of positions and types because this is all SLiM can read
		cut -f 2 {output.tmpSites} > {output.tmpStarts}
		cut -f 5 {output.tmpSites} > {output.tmpTypes}

		# run simulation
		slim -d ID={wildcards.ID} -d meanS={params.meanS} -d alpha={params.alpha} -d sweepS={params.sweepS} -d h={params.h} -d N={params.N} -d sigmaA={params.sigmaA} -d sigmaC={params.sigmaC} -d tsigma={params.tsigma} -d tsweep={params.tsweep} -d G=100000 scripts/simulation.slim &> {log}
		
		# convert vcf to simple table
		# remove hastag from CHROM
		# remove multiallelic sites, because most studies focus on just bialleleic SNPs
		# convert genotypes to 0s and 1s
		grep -v ^## {output.tmpVCF} | grep -v "MULTIALLELIC" | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > {output.finalTable}
		
		# remove intermediate files
		# rm slim_{wildcards.ID}.vcf
		# rm starts_{wildcards.ID}.txt
		# rm types_{wildcards.ID}.txt
		# rm slim_{wildcards.ID}_04sites.bed

		# move table into folder so things stay organized
		# mv slim_{wildcards.ID}.table {output}
		"""
