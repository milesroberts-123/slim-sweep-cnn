rule create_image:
	input:
		"data/tables/slim_{id}.table"
	output:
		image = "data/images/slim_{id}.png",
		pos = "data/positions/slim_{id}.pos"
	log:
		"logs/create_image/{id}.log"
	params:
		distMethod="manhattan",
		clustMethod="complete"
	threads: 1
	resources:
		mem_mb_per_cpu=8000,
		time=239
	conda:
		"../envs/R.yml"
	shell:
		"Rscript scripts/create-images.R {input} {output.image} {output.pos} {params.distMethod} {params.clustMethod} &> {log}"
