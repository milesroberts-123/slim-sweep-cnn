rule sweep_stats:
	input:
		"slim_{ID}.vcf"
	output:
		"slim_{ID}.tsv"
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda: "../envs/sweeps.yml"
	shell:
		"""
		python3 scripts/sweep_stats.py --vcf {input} --window-length 129 --focus 50000 --output-prefix slim_{wildcards.ID}
		"""
