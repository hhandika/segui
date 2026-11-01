---
title: Alignment Partition Conversion
sidebar:
  order: 6
---

SEGUL CLI can convert single and multiple partition files. It can also extract partitions embedded in NEXUS sequence files.

```bash
segul partition convert --input <a-path/wildcard-to-partition> --input-partition <input-partition-format> --output-partition <output-partition-format>
```

If you output to RaXML partition and it is a DNA sequence, we recommend using the `--datatype dna` option. The partition format will include the datatype as below:

```text
DNA, locus_1 = 1-100
DNA, locus_2 = 101-150
DNA, locus_3 = 151-200
```

By default, `segul` checks the partition format:

1. The first partition position starts with 1.
2. The next partition is the next number after the previous partition's end. If using the codon model, the next locus applies the rule.

Passing the `--skip-checking` flag allows you to ignore format checking. For example, to extract nexus in-file partitions (called charset format in `segul`):

```bash
segul partition convert --input concatenated_alignment.nex --input-partition charset --output-partition nexus
```

You can also use wildcard to convert multiple concatenated alignment partitions at once:

```bash
segul partition convert --input ./*/concatenated_alignment.nex --input-partition charset --output-partition nexus
```

By default, SEGUL will save the resulting partitions in the parent directory of the input partition (or alignment if the partition is charset).

## All options

| Option                     | Description                                                                         |
| -------------------------- | ----------------------------------------------------------------------------------- |
| `-i`, `--input`            | Partition files, or alignments with an embedded partition. Allows wildcards         |
| `-p`, `--input-partition`  | Input partition format: `charset`, `nexus`, or `raxml`                              |
| `-P`, `--output-partition` | Output partition format: `nexus` (default), `charset`, or `raxml`                   |
| `--codon`                  | Write the partition as a codon model                                                |
| `--datatype`               | Data type: `dna` (default), `aa`, or `ignore`. Sets the RAxML datatype label        |
| `--skip-checking`          | Skip checking the partition positions                                               |
| `-f`, `--input-format`     | Format of an alignment with an embedded partition: `auto` (default), `fasta`, `nexus`, or `phylip` |
| `-F`, `--output-format`    | Output sequence format: `nexus` (default), `phylip`, `fasta`, `nexus-int`, `phylip-int`, or `fasta-int` |
| `-o`, `--output`           | Output directory. Default: `Partition-Convert`                                      |
| `--force`                  | Overwrite an existing output directory                                              |
| `--log`                    | Log file path. Default: `segul.log`                                                 |
