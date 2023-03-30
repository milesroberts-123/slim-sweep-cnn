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

rule slim:
	input:
		"data/Osativa_04Sites.bed"
	output:
		"data/tables/slim_{ID}.table"
	params:
		gene=get_gene,
		meanS=get_meanS,
		alpha=get_alpha
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
		slim -d ID={wildcards.ID} -d meanS={params.meanS} -d alpha={params.alpha} scripts/simulation.slim
		
		# convert vcf to simple table
		# remove hastag from CHROM
		# convert genotypes to 0s and 1s
		grep -v ^## slim_{wildcards.ID}.vcf | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > slim_{wildcards.ID}.table
		
		# remove intermediate files
		rm slim_{wildcards.ID}.vcf
		rm starts_{wildcards.ID}.txt
		rm types_{wildcards.ID}.txt
		rm slim_{wildcards.ID}_04sites.bed

		# move table into folder so things stay organized
		mv slim_{wildcards.ID}.table {output}
		"""
