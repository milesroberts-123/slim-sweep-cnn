rule fit_cnn:
	input:
		images=expand("data/images/slim_{ID}.png", ID=parameters.index.get_level_values("ID")),
		#hyperparams = "../config/hyperparameters.tsv"
	output:
		"best_cnn.h5"
	conda:
		"../envs/cnn.yml"
	threads: 1
	resources:
		mem_mb_per_cpu=32000
	shell:
		"python3 scripts/mycnn.py"
