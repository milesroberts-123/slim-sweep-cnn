rule create_image:
	input:
		"data/tables/slim_{id}.table"
	output:
		"data/images/slim_{id}.jpg"
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/R.yml"
	shell:
		"Rscript scripts/create-images.R {input} {output}"
