---
title: Genetic Distance
sidebar:
  order: 5
---

Compute pairwise genetic distances between samples for each alignment. The app writes a distance matrix for every alignment and a summary table across all alignments.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Compute genetic distances` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type. The data type must be `DNA` or `AA`.
5. Select the distance model, the matrix layout, and the diagonal value.
6. Select the output directory by clicking the `Add directory` button.
7. Add a prefix for the summary file (optional).
8. Click the `Run` button labeled `Compute` to start the task.

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

## Output

The output directory contains a `per_locus` folder with one distance matrix per alignment, named after the input file, and a `distance_summary.csv` file with one row per alignment. With a prefix, the summary is named `<prefix>_summary.csv`. See the [CLI guide](/docs/cli-usage/align-distance/) for the summary columns.
