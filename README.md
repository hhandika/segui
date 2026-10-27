# SEGUI <img src="https://raw.githubusercontent.com/hhandika/segui/main/assets/launcher/iconDesktop.png" alt="segul logo" align="right" width="150"/>

![Segui-Tests](https://github.com/hhandika/segui/workflows/test/badge.svg)

<!-- ![GH-Downloads](https://img.shields.io/github/downloads/hhandika/segui/total?color=blue&label=gh-release-downloads) -->

![last-commit](https://img.shields.io/github/last-commit/hhandika/segui)
![License](https://img.shields.io/github/license/hhandika/segui)

A GUI version of [segul](https://github.com/hhandika/segul), an ultrafast, memory-efficient application for phylogenomic data manipulation and sequence summary statistics. It performs similarly to the CLI version of the app with the convenience of GUI while still retaining reproducibility through logging support. The GUI version will also support iOS, iPadOS and Android, and macOS, Windows, and Linux.

## Installation

### Desktop

[<img style="padding-left: 15" alt="Microsoft Store download" src="https://get.microsoft.com/images/en-us%20dark.svg" width="200" />](https://apps.microsoft.com/detail/SEGUI/9NP1BQ6FW9PW?mode=direct)

[<img
    style="padding: 15"
    src="https://tools.applemediaservices.com/api/badges/download-on-the-mac-app-store/black/en-us?size=250x83&amp;releaseDate=1716076800"
    alt="Download on the Mac App Store"
    width="220"
  />](https://apps.apple.com/us/app/segui/id6447999874?mt=12&itsct=apps_box_badge&itscg=30200)

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/segui)

### Mobile

[<img style="padding-left: 15" src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1716076800" alt="Download on the App Store" width="180">](https://apps.apple.com/us/app/segui/id6447999874?itsct=apps_box_badge&itscg=30200)

[<img
    alt="Get it on Google Play"
    src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
    height="80"
  />](https://play.google.com/store/apps/details?id=com.hhandika.segui&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1)

Learn more about device requirements and GUI app installation in the [documentation](https://www.segul.app/docs/installation/install_gui/).

## Coming Soon: SEGUI with SEGUL v0.24.0

> [!NOTE]
> This update is not released yet. The current app store versions do not include these features.

The next release updates SEGUI to SEGUL v0.24.0 and redesigns the app.

New tools:

- **Alignment distance**: pairwise genetic distances for each alignment, with optional averages within and between populations or species.
- **Alignment trimming**: remove sites by the proportion of missing data or by parsimony informative sites.
- **Alignment unaligning**: remove gaps to produce unaligned sequence files.
- **MAF conversion and summary**: convert whole-genome Multiple Alignment Format (MAF) blocks to FASTA, NEXUS, or PHYLIP alignments, and summarize MAF files before converting them.
- **Sequence addition**: add sequences from many source files to matching destination files.
- **Sequence filtering**: remove individual sequences by length or proportion of gaps (previously CLI only).
- **Sequence transposition**: turn locus alignments into per-sample sequence files.

App improvements:

- An alignment viewer that handles large alignments, plus a file inspector.
- A workbench that suggests the next tool to run on a task's output.
- Multi-file input with a directory tree view.
- Output export as ZIP or `.tar.gz` archives.
- A redesigned home screen, tool layout, and icons, with better support for phones and tablets.

## Quick Links

| Feature                        | Quick Link                                                                                                                        |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Alignment concatenation        | [CLI](https://www.segul.app/docs/cli-usage/align-concat/) / [GUI](https://www.segul.app/docs/gui-usage/align-concat/)             |
| Alignment conversion           | [CLI](https://www.segul.app/docs/cli-usage/align-convert/) / [GUI](https://www.segul.app/docs/gui-usage/align-convert/)           |
| Alignment distance             | [CLI](https://www.segul.app/docs/cli-usage/align-distance/) / [GUI](https://www.segul.app/docs/gui-usage/align-distance/)         |
| Alignment filtering            | [CLI](https://www.segul.app/docs/cli-usage/align-filter/) / [GUI](https://www.segul.app/docs/gui-usage/align-filter/)             |
| Alignment splitting            | [CLI](https://www.segul.app/docs/cli-usage/align-split/) / [GUI](https://www.segul.app/docs/gui-usage/align-split/)               |
| Alignment partition conversion | [CLI](https://www.segul.app/docs/cli-usage/align-partition/) / [GUI](https://www.segul.app/docs/gui-usage/align-partition/)       |
| Alignment summary statistics   | [CLI](https://www.segul.app/docs/cli-usage/align-summary/) / [GUI](https://www.segul.app/docs/gui-usage/align-summary/)           |
| Alignment trimming             | [CLI](https://www.segul.app/docs/cli-usage/align-trim/) / [GUI](https://www.segul.app/docs/gui-usage/align-trim/)                 |
| Alignment unaligning           | [CLI](https://www.segul.app/docs/cli-usage/align-unalign/) / [GUI](https://www.segul.app/docs/gui-usage/align-unalign/)           |
| Genomic read summary           | [CLI](https://www.segul.app/docs/cli-usage/read-summary/) / [GUI](https://www.segul.app/docs/gui-usage/read-summary/)             |
| Genomic contig summary         | [CLI](https://www.segul.app/docs/cli-usage/contig-summary/) / [GUI](https://www.segul.app/docs/gui-usage/contig-summary/)         |
| MAF conversion                 | [CLI](https://www.segul.app/docs/cli-usage/maf-convert/) / [GUI](https://www.segul.app/docs/gui-usage/maf-convert/)               |
| MAF summary statistics         | [CLI](https://www.segul.app/docs/cli-usage/maf-summary/) / [GUI](https://www.segul.app/docs/gui-usage/maf-summary/)               |
| Sequence addition              | [CLI](https://www.segul.app/docs/cli-usage/sequence-add/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-add/)             |
| Sequence extraction            | [CLI](https://www.segul.app/docs/cli-usage/sequence-extract/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-extract/)     |
| Sequence filtering             | [CLI](https://www.segul.app/docs/cli-usage/sequence-filter/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-filter/)       |
| Sequence ID extraction         | [CLI](https://www.segul.app/docs/cli-usage/sequence-id/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-id/)               |
| Sequence ID mapping            | [CLI](https://www.segul.app/docs/cli-usage/sequence-map/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-id-map/)          |
| Sequence ID renaming           | [CLI](https://www.segul.app/docs/cli-usage/sequence-rename/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-rename/)       |
| Sequence removal               | [CLI](https://www.segul.app/docs/cli-usage/sequence-remove/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-remove/)       |
| Sequence translation           | [CLI](https://www.segul.app/docs/cli-usage/sequence-translate/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-translate/) |
| Sequence transposition         | [CLI](https://www.segul.app/docs/cli-usage/sequence-transpose/) / [GUI](https://www.segul.app/docs/gui-usage/sequence-transpose/) |
