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
import 'package:segui/screens/viewers/distance_report/matrix.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/report/layout.dart';
import 'package:segui/services/providers/distance_report.dart';
import 'package:segui/services/viewers/alignment_report.dart';
import 'package:segui/services/viewers/distance_report.dart';
import 'package:segui/src/rust/api/distance_report.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';
import 'package:segui/screens/shared/badges.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

String _count(double value) =>
    value.isFinite ? _countFormat.format(value) : '–';

String _decimal(double value) =>
    value.isFinite ? value.toStringAsFixed(1) : '–';

/// Interactive report for `distance-report.json`.
class DistanceReportView extends StatelessWidget {
  const DistanceReportView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BetaTitle(text: p.basename(file.path), isBeta: true),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [InfoButton(file: file)],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: SafeArea(child: DistanceReportBody(path: file.path)),
    );
  }
}

class DistanceReportBody extends ConsumerWidget {
  const DistanceReportBody({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(distanceReportProvider(path)).when(
          data: (report) => DistanceReportContent(report: report),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyScreen(
            title: 'Failed to read the report.',
            description: error.toString(),
          ),
        );
  }
}

/// The report in tabs: an overview, every locus, sample, and group, and
/// the distance matrices.
class DistanceReportContent extends StatefulWidget {
  const DistanceReportContent({super.key, required this.report});

  final DistanceReportData report;

  @override
  State<DistanceReportContent> createState() => _DistanceReportContentState();
}

class _DistanceReportContentState extends State<DistanceReportContent> {
  int _openLocus = 0;
  int _openSample = 0;
  int _openGroup = 0;

  @override
  void didUpdateWidget(covariant DistanceReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report) {
      _openLocus = 0;
      _openSample = 0;
      _openGroup = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DistanceReportData report = widget.report;
    if (report.loci.names.isEmpty) {
      return const EmptyScreen(
        title: 'No loci in this report.',
        description: 'The run found no alignments to report.',
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

  List<ReportTab> _tabs(DistanceReportData report) {
    final DistanceLociData loci = report.loci;
    final DistanceSamplesData samples = report.samples;
    final DistanceGroupsData? groups = report.groups;
    final DistanceMatrixData? matrix = report.matrix;
    return [
      ReportTab(label: 'Overview', sections: _overview(report)),
      ReportTab(label: 'Loci', sections: [
        ReportSection(
          title: 'Loci',
          description: 'Pairwise distances within each alignment. Select '
              'one to see all its values.',
          fill: true,
          child: ReportItemPanel(
            names: loci.names,
            metrics: distanceLociMetrics(loci),
            nameLabel: 'Locus',
            open: _openLocus.clamp(0, loci.names.length - 1),
            onSelected: (i) => setState(() => _openLocus = i),
          ),
        ),
      ]),
      ReportTab(label: 'Samples', sections: [
        ReportSection(
          title: 'Samples',
          description: 'Distances from each sample to every other sample, '
              'across loci.',
          fill: true,
          child: samples.names.isEmpty
              ? const ChartPlaceholder(message: 'No samples in this report.')
              : ReportItemPanel(
                  names: samples.names,
                  metrics: distanceSampleMetrics(
                    samples,
                    hasMatrix: matrix != null,
                    hasGroups: groups != null,
                  ),
                  nameLabel: 'Sample',
                  open: _openSample.clamp(0, samples.names.length - 1),
                  onSelected: (i) => setState(() => _openSample = i),
                ),
        ),
      ]),
      if (groups != null && groups.names.isNotEmpty)
        ReportTab(label: 'Groups', sections: [
          ReportSection(
            title: 'Groups',
            description: 'Distances within each group, and the mean to '
                'the nearest group.',
            fill: true,
            child: ReportItemPanel(
              names: groups.names,
              metrics: distanceGroupMetrics(groups),
              nameLabel: 'Group',
              open: _openGroup.clamp(0, groups.names.length - 1),
              onSelected: (i) => setState(() => _openGroup = i),
            ),
          ),
        ]),
      if (matrix != null)
        ReportTab(label: 'Matrix', sections: [
          ReportSection(
            title: 'Sample matrix',
            description: 'Mean distance between samples across the loci '
                'they share.',
            fill: true,
            child: DistanceMatrixPanel(matrix: matrix, itemLabel: 'Sample'),
          ),
        ]),
      if (groups != null && groups.names.length > 1)
        ReportTab(label: 'Group matrix', sections: [
          ReportSection(
            title: 'Group matrix',
            description: 'Mean distance within and between groups.',
            fill: true,
            child: DistanceMatrixPanel(
              matrix: groups.matrix,
              itemLabel: 'Group',
            ),
          ),
        ]),
    ];
  }

  List<ReportSection> _overview(DistanceReportData report) {
    final DistanceOverviewData s = report.summary;
    final DistanceBars bars =
        DistanceBars.of(report.histogram, report.binWidth);
    return [
      ReportSection(
        title: 'Dataset',
        child: StatTileGrid(
          children: [
            StatTile(
              label: 'Model',
              value: report.model,
              detail: report.datatype == 'dna' ? 'DNA' : 'Amino acid',
            ),
            StatTile(label: 'Loci', value: _count(s.loci)),
            StatTile(label: 'Samples', value: _count(s.samples)),
            StatTile(
              label: 'Pairs',
              value: _count(s.pairs),
              detail: '${_count(s.undefinedPairs)} undefined',
            ),
            StatTile(
              label: 'Mean distance',
              value: formatDistance(s.mean),
              detail: 'SD ${formatDistance(s.sd)}\n'
                  '${formatDistance(s.min)}-${formatDistance(s.max)}',
            ),
            StatTile(
              label: 'Median locus mean',
              value: formatDistance(s.medianLocusMean),
            ),
            StatTile(
              label: 'Compared sites',
              value: _decimal(s.meanComparedSites),
              detail: 'mean per pair',
            ),
            if (s.groups != null)
              StatTile(
                label: 'Groups',
                value: _count(s.groups!),
                detail: '${_count(s.unassigned)} samples unassigned',
              ),
          ],
        ),
      ),
      ReportSection(
        title: 'Pairwise distances',
        description: 'Every sample pair across all loci.',
        child: bars.counts.isEmpty
            ? const ChartPlaceholder(message: 'No pairwise distances.')
            : ReadBarChart(
                xLabel: 'Distance',
                barWidth: SeguiChartLayout.wideBarWidth,
                yLabel: 'Pairs',
                categories: bars.labels,
                series: [
                  BarSeries(
                    name: 'Pairs',
                    values: bars.counts,
                    color: SeguiColors.of(context).seriesAt(0),
                  ),
                ],
              ),
      ),
    ];
  }
}

/// Columns of the loci table, and the metrics their bars can show.
List<ReportMetric> distanceLociMetrics(DistanceLociData loci) {
  return [
    ReportMetric(
      label: 'Samples',
      values: loci.ntax,
      format: _count,
      width: 110,
    ),
    ReportMetric(label: 'Sites', values: loci.nchar, format: _count),
    ReportMetric(label: 'Pairs', values: loci.pairs, format: _count),
    ReportMetric(
      label: 'Undefined',
      values: loci.undefinedPairs,
      format: _count,
    ),
    ReportMetric(label: 'Mean', values: loci.mean, format: formatDistance),
    ReportMetric(label: 'Median', values: loci.median, format: formatDistance),
    ReportMetric(label: 'SD', values: loci.sd, format: formatDistance),
    ReportMetric(label: 'Min', values: loci.min, format: formatDistance),
    ReportMetric(label: 'Max', values: loci.max, format: formatDistance),
    ReportMetric(
      label: 'Compared sites',
      values: loci.meanComparedSites,
      format: _decimal,
      width: 150,
    ),
  ];
}

/// Columns of the samples table. The nearest sample needs the sample
/// matrix, and the within and between distances need groups too.
List<ReportMetric> distanceSampleMetrics(
  DistanceSamplesData samples, {
  required bool hasMatrix,
  required bool hasGroups,
}) {
  return [
    ReportMetric(
      label: 'Loci',
      values: samples.loci,
      format: _count,
      width: 100,
    ),
    ReportMetric(label: 'Pairs', values: samples.pairs, format: _count),
    ReportMetric(label: 'Mean', values: samples.mean, format: formatDistance),
    ReportMetric(label: 'SD', values: samples.sd, format: formatDistance),
    ReportMetric(label: 'Min', values: samples.min, format: formatDistance),
    ReportMetric(label: 'Max', values: samples.max, format: formatDistance),
    if (hasMatrix)
      ReportMetric(
        label: 'Nearest',
        values: samples.nearestDistance,
        format: formatDistance,
      ),
    if (hasMatrix && hasGroups) ...[
      ReportMetric(
        label: 'Max within',
        values: samples.maxWithin,
        format: formatDistance,
      ),
      ReportMetric(
        label: 'Min between',
        values: samples.minBetween,
        format: formatDistance,
        width: 140,
      ),
    ],
  ];
}

/// Columns of the groups table.
List<ReportMetric> distanceGroupMetrics(DistanceGroupsData groups) {
  return [
    ReportMetric(
      label: 'Samples',
      values: groups.samples,
      format: _count,
      width: 110,
    ),
    ReportMetric(label: 'Pairs', values: groups.pairs, format: _count),
    ReportMetric(
      label: 'Mean within',
      values: groups.meanWithin,
      format: formatDistance,
      width: 140,
    ),
    ReportMetric(
      label: 'SD within',
      values: groups.sdWithin,
      format: formatDistance,
    ),
    ReportMetric(
      label: 'Max within',
      values: groups.maxWithin,
      format: formatDistance,
    ),
    ReportMetric(
      label: 'Nearest group',
      values: nearestGroupMeans(groups),
      format: formatDistance,
      width: 150,
    ),
  ];
}
