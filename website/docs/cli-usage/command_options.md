---
sidebar_position: 2
---

# Command Options

SEGUL CLI command is structured this way:

```Bash
<PROGRAM-NAME> <COMMAND> <SUBCOMMAND> <OPTIONS> [VALUES] <FLAGS>
```

The program name is `segul` on Linux, MacOS, and Windows Subsystem for Linux, and `segul.exe` on Windows. We group features into categories represented as commands. SEGUL CLI features are available using subcommands. Each of the subcommands has options, and some of them also have flags. Options require users to input the value, such as the `--dir` option that requires users to input the path to the alignment directory: `--dir alignment_path/`. Some options are available across all subcommands, whereas others are specific to certain subcommands (see below). Flags are used without a value, such as the `--sort` flag in the `convert` subcommand used to sort sequences in the output files.

In summary, we keep SEGUL CLI commands, subcommands, and options consistent:

1. The SEGUL CLI consists of commands and subcommands, such as `segul sequence convert` and `segul align concat`.
2. Long options, such as the `--input` option, are always prefixed with double dashes (`--`).
3. Short options are always prefixed with a single dash (`-`). For example, the short `--input` option is `-i`.
4. Options with equal sign (`=`), such as `--re=`, require the input values to be in a single or double quotation. For example, `--re="^Genus"`.
5. Some options are available in both long and short versions, while the rest are only available in long versions. The SEGUL CLI command options will never be available only in a short version.

SEGUL CLI command option as of v0.21.3

```Bash
Commands:
  read       Sequence read analyses
  contig     Contiguous sequence analyses
  align      Alignment analyses
  partition  Alignment partition conversion
  sequence   Sequence analyses
  help       Print this message or the help of the given subcommand(s)
```

Example subcommands for alignment category:

```bash
Commands:
  concat   Concatenate alignments
  convert  Convert sequence formats
  filter   Filter alignments
  split    Split alignment by partitions
  summary  Compute Alignment Statistics
  help     Print this message or the help of the given subcommand(s)
```

Example options and flags available for the alignment concatenation feature:

```bash
Options:
  -d, --dir <PATH>
          Input a directory
  -i, --input <INPUT>...
          Input a path (allow wildcard)
      --force
          Force overwriting existing output files/directory
  -f, --input-format <SEQUENCE INPUT FORMAT>
          Specify input format [default: auto] [possible values: auto, fasta, nexus, phylip]
      --datatype <DATATYPE>
          Specify sequence datatype [default: dna] [possible values: dna, aa, ignore]
  -F, --output-format <OUTPUT_FMT>
          Specify output format [default: nexus] [possible values: fasta, nexus, phylip, fasta-int, nexus-int, phylip-int]
      --log <LOG>
          Log file path [default: segul.log]
  -p, --partition-format <PART_FMT>
          Specify partition output format [default: nexus] [possible values: charset, nexus, raxml]
      --codon
          Set as a codon model partition format
      --prefix <PREFIX>
          Specify prefix for output files
  -o, --output <OUTPUT>
          Output path [default: Align-Concat]
      --sort
          Sort sequences by IDs alphabetically
  -h, --help
          Print help
```

## Help options

To show available commands, type `segul`, `segul --help`, or `segul -h`. This will display all the available commands and their description.

To show available subcommands in each of the commands, use `segul <COMMAND> <SUBCOMMAND> --help` or `segul <COMMAND> <SUBCOMMAND> -h`. The help function will show all the options, default values (if available), or possible values you can input when the program limits it.

For example, terminal output for `segul align convert -h`:

```Bash
Convert sequence formats

Usage: segul align convert [OPTIONS]

Options:
  -d, --dir <PATH>
          Input a directory
  -i, --input <INPUT>...
          Input a path (allow wildcard)
      --force
          Force overwriting existing output files/directory
  -f, --input-format <SEQUENCE INPUT FORMAT>
          Specify input format [default: auto] [possible values: auto, fasta, nexus, phylip]
      --datatype <DATATYPE>
          Specify sequence datatype [default: dna] [possible values: dna, aa, ignore]
  -F, --output-format <OUTPUT_FMT>
          Specify output format [default: nexus] [possible values: fasta, nexus, phylip, fasta-int, nexus-int, phylip-int]
      --log <LOG>
          Log file path [default: segul.log]
  -o, --output <OUTPUT>
          Output path [default: Align-Convert]
      --sort
          Sort sequences by IDs alphabetically
  -h, --help
          Print help
```

## Input options

- `-i` or `--input`: Use wildcards for a single file input or multiple input. This option is useful for dealing with complicated directory structures.
- `-d` or `--dir`: If your input is a path to a directory. It looks for files that match recursively across the input directory and its subdirectory. For version below v0.19.0, the directory input requires users to specify the input format.

Most users should generally use the `--dir` or `-d` option. The log file will capture the path, which is helpful for record keeping.

The standard input option relies on the operating system to provide input paths. It is reserved for complex folder structures or when your alignment extension uses uncommon file extensions (see below). In the log file, it will only print `STDIN` (Standard Input). For any SEGUL version, using this input option will not require using the `--input-format`. The app will infer the input format based on the file extension.

For example, your alignment files are stored in multiple folders, and you would like to generate summary statistics for files with specific names. Instead of running SEGUL multiple times, you can generate the statistics in a single run using the wildcard option:

```Bash
segul align summary -i parent_dir/*/contig.fasta
```

Below are several other examples of using `--input` (or `-i` in short format):

Inputting multiple files in a directory using wildcard:

```Bash
segul <COMMAND> <SUBCOMMAND> -i alignment-dir/*.fasta
```

For unusual file extensions or if the app failed to detect the file format, specify the input format:

```Bash
segul <COMMAND> <SUBCOMMAND> -i alignment-dir/*.aln -f fasta
```

:::note
Wildcards on Windows only work for files, not directories.
:::

## Input format

Arguments: `-f` or `--input-format`

Availabilities: all subcommands

It is used to specify the input format and support both sequential and interleave formats. In most cases, you don't need to specify the input format. SEGUL will infer it based on the file extension. Specify the input format if your file extension is unusual, for example `.aln` instead of `.fasta` or `.fas`.

Input format options for `sequence` and `align` commands:

- `auto` (default)
- `nexus`
- `phylip`*
- `fasta`

For `read` commands:

- `auto` (default)
- `fastq`
- `gz`

For `contig` commands:

- `auto` (default)
- `fasta`
- `gz`

:::note
SEGUL only supports the relaxed-PHYLIP format. The strict PHYLIP format is not supported.

Example of relaxed PHYLIP format:

```plaintext
5 10
Seq1    ATCGATCGATATCGATCGAT
Seq2    ATCGATCGATATCGATCGAT
Seq3    ATCGATCGATATCGATCGAT
```

Example of strict PHYLIP format (note the space between each sequence):

```plaintext
5 10

Seq1    ATCGATCGAT ATCGATCGAT
Seq2    ATCGATCGAT ATCGATCGAT
Seq3    ATCGATCGAT ATCGATCGAT
```

:::

## Output

Arguments: `-o` or `--output`

Availabilities: all subcommands

Each SEGUL-supported task has a default output directory. By default, the app writes to its output directory relative to the current working directory. Use the `--output` option to specify the output directory. The app will check if the same directory exists in the current working directory. It will prompt users to remove the existing directories. If users select `Yes`, the app will remove the existing directory and continue executing the command. Otherwise, it will exit. You can use the `--force` option to allow SEGUl to remove existing directories without showing the prompt. This option is helpful for an environment that does not allow the user to interact with the prompt, such as HPC clusters.

## Output format

Arguments: `-F` or `--output-format`

Use this option to specify the output format. Some commands that output sequences have a default output format. For example, the default output format for the `concat` subcommand is `nexus`. Specify the output format if you want to convert the sequences to a different format. Use can check the default value for each subcommand using the `segul <command> <subcommand> --help` option.

Supported output sequence formats:

- `nexus`
- `phylip`
- `fasta`

Interleaved formats:

- `fasta-int`
- `nexus-int`
- `phylip-int`

## Data types

Argument: `--datatype`

Availabilities: `segul align`, `segul sequence`

The app supports DNA and amino acid sequences for `alignment` and `sequence` commands. By default, the data type is set for DNA sequences. If your input file is amino acid sequences, you must change the data type to `aa`. By specifying the data type, the app will check if your sequence files contain valid IUPAC characters. The `--datatype ignore` option usually speeds up the computation by up to 40%.

When to use the `--datatype ignore` option:

1. Your dataset is DNA.
2. If your dataset consists of amino acid sequences, either the input is in the NEXUS format or the output is not in Nexus format.
3. You are sure your sequences contain only IUPAC characters and no spaces in the sequence names, or you have previously used the same dataset for SEGUL input.

To summarize, available data types:

- `aa`
- `dna`
- `ignore`

## Special arguments

### Prefix

Arguments: `--prefix`

The input for this option will be used as a prefix for the filenames.

### Input Partition

Arguments: `-I` or `--input-partition`

Availabilities: `partition` and `split` subcommand

Input input partition for splitting alignments by partition.

### Output Partition

Arguments: `-P` or `--output-part`

Availabilities: `segul partition convert`

Specify an output partition format.

### Partition format

Arguments: `-p` or `--part`

Availabilities: `concat`, `split`, and `filter` subcommands

This option is used to specify the partition format. By default, the format is NEXUS. Available options:

- `charset` (embedded in a nexus sequence)
- `nexus`
- `raxml`

### Percentage interval

Arguments: `-i` or `--interval`

Availabilities: `segul align summary` subcommand

This option is to specify the percentage decrement interval for computing data matrix completeness in summary statistics. The app will stop printing the data matrix completeness statistics when it reaches near zero (the lowest value depends on the interval value) or a maximum number of alignments. Default to 5. Available interval: `1`, `2`, `5`, `10`.

### Filtering options

Only available for the `segul align filter` subcommand. Available options:

- `-l` or `--len`: To filter alignments based on minimal alignment length
- `--percent`: To filter based on percentage of data matrix completeness.
- `--npercent`: The same as `--percent`, but accept multiple values. This option allows you to create collections of alignments with different data matrix completeness in a single command.
- `--pinf`: To filter based on the number of parsimony informative sites.
- `--percent-inf`: To filter based on a percentage of parsimony informative sites. Calculated based on the highest parsimony informative sites across all alignments.
- `--ntax`: To define the total number of taxa. By default, the app determines the number of taxa in all the alignments based on the number of unique IDs.

### Extracting options

Only available for the `segul align extract`. Available options:

- `--file`: Use to input a list of sequence IDs in a txt file.
- `--id`: Use to input a list of sequence IDs using the standard terminal input (stdin). Allow for multiple values.
- `--re=`: Use to input a regular expression to extract matching sequence IDs.

### Renaming options

Only available for the `segul sequence rename` subcommand. Available options:

- `-n` or `--name`: Use to input a CSV or a TSV file that contains the original names and the new names for the sequence ID.

### Translating options

Only available for the `segul sequence translate`. Available options:

- `--rf`: To set the reading frame for translating DNA sequences.
- `--table`: To set the translation table. The input number is based on NCBI translation table. Default to the NCBI standard code (Table 1).

## Special flags

- `--codon`: This is used to set the partition format to the codon model. It is available for the `segul align concat` and `segul align filter` (if you choose to concatenate the result).
- `--concat`: If this option is set, the app will concatenate filtered alignments instead of copying the files. It is available for the `segul align filter`.
- `--sort`: To sort the sequences based on their IDs in alphabetical order. Available for the `segul align convert`.
- `--show-table`: To show the supported NCBI translation table. Only available to the `segul sequence translate`.
- `--map`: Map sequence distribution across a collection of alignments. Only available for the `segul sequence id`.
- `--dry-run`: To check if the app can correctly parse input IDs. Only available for the `segul sequence rename`.
- `-h` or `--help`: Display help information.
- `-V` or `--version`: To display the app version information.
