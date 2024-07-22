rule stratified_sampling:
	input:
		"fixation_times.txt"
	output:
		"stratified_sample.tsv"
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	conda:
		"../envs/R.yml"	
	log:
		"logs/stratified_sampling.log"
	shell:
		"Rscript scripts/stratified_sampling.R {input} {output} &> {log}"
