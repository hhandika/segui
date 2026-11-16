import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/alignment_report.dart';
import 'package:segui/screens/viewers/alignment_report/items.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/layout.dart';
import 'package:segui/services/providers/contig_report.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/services/viewers/contig_report.dart';
import 'package:segui/src/rust/api/contig_report.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

String _count(double value) => _countFormat.format(value);

String _decimal(double value) => value.toStringAsFixed(1);

/// Interactive report for `contig-report.json`.
class ContigReportView extends StatelessWidget {
  const ContigReportView({super.key, required this.file});

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
      body: ContigReportBody(path: file.path),
    );
  }
}

class ContigReportBody extends ConsumerWidget {
  const ContigReportBody({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(contigReportProvider(path)).when(
          data: (report) => ContigReportContent(report: report),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyScreen(
            title: 'Failed to read the report.',
            description: error.toString(),
          ),
        );
  }
}

/// The report in tabs: an overview of the assemblies, every sample, and
/// contig lengths per sample.
class ContigReportContent extends StatefulWidget {
  const ContigReportContent({super.key, required this.report});

  final ContigReportData report;

  @override
  State<ContigReportContent> createState() => _ContigReportContentState();
}

class _ContigReportContentState extends State<ContigReportContent> {
  int _openSample = 0;
  int _openLength = 0;

  @override
  void didUpdateWidget(covariant ContigReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report) {
      _openSample = 0;
      _openLength = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ContigReportData report = widget.report;
    if (report.samples.names.isEmpty) {
      return const EmptyScreen(
        title: 'No samples in this report.',
        description: 'The summary found no contig files to report.',
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

  List<ReportTab> _tabs(ContigReportData report) {
    final ContigSamplesData samples = report.samples;
    final int last = samples.names.length - 1;
    return [
      ReportTab(label: 'Overview', sections: _overview(report)),
      ReportTab(label: 'Samples', sections: [
        ReportSection(
          title: 'Samples',
          description: 'Every contig file in the summary. Select one to see '
              'all its values.',
          fill: true,
          child: ReportItemPanel(
            names: samples.names,
            metrics: sampleMetrics(samples),
            nameLabel: 'Sample',
            open: _openSample.clamp(0, last),
            onSelected: (i) => setState(() => _openSample = i),
          ),
        ),
      ]),
      ReportTab(label: 'Lengths', sections: [
        ReportSection(
          title: 'Contig lengths',
          description: 'Contigs in each length range (bp) per sample.',
          fill: true,
          child: ReportItemPanel(
            names: samples.names,
            metrics: lengthMetrics(report),
            nameLabel: 'Sample',
            open: _openLength.clamp(0, last),
            onSelected: (i) => setState(() => _openLength = i),
          ),
        ),
      ]),
    ];
  }

  List<ReportSection> _overview(ContigReportData report) {
    final ContigOverviewData s = report.summary;
    final List<double> n50 = report.samples.n50;
    final Histogram n50Bins = Histogram.of(n50);
    return [
      ReportSection(
        title: 'Assemblies',
        child: StatTileGrid(
          children: [
            StatTile(label: 'Samples', value: _count(s.samples)),
            StatTile(label: 'Contigs', value: _count(s.contigs)),
            StatTile(label: 'Bases', value: _count(s.bases)),
            StatTile(label: 'GC content', value: '${_decimal(100 * s.gc)}%'),
            StatTile(
              label: 'N content',
              value: '${_decimal(100 * s.propN)}%',
              detail: '${_count(s.nCount)} bases',
            ),
            StatTile(
              label: 'Contigs per sample',
              value: _count(s.meanContigs.roundToDouble()),
              detail: 'mean, ${_count(s.minContigs)}-${_count(s.maxContigs)}',
            ),
            StatTile(
              label: 'N50',
              value: _count(s.medianN50.roundToDouble()),
              detail: 'median, ${_count(s.minN50)}-${_count(s.maxN50)}',
            ),
            StatTile(label: 'Longest contig', value: _count(s.longest)),
          ],
        ),
      ),
      ReportSection(
        title: 'Contig length',
        description: 'Contigs in each length range across all samples.',
        child: ReadBarChart(
          xLabel: 'Length (bp)',
          barWidth: SeguiChartLayout.wideBarWidth,
          yLabel: 'Contigs',
          categories: report.lengthBins,
          series: [
            BarSeries(
              name: 'Contigs',
              values: contigLengthTotals(report),
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      ),
      ReportSection(
        title: 'N50 across samples',
        description: 'Median ${_count(medianOf(n50))} across '
            '${_count(n50.length.toDouble())} samples.',
        child: ReadBarChart(
          xLabel: 'N50 (bp)',
          barWidth: SeguiChartLayout.wideBarWidth,
          yLabel: 'Samples',
          categories: n50Bins.labels,
          series: [
            BarSeries(
              name: 'Samples',
              values: n50Bins.counts,
              color: SeguiColors.of(context).seriesAt(0),
            ),
          ],
        ),
      ),
    ];
  }
}

/// Columns of the samples table, and the metrics their bars can show.
List<ReportMetric> sampleMetrics(ContigSamplesData samples) {
  return [
    ReportMetric(label: 'Contigs', values: samples.contigs, format: _count),
    ReportMetric(label: 'Bases', values: samples.bases, format: _count),
    ReportMetric(label: 'Mean length', values: samples.mean, format: _decimal),
    ReportMetric(label: 'Max length', values: samples.max, format: _count),
    ReportMetric(label: 'N50', values: samples.n50, format: _count, width: 100),
    ReportMetric(label: 'N75', values: samples.n75, format: _count, width: 100),
    ReportMetric(label: 'N90', values: samples.n90, format: _count, width: 100),
    ReportMetric(
      label: '>1000 bp',
      values: samples.longContigs,
      format: _count,
    ),
    ReportMetric(
      label: 'GC (%)',
      values: [for (final double v in samples.gc) 100 * v],
      format: _decimal,
      width: 110,
    ),
    ReportMetric(
      label: 'N (%)',
      values: [for (final double v in samples.propN) 100 * v],
      format: _decimal,
      width: 110,
    ),
  ];
}

/// One metric per length range, with the contigs of each sample in it.
List<ReportMetric> lengthMetrics(ContigReportData report) {
  final List<List<double>> counts = report.samples.lengthDistribution;
  return [
    for (int i = 0; i < report.lengthBins.length; i++)
      ReportMetric(
        label: report.lengthBins[i],
        values: [for (final List<double> sample in counts) sample[i]],
        format: _count,
        width: 100,
      ),
  ];
}
