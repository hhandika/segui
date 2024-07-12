---
sidebar_position: 1
---

# Overview

The goals of SEGUL CLI are to be easy to use for beginners and to provide powerful options for experienced users. Some common arguments have short options. Some of them also have default values when they are possible and safe to have. This way, we will save time typing the commands.

Several considerations before using `segul`:

1. SEGUL CLI has two input options, each with pros and cons. See [command options](./command_options) for details.
2. The SEGUL CLI datatype is DNA by default. If your input file contains amino acid sequences, use the `-- datatype aa` option.
3. Except for computing alignment statistics, you can pass `--datatype ignore`. This will speed up the processing time by up to 40 percent. Use this option carefully. It is safe for DNA sequences. It is only safe for amino acid sequences when the output is not in nexus format. You can learn more in the [command options](./command_options#data-types).
4. The command examples below are for Unix-like OS, such as Linux, Windows Subsystem for Linux, and MacOS. If you run `segul` natively on Windows, the program name will be `segul.exe`.
5. SEGUL CLI has default output directories for each task. You can specify the input directory by using the `--output` or `-o` argument.
6. For some tasks, such as alignment concatenation and summary statistics, you can use the `--prefix` argument to specify the prefix of the output files.
