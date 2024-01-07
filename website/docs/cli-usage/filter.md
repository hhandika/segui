---
sidebar_position: 4
---

# Alignments Filtering

`segul` provides multiple ways to filter alignments:

1. Based on alignment length
2. Based on the data matrix completeness.
3. Based on parsimony informative sites.

In its simplest form, the command is structure as below:

```Bash
segul <input-option> [alignment-path] <filtering-options>
```

> IMPORTANT NOTES: `segul` will never overwrite your original datasets. When filtering alignments, it will copy the alignments that match the filtering parameters to its output directory. You can also concat the resulting alignments instead. It is particularly useful to quickly estimate a species tree based on the filtered alignments.

## Filtering based on the minimal alignment length

To filter based on the alignment length (also refer to number of sites), we will use the `--len` option. For example, our directory below contains three alignments:

```Bash
alignments/
├── locus_1.nexus
├── locus_2.nexus
└── locus_3.nexus
```

We would like to filter an alignment with minimal alignment length 500 bp. `segul` command using `--dir` input as below:

```Bash
segul --dir alignments/ --input-format nexus --len 500
```

We can achieve the same result using `--input` or `-i` option:

```Bash
segul --input alignments/*.nexus --len 500
```

## Filtering based on data matrix completeness

This filtering method is based on the percentage of minimal taxa present in your alignments, similar to `phyluce_align_get_only_loci_with_min_taxa` in [Phyluce pipeline](https://phyluce.readthedocs.io/en/latest/tutorials/tutorial-1.html#final-data-matrices). For example, given a collection of alignments with 100 taxa with 90 percent completeness, `segul` will filter alignments with at least containing 90 taxa.

To filter alignments based on data matrix completeness, we use `--percent` option with input in decimals. For example, here we will filter alignments in `alignments` directory with 80 percent data matrix completeness:

```Bash
segul --dir alignments/ --input-format nexus --percent 0.8
```

You can also write the percentage as `.8`, it will parse the same way as you write it with 0.

Sometimes, we want to try building phylogenetic trees with different data matrix completeness. Using `segul`, we can filter with multiple data matrix completeness values in a single commands. For this task, we use `npercent` option:

```Bash
segul --dir segul --dir alignments/ --input-format nexus --npercent .9 .8 .75
```

`segul` will create an output directory for each data matrix completeness value. The output directory names will be suffixed with the percentage values. For the example above, it will create three directories named `alignments_90p`, `alignments_80p`, and `alignments_75p`.

## Filtering based on parsimony informative sites

`segul` provides two ways in filtering based on parsimony informative sites. First, by inputing the minimal number of parsimony informative sites using the `--pinf` option. It will filter alignments that at least contains the input number of parsimony informative sites.

For example, in the command below, we will filter alignments in `alignments` directory with minimal contain 50 parsimony informative sites:

```Bash
segul filter --dir alignments/ --input-format nexus --pinf 50
```

Second, we can filter based on the percentage of minimal parsimony informative sites. This value is counted based on the highest number of parsimony informative sites in your alignments. It is similar to computing data matrix completeness, but based on the number of parsimony informative sites.

For example, the highest number of parsinomy informative sites in the input alignments is 100. We will filter with minimal 80 percent of the highest parsimony informative value. Using `--percent-inf .8` option, `segul` will filter an alignments with at least containing 80 parsimony informative sites:

```Bash
segul filter --dir alignments/ --input-format nexus --percent-inf .8
```

## Specifying output directories

By default, `segul` output directories for filtering are based on the input directory names suffixed with filtering values. The format as below:

```Text
[input-dir](underscore)[filtering-values]
```

For example, if your input directory is named `alignments/` and the filtering option is minimal alignment length of 500 bp, the output directory will be `alignments_500bp`.

You can change the prefix names using `--output` or `-o` option.

## Concatenating the results

By defaults, `segul` copy the alignments that match the filtering option. Instead of copying the files, you can concat them by using `--concat` flag. All of the options available for the `concat` subcommand are also available for this task ([see above](./filter#concatenating-alignments)). You are, however, are required to specify the `--output` or `-o` name and the partition format `--part` or `-p` option. The output name will be used as the name of the output directory, the name of the concatenated alignment, and the prefix name for the partition setting file (if set for `raxml` or `nexus`).

For example, in the command below, we will filter based on alignment length of 500 bp and will concat the result:

```Bash
segul --dir alignments/ --input-format nexus --len 500 --concat --part raxml -output concat_alignment
```
