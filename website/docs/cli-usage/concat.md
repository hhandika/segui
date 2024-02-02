---
sidebar_position: 3
---
# Alignment Concatenation

`segul` provides an easy way to concat multiple alignments and generate the partition setting at the same time.

For version 0.19.0+

```Bash
segul align concat <input-argument> [input-path] --input-format [sequence-format]
```

For version 0.18.0 and below:

```Bash
segul concat <input-argument> [input-path] --input-format [sequence-format]
```

For example, we will concat all the alignments in this folder:

```Bash
alignments/
├── locus_1.nexus
├── locus_2.nexus
└── locus_3.nexus
```

We can do it in two ways. First, using `--dir` argument to input alignment files:

For version 0.19.0+

```Bash
segul align concat --dir alignments/
```

For version 0.18.0 and below:

```Bash
segul concat --dir alignments/ --input-format nexus
```

Second, we can use the `--input` argument to input the alignment files. We will rely on wildcard and the OS to find all the alignment files. We do not need to specify the input format for `.nexus` file extension:

For version 0.19.0+

```Bash
segul align concat --input alignments/*.nexus
```

For version 0.18.0 and below:

```Bash
segul concat --input alignments/*.nexus
```

`segul` will generate two files saved in `SEGUL-concat` directory, consisting of the concatenated alignments and the partition settings:

```Bash
SEGUL-concat/
├── SEGUL-Concat.nex
└── SEGUL-Concat_partition.nex
```

To specify the name of the output directory, use the `--output` or `-o` option. Below, we will name our output directory `aln-concat`.

For version 0.19.0+

```Bash
segul align concat --input alignments/*.nexus --output aln-concat
```

For version 0.18.0 and below:

```Bash
segul concat --input alignments/*.nexus --output aln-concat
```

To specify the prefix of the file names use the `--prefix` option. Below, our output filenames will start with concat:

For version 0.19.0+

```Bash
segul align concat --input alignments/*.nexus --output aln-concat --prefix concat
```

For version 0.18.0 and below:

```Bash
segul concat --input alignments/*.nexus --output aln-concat --prefix concat
```

The resulting output directory will contain files as below:

```Bash
aln-concat/
├── concat.nex
└── concat_partition.nex
```

By default, the partition format is in nexus:

```Text
#nexus
begin sets;
charset 'locus-1' = 1-666;
charset 'locus-2' = 667-1473;
charset 'locus-3' = 1474-2000;
end;
```

You can specify the partition format using `--part` or `-p` option.

For example, to use raxml format:

For version 0.19.0+

```Bash
segul align concat --input alignments/*.nexus --output concat --prefix concat --part raxml
```

For version 0.18.0 and below:

```Bash
segul concat --input alignments/*.nexus --output concat --prefix concat --part raxml
```

The resulting partioned will be formatted in raxml style:

```Text
DNA, locus_1 = 1-666
DNA, locus_2 = 667-1473
DNA, locus_3 = 1474-2000
```

If the input is amino acid sequence, the partion will not contain the datatype:

The resulting partioned will be formatted in raxml style:

```Text
locus_1 = 1-666
locus_2 = 667-1473
locus_3 = 1474-2000
```

You can also use `charset` format. In this format, the partition will be written at the end of the sequence and only available for the nexus output. This format is usually required for phylogenetic programs, such PAUP and BEAST. To use `charset` format:

For version 0.19.0+

```Bash
segul align concat --input alignments/*.nexus --output concat --prefix concat --part charset
```

```Bash
segul concat --input alignments/*.nexus --output concat --prefix concat --part charset
```

You can also write the partition to a codon model format by using the flag `--codon`. You may not need this option for genomic datasets. We reserve this function for Sanger datasets.
