---
sidebar_position: 1
---

# Overview

The goals of `segul` are to be easy to use for non-tech-savvy users and provides powerful options for experienced users. Some common arguments have short options. Some of them also have default values when they are possible and safe to have. This way, we will save time typing the commands.

Several considerations before using `segul`:

1. `segul` has two input options. Each have its pros and cons. See [command options](./command_options) for details.
2. By default, `segul` datatype is DNA. If your input file is amino acid sequences, you are required to use `--datatype aa` option.
3. Except for computing alignment statistics, you can pass `--datatype ignore`. This will speed up the processing time up to 40 percent. Use this option carefully. It is safe for DNA sequences. It is only safe for amino acid sequences when the output is not in nexus format. Learn more in the [command options](./command_options#data-types).
4. The command examples below is for Unix-like OS, such as Linux, Windows Subsystem for Linux, and MacOS. If you are running `segul` natively on Windows, the program name will be `segul.exe`.
5. Most functions in `segul` has default output directories. Follow the specifying output directory instruction below if you would like to use a custom name for output directories.
