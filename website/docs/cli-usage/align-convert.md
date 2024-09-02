---
sidebar_position: 4
---

# Alignment Conversion

SEGUL can convert a single file to multiple files in the same directory.

## Converting a single file

To convert a single file, use the `--input` or `-i`.

```Bash
segul align convert --input [a-path-to-file] --output-format [sequence-format]
```

SEGUL should be able to infer the input file format based on the extension of your file. If your file extension is uncommon (for example, .aln instead of .fas), specify the `--input-format`:

```Bash
segul align convert --input [a-path-to-file] --input-format [sequence-format] --output-format [sequence-format]
```

For example, here we will convert a nexus file containing DNA sequences named `loci.nexus` to fasta format:

```Bash
segul align convert --input alignments/loci.nexus -output-format fasta
```

You can ignore specifying the output format if you want the output files in NEXUS format. For example, we will convert loci.fasta to nexus format:

```Bash
segul align convert --input alignments/loci.fasta
```

Some `segul` arguments are available in short format (note the uppercase 'F' for the output format):

```Bash
segul align convert -i alignments/loci.nexus -f nexus  -F fasta --datatype aa -o alignment-fasta
```

:::note
When converting alignments, SEGUL only changes the file extension and maintains the original file names for the output files. This behavior is the same for a single or multiple file format conversion, giving the app the flexibility to convert many files in a single command.
:::

## Batch converting sequence files in a directory

We have the option to provide the input files to the program. First, use the `--dir` or `-d` input. For a directory input, it is required to specify the `--input-format`:

```Bash
segul align convert --dir [path-to-your-repository] --input-format [sequence-format] --output [your-output-dir-name] --output-format [sequence-format]
```

In short format:

```Bash
segul align convert -d [path-to-your-repository] -f [sequence-format] -o [your-output-dir-name]
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
segul align convert -d alignments/ -f nexus -F fasta -o alignments-fas
```

We can also input wildcard (\*) using the `--input` or `-i` option to achieve the same results:

```Bash
segul align convert -i alignments/*.nexus -f nexus -F fasta -o alignments-fas
```

The outputs will be:

```Bash
alignments-fas/
├── locus_1.fas
├── locus_2.fas
└── locus_3.fas
```

## Converting amino acid sequences

By default, the SEGUL datatype is set to convert DNA sequences. If your file contains amino acid sequences, use the argument `--datatype aa`. For example:

```Bash
segul align convert --input alignments/loci.nexus -output-format fasta --datatype aa
```

## Specifying the output directory

By default, segul will write the result in a directory called `SEGUL-convert`. To specify the output directory, use the `--output` argument. For example, here, we will specify the output directory to `alignment-fasta`.

```Bash
segul align convert --input alignments/loci -output-format fasta --datatype aa --output alignment-fasta
```

## Sorting the output sequences

By default, SEGUL maintains the original order of the sequences in the input file(s). Using the `--sort` flag, you can sort the sequences in alphabetical order based on their IDs:

```Bash
segul align convert --input alignments/loci -output-format fasta --datatype aa --output alignment-fasta --sort
```

