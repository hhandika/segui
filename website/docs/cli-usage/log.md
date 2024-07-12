---
sidebar_position: 17
---
# Log File

Except for the spinning emoji and the program progress messages, all the terminal output is written in the log file and saved in the current working directory. The log file also includes the time and the log status. 

By default, the SEGUL log file is named `segul.log`. SEGUL does not overwrite the log file. Each time you run the app, if the log file exists in the same working directory, it will append the log output to the same file. You can customize the log file name using the `--log` option, which is available in all features.

For example, to set the log file name for alignment concatenation:

```bash
segul align concat -d alignment_dir/ --log my_log_file
```

Below is an example of the terminal output as of v0.21.3:

```Text
=========================================================
SEGUL v0.21.3
An ultrafast and memory efficient tool for phylogenomics
---------------------------------------------------------
Input dir         : alignments/oliveros_2019_80p_trimmed/
File counts       : 4,060
Input format      : Auto
Data type         : DNA
Task              : Alignment concatenation

🌘 Finished concatenating alignments!
                                                                                                                                                                      Output
Taxa              : 221
Loci              : 4,060
Alignment length  : 2,464,926
Alignment file    : Align-Concat/Align-Concat.nex
Partition file    : Align-Concat/Align-Concat_partition.nex
Log file          : segul.log

Execution time    : 3.185152458s
```

The log file is as follows:

```Text
2024-07-12 16:09:39 -05:00 - INFO - =========================================================
2024-07-12 16:09:39 -05:00 - INFO - SEGUL v0.21.3
2024-07-12 16:09:39 -05:00 - INFO - An ultrafast and memory efficient tool for phylogenomics
2024-07-12 16:09:39 -05:00 - INFO - ---------------------------------------------------------
2024-07-12 16:09:39 -05:00 - INFO - Input dir         : alignments/oliveros_2019_80p_trimmed/
2024-07-12 16:09:39 -05:00 - INFO - File counts       : 4,060
2024-07-12 16:09:39 -05:00 - INFO - Input format      : Auto
2024-07-12 16:09:39 -05:00 - INFO - Data type         : DNA
2024-07-12 16:09:39 -05:00 - INFO - Task              : Alignment concatenation

2024-07-12 16:09:42 -05:00 - INFO - Output
2024-07-12 16:09:42 -05:00 - INFO - Taxa              : 221
2024-07-12 16:09:42 -05:00 - INFO - Loci              : 4,060
2024-07-12 16:09:42 -05:00 - INFO - Alignment length  : 2,464,926
2024-07-12 16:09:42 -05:00 - INFO - Alignment file    : Align-Concat/Align-Concat.nex
2024-07-12 16:09:42 -05:00 - INFO - Partition file    : Align-Concat/Align-Concat_partition.nex
2024-07-12 16:09:42 -05:00 - INFO - Log file          : segul.log
2024-07-12 16:09:42 -05:00 - INFO - Execution time    : 3.185152458s
```
