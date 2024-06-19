rule extract_log_data:
	input:
		images=["data/images/slim_{ID}.png".format(ID=ID) for ID in range(1,config["K"] + 1)],
	output:
		"harmonic_mean_ne.txt",
		"fixation_times.txt"
	threads: 1
	resources:
		mem_mb_per_cpu=8000
	shell:
		"""
		echo Extracting Ne from log files...
		grep "HARMONIC MEAN Ne" logs/slim/* | sed 's|.*log:||g' | sed 's|:.*:||g' > harmonic_mean_ne.txt

		echo Extracting fixation times from log files...
		grep "FIXATION TIME:" logs/slim/* | sed 's|.*log:||g' | sed 's|:.*:||g' > fixation_times.txt
		"""
