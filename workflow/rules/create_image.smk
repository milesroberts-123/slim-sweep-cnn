rule create_image:
	input:
		table="data/tables/slim_{ID}.table",
                stats="slim_{ID}.tsv"
	output:
		image = "data/images/slim_{ID}.png",
		pos = "data/positions/slim_{ID}.pos"
	log:
		"logs/create_image/{ID}.log"
	params:
		distMethod=config["distMethod"],
		clustMethod=config["clustMethod"],
		nidv=config["nidv"],
		nloc=config["nloc"]
	threads: 1
	resources:
		mem_mb_per_cpu=8000,
		time=239
	conda:
		"../envs/R.yml"
	shell:
		"Rscript scripts/create-images.R {input.table} {output.image} {output.pos} {params.distMethod} {params.clustMethod} {params.nidv} {params.nloc} &> {log}"
