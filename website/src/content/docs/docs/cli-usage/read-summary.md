---
title: Genomic Read Summary
sidebar:
  order: 11
---

`segul read summary` calculates summary statistics for raw sequence reads in FASTQ format. For assembled contigs, see [Genomic Contig Summary](/docs/cli-usage/contig-summary/).

## Input formats

- Gunzip Compressed FASTQ (.fq.gz/.fastq.gz), including BGZF
- Standard FASTQ (.fq/.fastq)

SEGUL detects the compression from the file content. Each file is read once and summarized on all CPU cores, and BGZF files are also decompressed in parallel.

## Usage

```bash
segul read summary -i raw_reads.fq.gz
```

or using directory input:

```bash
segul read summary -d /raw_read_dir
```

The output file will be saved as `default-read-summary.csv` in `Read-Summary` directory.

To specify the output directory, use the `--output` or `-o` argument:

```bash
segul read summary -d /raw_read_dir -o read_dir_output
```

You can also use the `--prefix` argument to specify the prefix name of the output files:

```bash
segul read summary -d /raw_read_dir -o read_dir_output --prefix my_read_summary
```

## Summary modes

SEGUL provides three modes to calculate summary statistics for raw reads:

- **Minimal**: read count only
- **Default**: generate essential statistics (see below)
- **Complete**: generate all the essential statistics plus statistics per read position, distributions, duplication, overrepresented sequences, and adapter content (see below).

Use the `--mode` option to choose `minimal`, `default`, or `complete`:

```bash
segul read summary -d /raw_read_dir --mode complete
```

## Statistics

Essential statistics for raw reads:

- Number of reads
- Number of bases
- Mean read length
- Minimum read length
- Maximum read length
- GC count
- GC content
- AT count
- AT content
- A, C, G, T, N count
- Low-quality base count
- Mean base quality
- Min base quality
- Max base quality
- Median, standard deviation, and N50 of read length
- Bases with quality 20 or higher (Q20) and 30 or higher (Q30)
- Mean quality per read, and reads with mean quality below 20
- Quality score offset (Phred+33 or Phred+64)

Complete mode adds:

- Quality quartiles, 10th and 90th percentiles, and base composition, including N, at each read position (`read-pos-summary.zip`)
- Read length, mean read quality, and GC content distributions, with the theoretical GC distribution (`read-dist-summary.zip`)
- Duplication across every read of each file, with the number of copies of each sequence (see below)
- Overrepresented sequences, above 0.1% of all reads, with the adapter they match. Reads longer than 75 bp are compared by their first 50 bp, like FastQC
- Adapter content by position for Illumina Universal, Nextera, Illumina Small RNA, poly-A, and poly-G
- All of the above in `read-report.json`, which SEGUI opens as an interactive report

## Duplication

SEGUL compares the full sequence of every read in the file. FastQC, by comparison, follows only the first 100,000 distinct sequences, so long or sorted files can be misjudged. Counting every distinct sequence of a large file exactly takes a lot of memory, so by default SEGUL keeps a uniform sample of 100,000 distinct sequences and counts their copies across all reads. The duplicate share is estimated from this sample with an error of about 0.3% of the distinct sequences, and the levels chart uses the sample's exact copy counts. Files with fewer distinct sequences are counted exactly. The sample uses about 30 bytes per sequence, so the default takes about 3 MB per file.

Use `--dup-sketch-size` to change the sample size. Larger samples are more accurate, and `0` counts every distinct sequence exactly:

```bash
segul read summary -d /raw_read_dir --mode complete --dup-sketch-size 1000000
```

The duplication results are the same with any number of threads. Overrepresented sequences are found among all reads, and their counts can be short by up to 0.025% of reads in files with many distinct sequences, which `read-report.json` lists as `max_error_pct`.

## Quality score offset

SEGUL detects the quality score offset from the first reads. Use `--phred 33` or `--phred 64` to set it.

## Charts

Add `--plot` to also write charts to `<OUTPUT>/plots`. Complete mode adds charts of quality by position (`pos-qscore-box_<sample>`), read length (`length-dist`), mean read quality (`read-qscore-dist`), GC content (`gc-dist_<sample>`), N content (`pos-n-content`), adapter content (`adapter-content_<sample>`), and duplication (`duplication_<sample>`):

```bash
segul read summary -d /raw_read_dir --mode complete --plot
```

## All options

| Option                 | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| `-d`, `--dir`          | Directory with FASTQ files                                     |
| `-i`, `--input`        | FASTQ files. Allows wildcards                                  |
| `-f`, `--input-format` | Input format: `auto` (default), `fastq`, or `gzip`             |
| `--mode`               | Summary mode: `default` (default), `minimal`, or `complete`    |
| `--phred`              | Quality score offset: `auto` (default), `33`, or `64`          |
| `--dup-sketch-size`    | Distinct sequences kept to estimate duplication. Default: `100000`. `0` counts all |
| `-o`, `--output`       | Output directory. Default: `Read-Summary`                      |
| `--prefix`             | Prefix of the output files                                     |
| `--force`              | Overwrite an existing output directory                         |
| `--log`                | Log file path. Default: `segul.log`                            |
