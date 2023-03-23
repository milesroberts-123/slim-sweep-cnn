rule create_image:
	input:
		"data/tables/slim_{id}.table"
	output:
		"data/images/slim_{id}.jpg"
	shell:
		"scripts/create-images.R {input} {output}"
