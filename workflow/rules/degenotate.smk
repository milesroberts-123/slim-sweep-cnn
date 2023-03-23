rule degenotate:
	input:
		genome="data/genome/Osativa_323_v7.0.fa",
		annot="data/genome/Osativa_323_v7.0.gene.gff3"
	output:
		"data/Osativa_04Sites.bed"
	params:
		outputFolder="data/degenotateOutput/"
	threads: 1
	resources:
		mem_mb_per_cpu=16000
	conda:
		"../envs/degenotate.yml"
	shell:
		"""
		# remove lengthy titles so fasta headers match gff exactly
		# replace ambiguous bases with N
		#scripts/seqkit replace -s -p [^ATGC] -r N {input.genome} | scripts/seqkit replace -p " .*" -r "" > data/genome_shortTitles_noAmbig.fa
 
		# before running degenotate, check that correct python version is installed
		# ml -*
		echo $CONDA_PREFIX
		which python
		python --version

		# run degenotate, remove any extra information in fasta header after initial key
		# if previous run failed, overwrite that failed run
		# if conda is enabled, use fastp conda env
                # if conda is disabled, check scripts for fastp binary
		$CONDA_PREFIX/bin/python $CONDA_PREFIX/bin/degenotate.py --overwrite -d " " -a {input.annot} -g {input.genome} -o {params.outputFolder}

		# subset out four-fold degenerate sites
		awk '(($5 == 4 || $5 == 0))' {params.outputFolder}/degeneracy-all-sites.bed > {output}
		"""
