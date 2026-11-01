# Release Notes

## Upcoming (in development)

### New Features

- New interface: redesigned home screen with a searchable tool catalog, suggested workflows, new icons, color scheme, and better layouts for phones, tablets, and large screens.
- New tools: genetic distance, alignment trimming, unaligning alignments, MAF conversion and summary, sequence addition, filtering, and transposition.
- Input from folders and archives (`.zip`, `.tar.gz`), with faster loading of large datasets on mobile and files shared from other apps.
- Workbench with a file inspector, run parameters, and next steps that pass output to the next tool.
- Export output as `.zip` or `.tar.gz` archives.
- Alignment viewer for large alignments, with file switching, color modes, zoom, an overview strip, and sequence selection.
- Interactive read report for the Complete read summary, with per-sample charts and adjustable duplication counts.
- Interactive alignment summary report, opened from the workbench after a run: an overview of the dataset with site types, matrix completeness, and character counts, every locus and taxon as bars or a sortable table, and distributions across loci.
- More genetic distance options.

### Improvements

- Updated SEGUL and other dependencies, with native assets builds and Windows arm64 downloads.
- New documentation website with visual guides for each feature.
- Tables from CSV files sort by any column and show a page at a time with the header in place, and columns of numbers show a bar behind each value.
- New **Settings › Colors** page to choose the chart palette (Okabe-Ito, Paul Tol, or ColorBrewer), the heatmap colormap (viridis family or ColorBrewer), the color of table data bars, and the alignment residue colors, each shown as a preview. A live preview shows a chart, heatmap, table, and alignment in the chosen colors, as seen with typical vision or a color vision deficiency, with their weakest contrast.
- Colors come from the SEGUL color library, so charts match SEGUL plots. Chart lines and bar outlines reach 3:1 contrast and text reaches 4.5:1 (WCAG 2.2 AA). Read report heatmaps use the chosen colormap instead of shades of green, and the alignment viewer remembers its color mode.

### Bug Fixes

- Fix Android launch issues.

## v1.1.3

### Bug Fixes

- Fix issue with trailing whitespaces in the sequence IDs.
- Fix menu drawer keeps opening after toggling the hamburger menu.
- Fix window size buttons.

## v1.1.2

- Improve number formatting for tabular data.

## v1.1.1

- Fix empty window help text not displayed properly.

## v1.1.0

### New Features

- Now support viewing large tabular data.

### Bug Fixes

- Fix help text not displayed properly.
- Improve help text description.

## v1.0.1

- Fix contig summary could not find the contig files
- Fix quick action button label improperly displayed

## v1.0.0

- First stable release
