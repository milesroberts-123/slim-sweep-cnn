rule slim:
	output:
		"data/tables/slim_{id}.table"
	shell:
		"""
		# run simulation
		slim -d Ln=1000 -d Ls=1000 -d "output='{wildcards.id}'" simulation.slim
		
		# convert vcf to simple table
		# remove hastag from CHROM
		# convert genotypes to 0s and 1s
		grep -v ^## slim_{wildcards.id}.vcf | cut -f1,2,8,10- | sed 's/^#//g' | sed 's/0|0/0/g' | sed 's/1|0/0.5/g' | sed 's/0|1/0.5/g' | sed 's/1|1/1/g' > slim_{wildcards.id}.table
		
		# remove intermediate VCF file
		rm slim_{wildcards.id}.vcf

		# move table into folder so things stay organized
		mv slim_{wildcards.id}.table {output}
		"""
