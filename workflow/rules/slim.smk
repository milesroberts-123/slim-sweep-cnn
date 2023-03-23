def get_gene(wildcards):
        gene = parameters.loc[parameters["ID"] == wildcards.ID, "gene"]
        return str(gene)

def get_mean(wildcards):
        mean = parameters.loc[parameters["ID"] == wildcards.ID, "mean"]
        return str(mean)

def get_alpha(wildcards):
        alpha = parameters.loc[parameters["ID"] == wildcards.ID, "alpha"]
        return str(alpha)

rule slim:
	input:
		"data/Osativa_04Sites.bed"
	output:
		"data/tables/slim_{ID}.table"
	params:
		gene=get_gene,
		mean=get_mean,
		alpha=get_alpha
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/slim.yml"
	shell:
		"""
		# get individual 0 and 4 sites for each gene
		grep "{params.gene}" {input} > slim_{wildcards.ID}_04sites.bed

		# get just single vector of positions and types because this is all SLiM can read
		cut -f 2 slim_{wildcards.ID}_04sites.bed > starts_{wildcards.ID}.txt
		cut -f 5 slim_{wildcards.ID}_04sites.bed > types_{wildcards.ID}.txt

		# run simulation
		slim -d ID={wildcards.ID} -d mean={params.mean} -d alpha={params.alpha} scripts/simulation.slim
		
		# convert vcf to simple table
		# remove hastag from CHROM
		# convert genotypes to 0s and 1s
		grep -v ^## slim_{wildcards.ID}.vcf | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > slim_{wildcards.ID}.table
		
		# remove intermediate files
		rm slim_{wildcards.ID}.vcf
		rm starts_{wildcards.ID}.txt
		rm types_{wildcards.ID}.txt

		# move table into folder so things stay organized
		mv slim_{wildcards.ID}.table {output}
		"""
