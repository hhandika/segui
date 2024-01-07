---
sidebar_position: 13
---

# Sequence Conversion

Segul can convert a single file, multiple file in the same directory, or multiple files in multiple directory.

## Converting a single file

To convert a single file, use the `--input` or `-i`.

```Bash
segul convert --input [a-path-to-file] --output-format [sequence-format]
```

`segul` should be able to infer the input file format based on the extension of your file. If your file extension is uncommon (for example .aln instead of .fas), specify the `--input-format`:

```Bash
segul convert --input [a-path-to-file] --input-format [sequence-format] --output-format [sequence-format]
```

For example, here we will convert a nexus file containing DNA sequence named `loci.nexus` to fasta format:

```Bash
segul convert --input alignments/loci.nexus -output-format fasta
```

You can ignore specifying the output format if you would like the output files in nexus format. For example, we will convert loci.fasta to nexus format:

```Bash
segul convert --input alignments/loci.fasta
```

Some `segul` arguments available in short format, notice the uppercase 'F' for the output format:

```Bash
segul convert -i alignments/loci.nexus -f nexus  -F fasta --datatype aa -o alignment-fasta
```

> Note that, when converting alignments, `segul` will only change the file extension and will maintain the original file names for the output files. This behavior is the same for a single or multiple file format conversion. This way it gives the app the flexibility to convert many files in a single command.

## Batch converting sequence files in a directory

We have to option to provide the input files to the progam. First, using the `--dir` or `-d` input. For a directory input, it is required to specify the `--input-format`:

```Bash
segul convert --dir [path-to-your-repository] --input-format [sequence-format] --output [your-output-dir-name] --output-format [sequence-format]
```

In short format:

```Bash
segul convert -d [path-to-your-repository] -f [sequence-format] -o [your-output-dir-name]
```

For example, suppose we want to convert all the nexus files in the directory below to fasta formats and name the output directory `alignments-fas`:

```Bash
alignments/
├── locus_1.nexus
├── locus_2.nexus
└── locus_3.nexus
```

The command will be:

```Bash
segul convert -d alignments/ -f nexus -F fasta -o alignments-fas
```

We can also input wildcard (\*) using the `--input` or `-i` option to achieve the same results:

```Bash
segul convert -i alignments/*.nexus -f nexus -F fasta -o alignments-fas
```

The outputs will be:

```Bash
alignments-fas/
├── locus_1.fas
├── locus_2.fas
└── locus_3.fas
```

## Batch converting multiple files in multiple directories

To convert multiple files in multiple directories, we will inputs multiple paths with wildcards and use the `--input` or `-i` option:

```Bash
segul convert -i [wildcard-1] [wildcard-2] [wildcard-3] -o [your-output-dir-name]
```

For example:

```Bash
segul convert -i alignments-1/*.nexus alignments-2/*.nexus alignments-3/*.nexus -F fasta -o alignments-fas
```

You can also convert multiple files in different formats. Because `segul` maintain the original file name for the output, the filename for each input file should be unique regardless of the extension. Otherwise, `segul` will failed to write the output.

For example:

```Bash
segul convert -i alignments-1/*.nexus alignments-2/*.fasta alignments-3/*.fasta -F phylip -o alignments-phylip
```

Depending on the size of your RAM, you can provide as many input paths as possible. The output files, however, will all be saved in the same directory.

## Converting amino acid sequences

By default, `segul` datatype is set for converting DNA sequence. If your file contains amino acid sequence, use the argument `--datatype aa`. For example:

```Bash
segul convert --input alignments/loci.nexus -output-format fasta --datatype aa
```

## Specifying the output directory

By default segul will write the result in a directory called `SEGUL-convert`. If you would like to specify the output directory, use the `--output` argument. For example, here we will specify the output directory to `alignment-fasta`.

```Bash
segul convert --input alignments/loci -output-format fasta --datatype aa --output alignment-fasta
```

## Sorting the output sequences

By default, `segul` maintain the original order of the sequences in the input file(s). Using the `--sort` flag, you can sort the sequences in alphabetical order based on their IDs:

```Bash
segul convert --input alignments/loci -output-format fasta --datatype aa --output alignment-fasta --sort
```

## Terminal output for file conversion

For sequence format conversion, `segul` terminal output consists of three parts. The first part is the input information. It contains information from your command input. The second part is the spinner. It will show you the state of the program as it is processing the file. The third part is the output information. It shows the information of the output directory relative to the current working directory, the output format, and the log file path. With the exception of the spinner (include the spinning emoji and its text), all the terminal output is written into the log file.

Below is an example of terminal output when you use the argument `--input` or `-i` to input the files:

```Text
=========================================================
SEGUL v0.11.1
An alignment tool for phylogenomics
---------------------------------------------------------
Input             : STDIN
File counts       : 1
Input format      : Auto
Data type         : DNA
Task              : Sequence format conversion

🌘 Finished converting sequence format!

Output
Output dir        : SEGUL-Convert
Output format     : Nexus Sequential
Log file          : segul.log

Execution time    : 9.7194ms
```

For `--dir` or `-d` input, notice the input file path is printed in the terminal:

```Text
=========================================================
SEGUL v0.11.1
An alignment tool for phylogenomics
---------------------------------------------------------
Input dir         : align-fas/
File counts       : 1
Input format      : Fasta
Data type         : DNA
Task              : Sequence format conversion

🌘 Finished converting sequence format!

Output
Output dir        : SEGUL-Convert
Output format     : Nexus Sequential
Log file          : segul.log

Execution time    : 13.5741ms
```
