---
sidebar_position: 8
---

# Alignment Summary

SEGUL generates different summary statistics for DNA and amino acid sequences. By default, the data type is set to the DNA sequence. In general, the command is as follows:

```Bash
segul align summary <input-option> [alignment-path] --datatype [datatype]
```

The `summary` function produces three summary statistics:

1. Summary statistics for all the alignments printed in the terminal and written to the log file (`segul.log`).
2. Summary statistics for each alignment (assuming locus) written to a CSV file (default name: `locus_summary.csv`).
3. Summary statistics for each taxon written to a CSV file (default name: `taxon_summary.csv`).

Learn more about specifying the output directory and filenames [here](./align-summary#specifying-the-output-directory-and-filenames).

## Computing sequence summary statistics for DNA sequences

Because the SEGUL datatype defaults to DNA, we don't need to pass the command's `--datatype` option. For example, to generate summary statistics for alignments in the folder `alignments/`:

```Bash
segul align summary -d alignments/
```

or using the `--input` or `-i` option:

```Bash
segul align summary -i alignments/*.nexus
```

Below is an example of segul terminal output for DNA sequence summary statistics. This output is based on alignments from [Oliveros et al. (2019)](https://www.pnas.org/content/116/16/7916.short).

:::info
Since v0.21.0, SEGUL writes the alignment summary in a separate text file (default name: `alignment_summary.txt`) consistent with the GUI version.
:::

```Text
=========================================================
SEGUL v0.11.1
An alignment tool for phylogenomics
---------------------------------------------------------
Input dir         : oliveros_et_al_2019/
File counts       : 4,060
Input format      : Nexus
Data type         : DNA
Task              : Sequence summary statistics

🌘 Finished computing summary stats!

General Summary
Total taxa        : 221
Total loci        : 4,060
Total sites       : 2,464,926
Missing data      : 38,227,233
%Missing data     : 7.32%
GC content        : 0.36
AT content        : 0.56
Characters        : 522,529,858
Nucleotides       : 484,302,625

Alignment Summary
Min length        : 155 bp
Max length        : 1,410 bp
Mean length       : 607.12 bp

Taxon Summary
Min taxa          : 177
Max taxa          : 221
Mean taxa         : 210.84

Character Count
?                 : 36,681,846
-                 : 1,545,387
A                 : 147,184,543
C                 : 94,814,080
G                 : 94,526,406
T                 : 147,777,596

Data Matrix Completeness
100% taxa         : 15
95% taxa          : 3,069
90% taxa          : 3,729
85% taxa          : 3,961
80% taxa          : 4,060

Conserved Sequences
Con. loci         : 0
%Con. loci        : 0.00%
Con. sites        : 1,261,559
%Con. sites       : 0.51%
Min con. sites    : 16
Max con. sites    : 885
Mean con. sites   : 0.51

Variable Sequences
Var. loci         : 4,060
%Var. loci        : 100.00%
Var. sites        : 1,203,367
%Var. sites       : 0.49%
Min var. sites    : 15
Max var. sites    : 814
Mean var. sites   : 0.49

Parsimony Informative
Inf. loci         : 4,060
%Inf. loci        : 100.00%
Inf. sites        : 811,688
%Inf. sites       : 0.33%
Min inf. sites    : 2
Max inf. sites    : 631
Mean inf. sites   : 0.33

Output Files
Alignment summary : locus_per_locus.csv
Log file          : segul.log

Execution time    : 4.3725607s
```

### Computing sequence summary statistics for amino acid sequences

We need to use the `--datatype aa` option to compute the summary statistics for amino acid sequences. For example:

```Bash
segul align summary -d alignments/ --datatype aa
```

If we use the `--input` or `-i` option, the command will be:

```Bash
segul align summary -i alignments/*.nexus --datatype aa
```

### Setting up data matrix completeness interval

By default, SEGUL will print the percentage of data matrix completeness with a decrement interval of 5 percent. It starts from 100% until it reaches all alignment coverage or near zero percent completeness. With the default interval, if SEGUL never reaches all alignment coverage, it will stop printing the result when the result reaches 5%. In the Oliveros et al. (2019) dataset [above](./align-summary#computing-sequence-summary-statistics-for-dna-sequences), SEGUL stops printing the data matrix completeness at 80% because it already covers the total number of alignments (4,060 alignments).

Use the `--interval` option to change the interval setting. SEGUL supports intervals 1, 2, 5, and 10. For example:

```Bash
segul align summary -i alignments/*.nexus --interval 1
```

Using Oliveros et al. (2019) dataset with 1% interval, the data matrix completeness result will be as below:

```Text
Data Matrix Completeness
100% taxa         : 15
99% taxa          : 520
98% taxa          : 1,219
97% taxa          : 1,953
96% taxa          : 2,496
95% taxa          : 3,069
94% taxa          : 3,301
93% taxa          : 3,445
92% taxa          : 3,548
91% taxa          : 3,636
90% taxa          : 3,729
89% taxa          : 3,786
88% taxa          : 3,841
87% taxa          : 3,880
86% taxa          : 3,908
85% taxa          : 3,961
84% taxa          : 3,980
83% taxa          : 4,005
82% taxa          : 4,021
81% taxa          : 4,050
80% taxa          : 4,060
```

### Specifying the output directory and filenames

The two CSV files are saved in the `SEGUL-Stats` directory by default. You can change the directory name by using the `--output` or `-o` option. For example:

```Bash
segul align summary -d alignments/ -f nexus -o alignment_stats
```

You can also add a prefix to the CSV filenames using the `-- prefix` option. For example:

```Bash
segul align summary -d alignments/ -f nexus -o alignment_stats --prefix my_samples
```

The command above will create a directory named `alignment_stats/` and write the CSV output files. Using the `--prefix` option, the output filename for the taxon summary will be `my_samples_taxon_summary.csv,`. For the locus, the summary will be `my_samples_locus_summary.csv.`,  and `my_samples_alignment_summary.csv` for the alignment summary.
