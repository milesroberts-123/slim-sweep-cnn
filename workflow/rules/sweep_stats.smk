rule sweep_stats:
	input:
		"slim_{ID}.vcf"
	output:
		"data/sweep_stats/{ID}.tsv"
	threads: 1
	resources:
		mem_mb_per_cpu=8000,
		time=239
	params:
		prefix="data/sweep_stats/{ID}",
		nloc=config["nloc"]
	conda: 
		"../envs/sweeps.yml"
	log: 
		"logs/sweeps_stats/{ID}.log"
	shell:
		"""
		python3 scripts/sweep_stats.py --vcf {input} --window-length {params.nloc} --focus 50001 --output-prefix {params.prefix} &> {log}
		"""
