---
sidebar_position: 5
---

# Alignment Filtering

SEGUL provides multiple ways to filter alignments:

1. Based on alignment length
2. Based on the data matrix completeness.
3. Based on parsimony informative sites.

In its simplest form, the command is structured as below:

```Bash
segul align filter <input-option> [alignment-path] <filtering-options>
```

:::info
SEGUL will never overwrite your original datasets. It will copy the alignments that match the filtering parameters to its output directory when filtering alignments. You can also concatenate the resulting alignments instead. It is particularly useful to estimate a species tree quickly based on the filtered alignments.
:::

## Filtering based on the minimal alignment length

To filter based on the alignment length (also refer to number of sites), we will use the `--len` option. For example, our directory below contains three alignments:

```Bash
alignments/
├── locus_1.nexus
├── locus_2.nexus
└── locus_3.nexus
```

We want to filter an alignment with a minimal length of 500 bp. Use `segul` command using `--dir` input as below:

```Bash
segul align filter --dir alignments/ --len 500
```

We can achieve the same result using the `--input` or `-i` option:

```Bash
segul align filter --input alignments/*.nexus --len 500
```

## Filtering based on data matrix completeness

This filtering method is based on the percentage of minimal taxa present in your alignments, similar to `phyluce_align_get_only_loci_with_min_taxa` in [Phyluce pipeline](https://phyluce.readthedocs.io/en/latest/tutorials/tutorial-1.html#final-data-matrices). For example, given a collection of alignments with 100 taxa with 90 percent completeness, SEGUL will filter alignments containing at least 90 taxa.

We use the `--percent` option with input in decimals to filter alignments based on data matrix completeness. For example, here we will filter alignments in the `alignments` directory with 80 percent data matrix completeness:

```Bash
segul align filter --dir alignments/ --input-format nexus --percent 0.8
```

You can also write the percentage as `.8`, and it will parse the same way you write it with 0.

Sometimes, we want to build phylogenetic trees with different data matrix completeness. Using `segul`, we can filter with multiple data matrix completeness values in a single command. For this task, we use `npercent` option:

```Bash
segul align filter --dir segul --dir alignments/ --input-format nexus --npercent .9 .8 .75
```

SEGUL will create an output directory for each data matrix completeness value, with the percentage values suffixed on the directory names. For the example above, it will create three directories named `alignments_90p`, `alignments_80p`, and `alignments_75p`.

## Filtering based on parsimony informative sites

SEGUL provides two ways of filtering based on parsimony informative sites:

1. Based on the minimum input values of informative sites

We use the `--pinf` option to input the number of informative sites. This option filters alignments that contain at least that number of informative sites.

For example, in the command below, we will filter alignments in the `alignments` directory with a minimum containing 50 parsimony informative sites:

```Bash
segul align filter --dir alignments/ --input-format nexus --pinf 50
```

2. Based on the percentage of minimal parsimony informative sites

This value is counted based on the highest number of informative sites on your alignments. It is similar to computing data matrix completeness but based on the number of informative sites. You only need to input the percentage value. SEGUL will determine the highest number of informative sites across all input alignments.

For example, the highest number of informative sites in the input alignments is 100. We will filter with a minimal 80 percent of the highest parsimony informative value. Using `--percent-inf .8` option, SEGUL will filter alignments with at least containing 80 parsimony informative sites:

```Bash
segul align filter --dir alignments/ --percent-inf .8
```

## Specifying output directories

By default, SEGUL output directories for filtering are based on the input directory names suffixed with filtering values. The format is as follows:

```Text
[input-dir](underscore)[filtering-values]
```

For example, if your input directory is named `alignments/` and the filtering option is a minimal alignment length of 500 bp, the output directory will be `alignments_500bp`.

You can change the prefix names using `--output` or `-o` option.

## Concatenating the results

By default, SEGUL copies the alignments that match the filtering option. Instead of copying the files, you can concatenate them using the `--concat` flag. All options for the [`align concat`](./concat) subcommand are available for this task. You are, however, required to specify the `--output` or `-o` name and the partition format `--part` or `-p` option.

For example, in the command below, we will filter based on alignments with a length of 500 bp and will concat the result:

```Bash
segul align filter --dir alignments/ --input-format nexus --len 500 --concat --part raxml -output concat_alignment
```
