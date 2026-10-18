---
title: Alignment Distance
sidebar:
  order: 4.5
---

Compute pairwise genetic distances between samples for each alignment. SEGUL writes a distance matrix for every locus and a summary table across all loci, so you can compare thousands of loci in a single command. SEGUL can also average the distances within and between populations or species, and write all distances as long tables.

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

To also average the distances within and between species, and write long tables for all loci, add a grouping option and `--long`:

```bash
segul align distance --dir alignments/ --group-auto --long
```

See [Group means](#group-means-for-populations-or-species) and [Long-format tables](#long-format-tables) for details.

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
- `na`: write `NA`.

With grouping, `--diagonal` also accepts `mean` and `max` for the group matrices. See [Group matrix diagonal](#group-matrix-diagonal).

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

### Group means for populations or species

When samples are individuals, a matrix per locus is hard to compare. Group the samples into populations or species, and SEGUL also computes the mean distance within each group and between each pair of groups. Choose one of four ways to group samples:

| Option | Groups by |
| ------ | --------- |
| `--group-delimiter <CHAR> --group-fields <N>` | The first `N` parts of the sample name split on `CHAR`. With `_` and `2`, `Rattus_rattus_FMNH1` belongs to `Rattus_rattus`. A name with fewer than `N` parts matches no group. |
| `--group-regex <PATTERN>` | The first capture group of the regular expression, or the whole match if the pattern has no capture group. |
| `--group-file <PATH>` | A CSV (`.csv`) or TSV (`.tsv`) file. The first row is a header, followed by one sample and its group per row. |
| `--group-auto` | A delimiter and field count detected from the sample names. |

For example, to group samples named `Genus_species_ID` by species:

```bash
segul align distance --dir alignments/ --group-delimiter _ --group-fields 2
```

A group file for populations looks like this:

```plaintext
sample,group
FMNH1,North
FMNH2,North
FMNH3,South
```

#### Detecting groups from sample names

With `--group-auto`, SEGUL tries the delimiters `_`, `-`, `.`, `|`, and space, with every field count that leaves at least one part out of every name. A candidate is kept if it gives more than one group, fewer groups than samples, and at least 80% of samples share their group with another sample. SEGUL picks the kept candidate with the most groups, so `Genus_species_ID` names are grouped by species rather than genus. It logs the delimiter and field count it chose, and stops with an error if no candidate is kept. For names such as `Genus_species_population_ID`, auto-detection gives populations. Use `--group-delimiter _ --group-fields 2` to group by species instead.

#### Group output files

Assume the alignment `locus_1.fas` has two samples of each of two species, grouped with `--group-delimiter _ --group-fields 1`:

```plaintext
>sp1_a
ACGTAC
>sp1_b
ACGTAT
>sp2_a
TCGTAC
>sp2_b
TCGAAC
```

The group matrix for the locus is written to `per_locus_group/locus_1.csv`. By default, the diagonal holds the mean distance within each group, and the other cells hold the mean between two groups:

```plaintext
,sp1,sp2
sp1,0.166667,0.333333
sp2,0.333333,0.166667
```

The two `sp1` samples differ at one of six sites (1/6). The four pairs between species differ at 1, 2, 2, and 3 sites, so the mean is 8/24 = 0.333333.

SEGUL also pools all loci into `<prefix>_group_mean.csv` (by default `distance_group_mean.csv`). The pooled mean averages every sample pair of every locus, so loci with more pairs count more. `<prefix>_group_pairs.csv` has the same layout and holds the number of pairs behind each mean.

A within-group mean is `NA` if the group has a single sample in the locus. Samples that match no group are left out of the group means, and SEGUL logs how many there are. `--triangle` applies to the group matrices too.

#### Group matrix diagonal

With grouping, `--diagonal` sets the diagonal of the group mean matrices, both per locus and pooled:

- `mean` (default with grouping): the mean distance within the group.
- `max`: the highest distance between two samples of the group.
- `zero`, `blank`, or `na`: the same as for the sample matrices.

With `mean` and `max`, the sample matrices hold zero on the diagonal. Both are `NA` for a group with a single sample, and both require a grouping option. For example, to write the highest within-group distance:

```bash
segul align distance --dir alignments/ --group-delimiter _ --group-fields 1 --diagonal max
```

In the example above, each species has a single within-group pair, so `max` and `mean` are the same. With three or more samples in a group, `max` shows the most divergent pair, while `mean` averages all pairs. Pooled over loci, `max` is the highest within-group distance in any locus.

The diagonal of `<prefix>_group_pairs.csv` always holds the number of within-group pairs.

### Long-format tables

Use the `--long` flag to also write the distances of all loci as one table with a row per sample pair. Long tables are easy to filter and plot in R, Python, or a spreadsheet:

```bash
segul align distance --dir alignments/ --long
```

`<prefix>_pairwise_long.csv` lists each pair of samples once for every locus:

| Column | Description |
| ------ | ----------- |
| `locus` | Locus name |
| `sample_1`, `sample_2` | The two samples |
| `group_1`, `group_2` | The groups of the samples, written only with a grouping option. Empty if a sample matches no group. |
| `compared_sites` | Number of sites compared for the pair |
| `distance` | Pairwise distance, or `NA` if it is undefined |

With a grouping option, `--long` also writes `<prefix>_group_long.csv`. It has one row for each pair of groups in each locus, followed by rows with `all` in the `locus` column for the pooled values:

| Column | Description |
| ------ | ----------- |
| `locus` | Locus name, or `all` for the pooled values |
| `group_1`, `group_2` | The two groups. Within-group rows name the same group twice. |
| `n_pairs` | Number of sample pairs with a defined distance |
| `mean`, `sd` | Mean and sample standard deviation of the distances |
| `min`, `max` | Minimum and maximum distance |

For example, to compute group means by species and write long tables:

```bash
segul align distance --dir alignments/ --group-auto --long
```

The output directory then looks like this:

```plaintext
Align-Distance/
├── distance_group_long.csv
├── distance_group_mean.csv
├── distance_group_pairs.csv
├── distance_pairwise_long.csv
├── distance_summary.csv
├── per_locus/
│   ├── locus_1.csv
│   └── locus_2.csv
└── per_locus_group/
    ├── locus_1.csv
    └── locus_2.csv
```

### Specifying the output directory and prefix

You can change the output directory name using the `--output` or `-o` option. Use the `--prefix` option to change the name of the summary file and the other files in the output directory. For example, the command below writes the summary to `distance-output/k2p_summary.csv`:

```bash
segul align distance --dir alignments/ --model k2p --output distance-output --prefix k2p
```

### More ways to specify input files

You can also specify input files using the `--input` or `-i` option. This option allows you to provide a single alignment file or multiple alignment files using [wildcards](https://en.wikipedia.org/wiki/Wildcard_character). For example:

```bash
segul align distance --input alignments/*.fasta
```

## All options

| Option                  | Description                                                                                   |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with alignments                                                                     |
| `-i`, `--input`         | Alignment files. Allows wildcards                                                             |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                                 |
| `--datatype`            | Data type: `dna` (default) or `aa`                                                            |
| `--model`               | Distance model: `p` (default), `jc69`, `k2p`, `tn93`, or `poisson`                            |
| `--triangle`            | Matrix layout: `full` (default), `lower`, or `upper`                                          |
| `--diagonal`            | Diagonal value: `zero` (default), `blank`, or `na`. With grouping, also `mean` (default) or `max` |
| `--group-delimiter`     | Group samples by splitting names on this character. Use with `--group-fields`                 |
| `--group-fields`        | Number of leading name parts that name the group. Use with `--group-delimiter`                |
| `--group-regex`         | Group samples by the first capture group, or the whole match, of a regular expression         |
| `--group-file`          | Group samples using a CSV or TSV file with a header and sample and group columns              |
| `--group-auto`          | Detect the group delimiter and number of fields from sample names                             |
| `--long`                | Also write pairwise distances, and group statistics with grouping, of all loci as long tables |
| `-o`, `--output`        | Output directory. Default: `Align-Distance`                                                   |
| `--prefix`              | Prefix of the output files. Default: `distance`                                               |
| `--force`               | Overwrite an existing output directory                                                        |
| `--log`                 | Log file path. Default: `segul.log`                                                           |

The grouping options cannot be combined. Use only one of `--group-delimiter` with `--group-fields`, `--group-regex`, `--group-file`, or `--group-auto`.
