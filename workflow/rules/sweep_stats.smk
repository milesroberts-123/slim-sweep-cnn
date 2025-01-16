rule sweep_stats:
	input:
		"slim_{ID}.vcf"
	output:
		"slim_{ID}.tsv"
	threads: 1
	resources:
		mem_mb_per_cpu=8000,
		time=239
	conda: 
		"../envs/sweeps.yml"
	log: 
		"logs/sweeps_stats/{ID}.log"
	shell:
		"""
		python3 scripts/sweep_stats.py --vcf {input} --window-length 129 --focus 50001 --output-prefix slim_{wildcards.ID} &> {log}
		"""
