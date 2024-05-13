rule degenotate:
	input:
		genome="../config/genome/Osativa_323_v7.0.fa",
		annot="../config/genome/Osativa_323_v7.0.gene.gff3"
	output:
		"data/Osativa_04Sites.bed"
	log:
		"logs/degenotate.log"
	params:
		outputFolder="data/degenotateOutput/"
	threads: 1
	resources:
		mem_mb_per_cpu=16000
	conda:
		"../envs/degenotate.yml"
	shell:
		"""
		# before running degenotate, check that correct python version is installed
		# ml -*
		echo $CONDA_PREFIX
		which python
		python --version

		# run degenotate, remove any extra information in fasta header after initial key
		# if previous run failed, overwrite that failed run
		# if conda is enabled, use fastp conda env
		# if conda is disabled, check scripts for fastp binary
		$CONDA_PREFIX/bin/python $CONDA_PREFIX/bin/degenotate.py --overwrite -d " " -a {input.annot} -g {input.genome} -o {params.outputFolder} &> {log}

		# subset out four-fold degenerate sites
		awk '(($5 == 4 || $5 == 0))' {params.outputFolder}/degeneracy-all-sites.bed > {output}
		"""
