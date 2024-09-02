---
sidebar_position: 13
---

# Sequence Extraction

SEGUL can extract sequences based on the sequence ID in a collection of alignments. You can input the sequence ID in three ways:

1. Using the standard input (stdin) via terminal
2. By inputting a list of IDs in a text file
3. Using regular expression

By default, segul will write the results in a nexus format and use the name from the original input. More details [below](./sequence-extract#specifying-output-directory-and-format).

## Extracting sequences using stdin

This method is helpful if you only extract a few sequences across all your alignments. To input the ID list, use `--id` option. Semi-colons should separate the list of IDs.

```Bash
segul sequence extract <input-option> [alignment-dir] --id="[list-of-sequence-id]"
```

For example, using the command below, we will extract `seq_1`, `seq_2`, and `seq_3` from our alignments stored in `alignments/` directory:

```Bash
segul sequence extract --dir alignments/ --id="seq_1;seq_2;seq_3"
```

:::warning
To input a list of IDs, you must use the equal sign `=` and quotation marks `"`.
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
segul sequence extract --dir alignments/ --file id.txt
```

For lots of ID, you can generate all the IDs first using SEGUL [sequence ID extraction](./sequence-id). Open the text file using your text editor and remove the sequence IDs you don't need. Use this file as an input for `segul sequence extract`.

## Extracting sequences using regular expression (REGEX)

This is the most flexible option to extract sequences from a collection of alignments. SEGUL uses the Rust [regex](https://docs.rs/regex/latest/regex/) library to parse regular expression syntax. The syntax is similar to Perl-style regex syntax (details [here](https://docs.rs/regex/latest/regex/#syntax)). To test your syntax, you can use a website like [https://regex101.com/](https://regex101.com/).

Use the option `-re=` for a regular expression and put the syntax in a single or double quotation. For example, our sequence ID is named this way `genus_species_voucherNo`. We want to extract the sequences from the same genus: `Mus`. We could write a regular expression that searches for sequence ID that starts with `Mus` as below. The `^` indicates the start of the word in REGEX syntax.

```Bash
segul sequence extract --dir alignments/ --re="^Mus"
```

We could also search it with an insensitive match by adding (?i) syntax.

```Bash
segul sequence extract --dir alignments/ --re="^(?i)mus"
```

Each alignment containing matched sequences will be written to the output files. The alignment's name will remain the same as the original.

## Specifying output directory and format

By default, the output files will be written into `SEGUL-Extract` directory. To change the directory name, use the `--output` or `-o` option. For the output files, the matched sequences will be written in nexus format using the alignment original name. You can change the output format using the `--output-format` (or `-F` in the short version) option. For example, below, we'll be able to change both the output directory and the output format of the resulting files.

```Bash
segul sequence extract --dir alignments/ --re="^Mus" output Mus-alignment/ --output-format Fasta
```
