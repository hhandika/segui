---
sidebar_position: 6
---

# Alignment Splitting

To split an alignment, you need two input files: the concatenated alignment and the partition file. If you skip inputting partition file, the app will assume the partition is embedded in the alignment file.

The command is as below:

```Bash
segul align split --input <path-to-alignment> --input-partition <path-to-partition-file>
```

For example:

```Bash
segul align split --input concat-alignment.nexus --input-partition concat-alignment-partition.nex
```

## Check Partition for Errors

The command above assume the partition following this rule:

1. The first partition position starts with 1.
2. The next partition is next number after the end of the previous partition. If codon model, it will check the next locus applies the rule.

To skip the partition check, use the `--skip-checking` option:

```Bash
segul align split --input concat-alignment.nexus --input-partition concat-alignment-partition.nex --skip-checking
```

## Supported partition format for splitting alignment

`segul` support two kind of RaXML format:

With datatype written in the partitions:

```Text
DNA, locus_1 = 1-5
DNA, locus_2 = 6-10
```

Or without the datatype:

```Text
locus_1 = 1-5
locus_2 = 6-10
```

For nexus partition:

```Text
#Nexus
begin set
  charset locus_1 = 1-5;
  charset locus_2 = 6-10;
end;
```

`segul` partition parser is robust when dealing with extra spaces, but forbid the use of spaces for the locus names.

This nexus format will work:

```Text
#Nexus
begin set
  charset locus_1 = 1 - 5 ;
  charset locus_2 = 6 - 10 ;
end;
```

But this will not work:

```Text
#Nexus
begin set
  charset 'locus 1' = 1-5;
  charset 'locus 2' = 6-10;
end;
```

Some other programs write locus names with file extension (contain dot). In that case, `segul` will replace it with underscore to avoid name conflict when changing file extension.

For example:

```Text
#Nexus
begin set
  charset locus_1.nex = 1 - 5 ;
  charset locus_2.nex = 6 - 10 ;
end;
```

In this case above, `segul` will write the output file as locus_1_nex.nex and locus_2_nex.nex (if save to nexus).
