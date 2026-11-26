# Release Notes

## Unreleased

### New Features

- Search GenBank and ENA from tools that read unaligned sequences, reads, or assemblies, and add the records as input. Downloads run in parallel, check free storage first, and have their own settings page.
- Contig summary report with charts and tables.
- Read summary reports compare all samples in one run.

### Improvements

- The alignment viewer shows the partitions of concatenated alignments as a track above the ruler, lists them beside the grid, and steps between them.
- Data usage shows storage by data type, with a searchable file tree and multi-select.
- Read reports show only the adapters found in the data.
- Report table columns can be resized.
- Workflows note that some steps may need tools outside SEGUI.

### Bug Fixes

- Fix the run button staying disabled after filling required fields.
- Fix overflow in settings and navigation on narrow screens.

## v1.2.1 - 2026-11-11

### Improvements

- Add progress bar for file copying and archive extraction in the mobile app.

### Bug Fixes

- Fix a bug where OS navigation buttons were covering the viewers.

## v1.2.0 - 2026-11-10

### New Features

- Redesigned interface: a searchable tool catalog, suggested workflows, new icons and colors, and layouts for phones, tablets, and large screens.
- New tools: genetic distance, alignment trimming and unaligning, MAF conversion and summary, and sequence addition, filtering, and transposition.
- Input from folders and archives (`.zip`, `.tar.gz`), with faster loading on mobile and files shared from other apps.
- Workbench with a file inspector, run parameters, and next steps that pass output to the next tool.
- Export output as `.zip` or `.tar.gz` archives.
- Alignment viewer for large alignments, with file switching, color modes, zoom, an overview strip, and sequence selection.
- Interactive reports for read summaries, alignment summaries, and genetic distances, with charts, sortable tables, and heatmaps.

### Improvements

- Updated SEGUL and other dependencies, with native assets builds and Windows arm64 downloads.
- New documentation website with visual guides for each feature.
- CSV tables sort by any column, page through rows, and show bars behind numbers.
- New **Settings › Colors** page for chart, heatmap, table, and alignment colors. Charts default to ColorBrewer Dark2 and meet WCAG 2.2 AA contrast.

### Bug Fixes

- Fix Android launch issues.

## v1.1.3 - 2026-08-31

### Bug Fixes

- Fix issue with trailing whitespaces in the sequence IDs.
- Fix menu drawer keeps opening after toggling the hamburger menu.
- Fix window size buttons.

## v1.1.2 - 2024-05-18

- Improve number formatting for tabular data.

## v1.1.1

- Fix empty window help text not displayed properly.

## v1.1.0 - 2024-05-13

### New Features

- Now support viewing large tabular data.

### Bug Fixes

- Fix help text not displayed properly.
- Improve help text description.

## v1.0.1 - 2024-05-13

- Fix contig summary could not find the contig files
- Fix quick action button label improperly displayed

## v1.0.0 - 2024-05-10

- First stable release
