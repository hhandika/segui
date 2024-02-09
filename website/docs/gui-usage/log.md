---
sidebar_position: 17
---
# Log File

The log file is a text file that contains the log of the last operation. The log file is saved in the output directory with the name `segul_currentDate.log`. The log file is available in the setting menu.

The log file contains the following information:

1. The date and time of the operation.
2. The task that was performed.
3. The input files.
4. Parameters used in the operations (if any).
5. The output files.
6. Execution time.

:::info
The current input from the GUI is not written to the log file. We are working on adding this feature in the future.
:::

Example log file:

```Text
2024-02-05 19:38:51 -06:00 - INFO - Input path        : STDIN
2024-02-05 19:38:51 -06:00 - INFO - File counts       : 1
2024-02-05 19:38:51 -06:00 - INFO - Input format:     : auto

2024-02-05 19:38:51 -06:00 - INFO - Task              : Contig Summary

2024-02-05 19:38:51 -06:00 - INFO - Output
2024-02-05 19:38:51 -06:00 - INFO - Dir               : /output
2024-02-05 19:38:51 -06:00 - INFO - Execution time    : 169.633292ms
2024-02-05 23:17:22 -06:00 - INFO - Input path        : STDIN
2024-02-05 23:17:22 -06:00 - INFO - File counts       : 2
2024-02-05 23:17:22 -06:00 - INFO - Input format:     : auto

2024-02-05 23:17:22 -06:00 - INFO - Task              : Read Summary

2024-02-05 23:19:29 -06:00 - INFO - Output
2024-02-05 23:19:29 -06:00 - INFO - Dir               : /Downloads
2024-02-05 23:19:29 -06:00 - INFO - Execution time (HH:MM:SS): 00:02:06
```
