---
title: Genetic Distance
sidebar:
  order: 5
---

Compute pairwise genetic distances between samples for each alignment. The app writes a distance matrix for every alignment and a summary table across all alignments. It can also average the distances within and between populations or species.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Compute genetic distances` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type. The data type must be `DNA` or `AA`.
5. Select the distance model, the matrix layout, and the diagonal value.
6. Select how to group samples into populations or species (optional). See [Groups](#groups).
7. Select the output directory by clicking the `Add directory` button.
8. Add a prefix for the output files (optional).
9. Turn on `Long-format tables` to also write the distances of all alignments as one table (optional).
10. Click the `Run` button labeled `Compute` to start the task.

## Example: species means

For samples named `Genus_species_ID`, such as `Rattus_rattus_FMNH1`:

1. In `Group samples`, select `Detect from sample names`, then click `Detect groups`. The app switches to `Split sample names` with `_` as the delimiter and `2` fields to keep, and lists each species with its number of samples.
2. Turn on `Long-format tables` in the output card.
3. Click `Compute`. Open `distance_group_mean.csv` for the mean distances within and between species across all alignments, or `distance_pairwise_long.csv` for every pair of samples.

## Parameters

### Distance model

| Model                    | Data type    |
| ------------------------ | ------------ |
| Uncorrected p-distance   | DNA and AA   |
| Jukes-Cantor (JC69)      | DNA and AA   |
| Kimura 2-parameter (K2P) | DNA only     |
| Tamura-Nei (TN93)        | DNA only     |
| Poisson                  | AA only      |

The app shows an error if the model does not match the data type.

### Matrix

The distance matrix is symmetric, so each value appears twice. Select `Lower triangle` or `Upper triangle` to write only one half, as is common for tables in publications. The default is the full matrix.

### Diagonal

The diagonal holds the distance of each sample to itself. Write `Zero` (the default), leave it `Blank`, or write the `Highest distance in the row`, which is the largest distance from that sample to any other sample.

### Groups

When samples are individuals, group them into populations or species to also compute the mean distance within each group and between each pair of groups. Select a method in `Group samples`:

| Method | Groups by |
| ------ | --------- |
| `No grouping` | Samples are not grouped (the default). |
| `Detect from sample names` | A delimiter and number of fields found from the sample names. |
| `Split sample names` | The first parts of each name split on a `Delimiter`. With `_` and `2` in `Fields to keep`, `Rattus_rattus_FMNH1` belongs to `Rattus_rattus`. |
| `Regular expression` | The first capture group of the pattern, or the whole match if it has no capture group. |
| `Group file (CSV or TSV)` | A `.csv` or `.tsv` file with a header row, followed by one sample and its group per row. |

Click `Preview groups` to check the groups before computing. The preview lists each group with its number of samples, and warns about samples that match no group. These samples are left out of the group means.

With `Detect from sample names`, click `Detect groups`. The app picks the delimiter and number of fields that give the most groups while pooling at least 80% of samples with another sample, so `Genus_species_ID` names are grouped by species. It then switches to `Split sample names` with these values filled in, so you can adjust them. For example, for `Genus_species_population_ID` names, detection gives populations. Change `Fields to keep` to `2` to group by species. See the [CLI guide](/docs/cli-usage/align-distance/#detecting-groups-from-sample-names) for the detection rules.

## Output

The output directory contains a `per_locus` folder with one distance matrix per alignment, named after the input file, and a `distance_summary.csv` file with one row per alignment. With a prefix, the files start with the prefix instead of `distance`, such as `<prefix>_summary.csv`. See the [CLI guide](/docs/cli-usage/align-distance/) for the summary columns.

With groups, the app also writes:

- `per_locus_group/`: one group matrix per alignment. By default, the diagonal holds the mean distance within each group, and the other cells hold the mean between two groups. A within-group mean is `NA` if the group has one sample in the alignment.
- `distance_group_mean.csv`: group means pooled over every sample pair of every alignment, so alignments with more pairs count more.
- `distance_group_pairs.csv`: the number of pairs behind each pooled mean.

The `Matrix` option applies to the group matrices too. The `Diagonal` option sets the sample matrices only. Use `Group matrix diagonal` in the groups card for the group mean matrices:

- `Mean within the group` (default): the mean distance within each group.
- `Zero` or `Blank`: write zero or leave the diagonal empty.
- `Highest mean in the row`: the largest mean distance from the group to any other group. It is `NA` if the group has no defined mean to another group.

With `Zero`, `Blank`, or `Highest mean in the row`, the within-group means are still listed in `distance_group_long.csv` when `Long-format tables` is on. The diagonal of `distance_group_pairs.csv` always holds the number of within-group pairs.

With `Long-format tables` on, the app also writes:

- `distance_pairwise_long.csv`: one row per sample pair per alignment, with the locus, the two samples, their groups (with groups only), the number of compared sites, and the distance.
- `distance_group_long.csv` (with groups only): one row per pair of groups per alignment, with the number of pairs, mean, standard deviation, minimum, and maximum. Rows with `all` as the locus hold the pooled values.

See the [CLI guide](/docs/cli-usage/align-distance/#long-format-tables) for all columns.
