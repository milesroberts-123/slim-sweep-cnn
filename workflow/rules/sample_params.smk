rule sample_params:
	input:
		"../config/config.yaml"
	output:
		"../config/parameters.tsv"
	threads: 1
	resources:
		mem_mb_per_cpu=8000,
		time=239
	conda:
		"../envs/r.yaml"
	shell:
		"""
		Rscript s00_make_param_table.R {input}
		"""
