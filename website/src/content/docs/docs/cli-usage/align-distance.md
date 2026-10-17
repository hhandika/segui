---
title: Alignment Distance
sidebar:
  order: 4.5
---

Compute pairwise genetic distances between samples for each alignment. SEGUL writes a distance matrix for every locus and a summary table across all loci, so you can compare thousands of loci in a single command.

:::note
This feature is available in SEGUL v0.24.0 and later versions. To check your SEGUL version, run in your terminal:

```bash
segul --version
# Compatible version example:
# segul 0.24.0
```

Check the [Installation Guide](/docs/installation/update/#segul-cli) to update SEGUL to the latest version.
:::

## Quick example

Assume we have an alignment file named `locus_1.fas` in FASTA format as follows:

```plaintext
>seq1
ACGTAC
>seq2
ACGTAT
>seq3
AC-TTC
```

To compute uncorrected p-distances, use the following command:

```bash
segul align distance --dir alignments/
```

The distance matrix for the locus is written to `Align-Distance/per_locus/locus_1.csv`:

```plaintext
,seq1,seq2,seq3
seq1,0.000000,0.166667,0.200000
seq2,0.166667,0.000000,0.400000
seq3,0.200000,0.400000,0.000000
```

`seq1` and `seq2` differ at one of six sites (1/6 = 0.166667). The gap in `seq3` is skipped, so `seq1` and `seq3` differ at one of the five remaining sites (1/5 = 0.2).

## Detailed usage

### Distance models

Use the `--model` option to choose a distance model. The default is the uncorrected p-distance.

| Option    | Model                                          | Data type        |
| --------- | ---------------------------------------------- | ---------------- |
| `p`       | Uncorrected p-distance (proportion of differences) | DNA, amino acid |
| `jc69`    | Jukes-Cantor (1969)                            | DNA, amino acid  |
| `k2p`     | Kimura 2-parameter (1980)                      | DNA              |
| `tn93`    | Tamura-Nei (1993)                              | DNA              |
| `poisson` | Poisson correction                             | Amino acid       |

For example, to compute Kimura 2-parameter distances:

```bash
segul align distance --dir alignments/ --model k2p
```

For the Tamura-Nei model, SEGUL estimates the base frequencies from all sequences in each alignment.

SEGUL stops with an error if the model does not match the data type, such as `k2p` for amino acid sequences.

### Amino acid alignments

If the input is amino acid sequences, use the `--datatype aa` option. For example:

```bash
segul align distance --dir alignments/ --datatype aa --model poisson
```

:::note
The `--datatype ignore` option is not supported for this feature. SEGUL needs to know the data type to choose the valid characters and models.
:::

### Missing data and ambiguous characters

SEGUL uses pairwise deletion. For each pair of samples, a site is skipped if either sequence has a gap (`-`), missing data (`?`), or an ambiguous character at that site. For DNA, only `A`, `C`, `G`, and `T` (or `U`) are compared, so `N` and other IUPAC ambiguity codes are skipped. For amino acids, only the 20 standard residues are compared. Uppercase and lowercase characters are treated the same.

A distance is reported as `NA` if:

- A pair has no sites left to compare.
- A corrected distance cannot be computed because the sequences are too divergent (saturated). For example, the Jukes-Cantor distance for DNA is undefined when the p-distance is 0.75 or higher.

### Output files

By default, SEGUL writes the output to `Align-Distance`:

```plaintext
Align-Distance/
├── distance_summary.csv
└── per_locus/
    ├── locus_1.csv
    └── locus_2.csv
```

Each file in `per_locus/` is a square distance matrix named after the input alignment. Samples are listed in the same order as in the alignment.

### Writing the lower or upper triangle

The distance matrix is symmetric, so each value appears twice. Use the `--triangle` option to write only one triangle, which is common for tables in scientific publications. The options are `full` (default), `lower`, and `upper`. For example:

```bash
segul align distance --dir alignments/ --triangle lower
```

Using the quick example above, the cells above the diagonal are left empty:

```plaintext
,seq1,seq2,seq3
seq1,0.000000,,
seq2,0.166667,0.000000,
seq3,0.200000,0.400000,0.000000
```

### Setting the diagonal

Use the `--diagonal` option to choose what to write on the diagonal:

- `zero` (default): the distance of each sample to itself, `0.000000`.
- `blank`: leave the diagonal empty.
- `max`: the highest distance between the sample and any other sample in the locus. It is written as `NA` if the sample has no defined distances.

For example, to write a lower triangle with an empty diagonal:

```bash
segul align distance --dir alignments/ --triangle lower --diagonal blank
```

Using the quick example above:

```plaintext
,seq1,seq2,seq3
seq1,,,
seq2,0.166667,,
seq3,0.200000,0.400000,
```

With `--diagonal max`, the diagonal shows the highest distance of each sample: `0.200000` for `seq1`, `0.400000` for `seq2`, and `0.400000` for `seq3`.

### Summary file

The `distance_summary.csv` file contains one row per locus with the following columns:

| Column                | Description                                              |
| --------------------- | -------------------------------------------------------- |
| `locus`               | Locus name (alignment file name without its extension)  |
| `path`                | Path to the input alignment                              |
| `model`               | Distance model                                           |
| `ntax`                | Number of samples                                        |
| `nchar`               | Alignment length                                         |
| `pairs`               | Number of sample pairs                                   |
| `undefined_pairs`     | Number of pairs reported as `NA`                         |
| `min`, `max`          | Minimum and maximum pairwise distance                    |
| `mean`, `median`      | Mean and median pairwise distance                        |
| `sd`                  | Sample standard deviation of pairwise distances          |
| `mean_compared_sites` | Average number of sites compared per pair                |

The statistics only include pairs with a defined distance. They are empty for loci with fewer than two samples, and `sd` is empty for loci with a single pair.

### Specifying the output directory and prefix

You can change the output directory name using the `--output` or `-o` option. Use the `--prefix` option to change the name of the summary file. For example, the command below writes the summary to `distance-output/k2p_summary.csv`:

```bash
segul align distance --dir alignments/ --model k2p --output distance-output --prefix k2p
```

### More ways to specify input files

You can also specify input files using the `--input` or `-i` option. This option allows you to provide a single alignment file or multiple alignment files using [wildcards](https://en.wikipedia.org/wiki/Wildcard_character). For example:

```bash
segul align distance --input alignments/*.fasta
```
