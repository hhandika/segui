---
sidebar_position: 17
---
# Log File

With the exception of the spinning emoji and the program progress messages, all the terminal output is written to `segul.log` file saved in the current working directory. In the log output, however, it is also include the time and the log status. For example, our terminal output is as follow:

```Text
=========================================================
SEGUL v0.12.0
An alignment tool for phylogenomics
---------------------------------------------------------
Input dir         : oliveros_et_al2019/
File counts       : 4,060
Input format      : Nexus
Data type         : DNA
Task              : Sequence format conversion

🌘 Finished converting sequence format!

Output
Output dir        : oliveros_et_al_2019_fasta
Output format     : Fasta Sequential
Log file          : segul.log

Execution time    : 1.762814458s
```

The log file is as follow:

```Text
2022-02-14 17:41:02 -06:00 - INFO - =========================================================
2022-02-14 17:41:02 -06:00 - INFO - SEGUL v0.12.0
2022-02-14 17:41:02 -06:00 - INFO - An alignment tool for phylogenomics
2022-02-14 17:41:02 -06:00 - INFO - ---------------------------------------------------------
2022-02-14 17:41:02 -06:00 - INFO - Input dir         : oliveros_et_al2019/
2022-02-14 17:41:02 -06:00 - INFO - File counts       : 4,060
2022-02-14 17:41:02 -06:00 - INFO - Input format      : Nexus
2022-02-14 17:41:02 -06:00 - INFO - Data type         : DNA
2022-02-14 17:41:02 -06:00 - INFO - Task              : Sequence format conversion

2022-02-14 17:41:04 -06:00 - INFO - Output
2022-02-14 17:41:04 -06:00 - INFO - Output dir        : oliveros_et_al_2019_fasta
2022-02-14 17:41:04 -06:00 - INFO - Output format     : Fasta Sequential
2022-02-14 17:41:04 -06:00 - INFO - Log file          : segul.log
2022-02-14 17:41:04 -06:00 - INFO - Execution time    : 1.762814458s
```

`segul` does not overwrite the log file. Each time you run the app, if the log file exists in the same working directory, it will append the log output into the same file. If you would like to keep a different log file for a different task, you either move the file to a different folder or rename it.
