import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/alignment_report/items.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/layout.dart';
import 'package:segui/services/providers/alignment_report.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/src/rust/api/alignment_report.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

String _count(double value) => _countFormat.format(value);

String _percent(double value) => value.toStringAsFixed(1);

/// Interactive report for `alignment-report.json`.
class AlignmentReportView extends StatelessWidget {
  const AlignmentReportView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [InfoButton(file: file)],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: AlignmentReportBody(path: file.path),
    );
  }
}

class AlignmentReportBody extends ConsumerWidget {
  const AlignmentReportBody({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(alignReportProvider(path)).when(
          data: (report) => AlignmentReportContent(report: report),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyScreen(
            title: 'Failed to read the report.',
            description: error.toString(),
          ),
        );
  }
}

/// The report in tabs: an overview of the dataset, every locus and taxon,
/// and distributions across loci.
class AlignmentReportContent extends StatefulWidget {
  const AlignmentReportContent({super.key, required this.report});

  final AlignReportData report;

  @override
  State<AlignmentReportContent> createState() => _AlignmentReportContentState();
}

class _AlignmentReportContentState extends State<AlignmentReportContent> {
  int _openLocus = 0;
  int _openTaxon = 0;

  @override
  void didUpdateWidget(covariant AlignmentReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report) {
      _openLocus = 0;
      _openTaxon = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AlignReportData report = widget.report;
    if (report.loci.names.isEmpty) {
      return const EmptyScreen(
        title: 'No loci in this report.',
        description: 'The summary found no alignments to report.',
      );
    }
    final List<ReportTab> tabs = _tabs(report);
    return Padding(
      padding: reportPadding(context),
      child: DefaultTabController(
        length: tabs.length,
        child: OutlinedPanel(child: ReportTabView(tabs: tabs)),
      ),
    );
  }

  List<ReportTab> _tabs(AlignReportData report) {
    final AlignLociData loci = report.loci;
    final AlignTaxaData taxa = report.taxa;
    return [
      ReportTab(label: 'Overview', sections: _overview(report)),
      ReportTab(label: 'Loci', sections: [
        ReportSection(
          title: 'Loci',
          description: 'Every alignment in the summary. Select one to see '
              'all its values.',
          fill: true,
          child: ReportItemPanel(
            names: loci.names,
            metrics: lociMetrics(loci),
            nameLabel: 'Locus',
            open: _openLocus.clamp(0, loci.names.length - 1),
            onSelected: (i) => setState(() => _openLocus = i),
          ),
        ),
      ]),
      ReportTab(label: 'Taxa', sections: [
        ReportSection(
          title: 'Taxa',
          description: 'Every taxon across the alignments. Select one to '
              'see all its values.',
          fill: true,
          child: taxa.names.isEmpty
              ? const ChartPlaceholder(message: 'No taxa in this report.')
              : ReportItemPanel(
                  names: taxa.names,
                  metrics: taxaMetrics(taxa),
                  nameLabel: 'Taxon',
                  open: _openTaxon.clamp(0, taxa.names.length - 1),
                  onSelected: (i) => setState(() => _openTaxon = i),
                ),
        ),
      ]),
      ReportTab(label: 'Distributions', sections: _distributions(report)),
    ];
  }

  List<ReportSection> _overview(AlignReportData report) {
    final AlignOverviewData s = report.summary;
    final List<(String, SiteTypeData)> siteTypes = [
      ('Conserved', s.conserved),
      ('Variable', s.variable),
      ('Parsimony informative', s.informative),
    ];
    return [
      ReportSection(
        title: 'Dataset',
        child: StatTileGrid(
          children: [
            StatTile(label: 'Taxa', value: _count(s.taxa)),
            StatTile(label: 'Loci', value: _count(s.loci)),
            StatTile(label: 'Sites', value: _count(s.sites)),
            StatTile(
              label: 'Missing data',
              value: '${_percent(100 * s.propMissing)}%',
              detail: '${_count(s.missing)} characters',
            ),
            if (s.gc != null)
              StatTile(label: 'GC content', value: '${_percent(100 * s.gc!)}%'),
            StatTile(
              label: 'Locus length',
              value: _count(s.meanSites.roundToDouble()),
              detail: 'mean, ${_count(s.minSites)}-${_count(s.maxSites)}',
            ),
            StatTile(
              label: 'Taxa per locus',
              value: s.meanTaxa.toStringAsFixed(1),
              detail: 'mean, ${_count(s.minTaxa)}-${_count(s.maxTaxa)}',
            ),
          ],
        ),
      ),
      ReportSection(
        title: 'Site types',
        description: 'Share of all sites of each type, and of loci that are '
            'fully conserved or have any variable or informative site.',
        header: StatTileGrid(
          children: [
            for (final (String name, SiteTypeData sites) in siteTypes)
              StatTile(
                label: name,
                value: _count(sites.sites),
                detail:
                    '${_count(sites.loci)} loci${name == 'Conserved' ? ' fully conserved' : ''}\n'
                    '${_count(sites.min)}-${_count(sites.max)} per locus',
              ),
          ],
        ),
        child: ReadBarChart(
          xLabel: 'Site type',
          yLabel: 'Share (%)',
          categories: [for (final (String name, _) in siteTypes) name],
          series: [
            BarSeries(
              name: 'Sites (%)',
              values: [
                for (final (_, SiteTypeData sites) in siteTypes)
                  100 * sites.propSites,
              ],
              color: SeguiColors.of(context).seriesAt(0),
            ),
            BarSeries(
              name: 'Loci (%)',
              values: [
                for (final (_, SiteTypeData sites) in siteTypes)
                  100 * sites.propLoci,
              ],
              color: SeguiColors.of(context).seriesAt(1),
            ),
          ],
        ),
      ),
      ReportSection(
        title: 'Matrix completeness',
        description: 'Loci that include at least each share of the '
            '${_count(s.taxa)} taxa.',
        child: ReadBarChart(
          xLabel: 'Taxa present (at least)',
          barWidth: SeguiChartLayout.wideBarWidth,
          yLabel: 'Loci',
          categories: [
            for (final double percent in report.completenessPercent)
              '${percent.toInt()}%',
          ],
          series: [
            BarSeries(
              name: 'Loci',
              values: report.completenessLoci,
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      ),
      ReportSection(
        title: 'Characters',
        description: 'Count of each character across all alignments, '
            'including gaps (-) and missing data (?).',
        child: ReadBarChart(
          xLabel: 'Character',
          barWidth: SeguiChartLayout.wideBarWidth,
          yLabel: 'Count',
          categories: [
            for (final String c in report.charNames) characterLabel(c)
          ],
          series: [
            BarSeries(
              name: 'Characters',
              values: report.charCounts,
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      ),
    ];
  }

  List<ReportSection> _distributions(AlignReportData report) {
    final AlignLociData loci = report.loci;
    final List<double> lociMissing = [
      for (final double v in loci.propMissing) 100 * v,
    ];
    final List<double> taxaMissing = [
      for (final double v in report.taxa.propMissing) 100 * v,
    ];
    ReportSection histogram(
      String title,
      String xLabel,
      String unit,
      List<double> values,
      String Function(double value) format,
    ) {
      final Histogram bins = Histogram.of(values);
      return ReportSection(
        title: title,
        description: 'Median ${format(medianOf(values))} across '
            '${_count(values.length.toDouble())} $unit.',
        child: ReadBarChart(
          xLabel: xLabel,
          barWidth: SeguiChartLayout.wideBarWidth,
          yLabel: unit[0].toUpperCase() + unit.substring(1),
          categories: bins.labels,
          series: [
            BarSeries(
              name: unit[0].toUpperCase() + unit.substring(1),
              values: bins.counts,
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      );
    }

    return [
      histogram('Locus length', 'Sites', 'loci', loci.sites, _count),
      histogram('Taxa per locus', 'Taxa', 'loci', loci.ntax, _count),
      histogram(
        'Parsimony informative sites',
        'Informative sites',
        'loci',
        loci.informative,
        _count,
      ),
      histogram(
        'Missing data per locus',
        'Missing data (%)',
        'loci',
        lociMissing,
        (v) => '${_percent(v)}%',
      ),
      if (taxaMissing.isNotEmpty)
        histogram(
          'Missing data per taxon',
          'Missing data (%)',
          'taxa',
          taxaMissing,
          (v) => '${_percent(v)}%',
        ),
    ];
  }
}

/// Columns of the loci table, and the metrics their bars can show.
List<ReportMetric> lociMetrics(AlignLociData loci) {
  final List<double>? gc = loci.gc;
  return [
    ReportMetric(label: 'Taxa', values: loci.ntax, format: _count, width: 100),
    ReportMetric(label: 'Sites', values: loci.sites, format: _count),
    ReportMetric(label: 'Conserved', values: loci.conserved, format: _count),
    ReportMetric(label: 'Variable', values: loci.variable, format: _count),
    ReportMetric(
      label: 'Informative',
      values: loci.informative,
      format: _count,
    ),
    ReportMetric(
      label: 'Missing (%)',
      values: [for (final double v in loci.propMissing) 100 * v],
      format: _percent,
    ),
    if (gc != null)
      ReportMetric(
        label: 'GC (%)',
        values: [for (final double v in gc) 100 * v],
        format: _percent,
        width: 110,
      ),
  ];
}

/// Columns of the taxa table, and the metrics their bars can show.
List<ReportMetric> taxaMetrics(AlignTaxaData taxa) {
  final List<double>? gc = taxa.gc;
  return [
    ReportMetric(label: 'Loci', values: taxa.loci, format: _count, width: 100),
    ReportMetric(label: 'Characters', values: taxa.chars, format: _count),
    ReportMetric(label: 'Missing', values: taxa.missing, format: _count),
    ReportMetric(
      label: 'Missing (%)',
      values: [for (final double v in taxa.propMissing) 100 * v],
      format: _percent,
    ),
    if (gc != null)
      ReportMetric(
        label: 'GC (%)',
        values: [for (final double v in gc) 100 * v],
        format: _percent,
        width: 110,
      ),
  ];
}

/// Stat tiles in rows: a fixed width on larger screens, and as many
/// columns as fit, at least two, on phones.
class StatTileGrid extends StatelessWidget {
  const StatTileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = SeguiSpacing.md;
        double width = SeguiContentWidth.statTile;
        if (isPhoneScreen(context) && constraints.hasBoundedWidth) {
          final int columns = math.max(
            2,
            ((constraints.maxWidth + gap) /
                    (SeguiContentWidth.statTileMin + gap))
                .floor(),
          );
          width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// One headline number of the report, with an optional detail below.
/// It fills the width its parent gives it, such as a [StatTileGrid].
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  /// Lines kept for [detail], so every tile has the same height.
  static const int detailLines = 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final TextStyle valueStyle = theme.textTheme.headlineSmall!;
    final TextStyle detailStyle = theme.textTheme.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeguiSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SeguiRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One line each, so labels and values keep tiles the same height.
          Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SeguiSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: valueStyle, maxLines: 1),
          ),
          Stack(
            children: [
              // Blank lines hold the detail's room, so tiles with and
              // without a detail have the same height.
              ExcludeSemantics(
                child: Text('\n' * (detailLines - 1), style: detailStyle),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: detailStyle,
                  maxLines: detailLines,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
