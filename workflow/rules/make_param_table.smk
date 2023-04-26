rule make_param_table:
	output:
		"data/parameters.tsv"
	conda:
		"../envs/R.yml"
	params:
		K=config["K"],
		train=config["train"],
		test=config["test"],
		val=config["val"],
		gff=config["gff"]
	log:
		"logs/make_param_table.log"
	shell:
		"Rscript scripts/make_param_table.R {params.K} {params.train} {params.test} {params.val} {params.gff} &> {log}"