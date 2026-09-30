rule extract_log_data:
    input:
        expand("images/{ID}.png", ID = parameters["ID"]),
    output:
        "fixation_times.txt",
        "sweep_ages.txt",
    shell:
        """
        echo Extracting fixation times from log files...
        grep "SCALED FIXATION TIME:" logs/slim/* | sed 's|.*log:||g' | sed 's|:.*:||g' > fixation_times.txt

        echo Extracting sweep ages from log files...
        grep "GENERATIONS POST-FIXATION" logs/slim/* | sed 's/.*.log://g' | sed 's/:.*SCALED:/ /g' > sweep_ages.txt
        """
