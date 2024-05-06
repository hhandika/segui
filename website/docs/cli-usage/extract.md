---
sidebar_position: 14
---

# Sequence Extraction

`segul` can extract sequences in a collection of alignments based on the sequence ID. You can input the sequence ID in three ways:

1. Using the standard input (stdin) via terminal
2. By inputting a list of IDs in a text file
3. Using regular expression

By default, segul will write the results in a nexus format and use the name from the original input. More details [below](./extract#specifying-output-directory-and-format).

## Extracting sequences using stdin

This method is useful if you only need to extract a few sequences across all your alignments. To input the list of ID, use `--id` option. The list of IDs should be separated by semi-colons.

```Bash
segul sequence extract <input-option> [alignment-dir] --input-format [seq-format] --id="[list-of-sequence-id]"
```

For example, using the command below, we will extract `seq_1`, `seq_2`, and `seq_3` from our alignments stored in `alignments/` directory:

```Bash
segul --dir alignments/ --input-format nexus --id="seq_1;seq_2;seq_3"
```

:::warning
The equal sign `=` and quotation marks `"` are required to input a list of IDs.
:::

## Extracting sequences using an input file

With a long list of IDs, it will be more convenient to input the list of the IDs instead. `segul` `--file` option is available for this task. You only need to list all the IDs in a text file with each ID in a new line as below:

```Text
seq_1
seq_2
seq_3
seq_4
seq_5
```

The command will be:

```Bash
segul sequence extract --dir alignments/ --input-format nexus --file id.txt
```

For lots of ID, you can generate all the ID first using `segul` [sequence ID extraction](./id). Open the text file using your text editor and remove the sequence IDs that you don't need. Use this file as an input for `segul sequence extract`.

> NOTES: `segul` can parse input file written both on Unix-like OS (Linux, WSL, and MacOS) and Windows with carriage return.

## Extracting sequences using regular expression

This is the most flexible option to extract sequence from a collection of alignments. `segul` use the Rust [regex](https://docs.rs/regex/latest/regex/) library to parse regular expression syntax. The syntax is similar to Perl-style regex syntax (details [here](https://docs.rs/regex/latest/regex/#syntax)). You can use [this website](https://regex101.com/) to test your syntax.

To use regular expression, use the option `--re=` and put the syntax in either a single or double quotation. For example, our sequence id is named this way `genus_species_voucherNo`. We want to extract the sequences from the same genus: `Mus`. We could write a regular expression that search for sequence ID that starts with `Mus` as below:

```Bash
segul sequence extract --dir alignments/ --input-format nexus --re="^Mus"
```

We could also search it with case insensitive match:

```Bash
segul sequence extract --dir alignments/ --input-format nexus --re="^(?i)mus"
```

All the matched sequences found in each alignment will be written to the output files. The name of the alignment will be maintain as the original.

## Specifying output directory and format

By default, the output files will be written into `SEGUL-Extract` directory. To change the directory name, use the `--output` or `-o` option. For the output files, the matched sequences will be written in nexus format using the alignment original name. You can change the output format using `--output-format` (or `-F` in short version) option. For example, below we will change both the output directory and the output format of the resulting files.

```Bash
segul sequence extract --dir alignments/ --input-format nexus --re="^Mus" output Mus-alignment/ --output-format Fasta
```
