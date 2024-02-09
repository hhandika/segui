---
sidebar_position: 11
---

# Sequence ID Mapping

To map the distribution of samples across a dataset.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Extract and map sequence IDs` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the output directory by clicking the `Add directory` button.
5. Add prefix for the output files.
6. Click `Map sequence IDs` button (**important**).
7. Click the `Run` button labeled `Extract` to start the task.

## Output

The app will generate two files:

- **Unique IDs**: A list of unique IDs in your dataset (default name: `id.txt`).
- **ID Map**: A csv file containing the distribution of your samples presented in TRUE/FALSE values across your alignments (default name: `id_map.txt`)

ID map file will look like as below:

| Alignments | sequence_1 | sequence_2 | sequence_3 |
| ---------- | ---------- | ---------- | ---------- |
| locus_1    | TRUE       | FALSE      | TRUE       |
| locus_2    | TRUE       | TRUE       | TRUE       |
| locus_3    | FALSE      | FALSE      | TRUE       |
