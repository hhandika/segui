---
sidebar_position: 2
---

# CLI vs GUI

## Which version should I use?

If your answer is yes to any of the following questions, you should use the CLI version of the app. otherwise, either GUI or CLI will serve your need.

1. Are you planning to run the app on a High-Performance Computing (HPC) cluster or Linux system?
2. Do you run SEGUL as part of a pipeline?
3. Do you you need the utmost efficiency?

## Performance

The CLI version is faster than the GUI version. The CLI version is also more memory efficient. The GUI version is more user-friendly and easier to use.

## Features

The CLI version has more features than the GUI version.

Specifically, the CLI version has the following features that are not available in the GUI version:

### Alignment filtering

The GUI version only can filter based on a single percentage of minimum number of taxa. The CLI version allows to filter using a single or multiple percentage values. For example, if you want to filter out alignment with less than 50% of taxa, you can use the following command:

```bash
segul align filter -d <input-directory> --percent 50
```

You can also filter out alignment with multiple values. For example, if you want to filter out alignment with less than 50% and 75% of taxa, you can use the following command:

```bash
segul align filter -d <input-directory> --npercent 50 75
```

The app will output the alignments for each filtering options. In the GUI version, the latter will need to be done in two steps. First, filter out alignment with less than 50% of taxa. Then, filter out alignment with less than 75% of taxa.
