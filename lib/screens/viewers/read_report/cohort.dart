import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/viewers/read_report/charts.dart';
import 'package:segui/screens/viewers/read_report/summary.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/viewers/natural_sort.dart';
import 'package:segui/services/viewers/read_report.dart';
import 'package:segui/src/rust/api/reads.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

final NumberFormat _countFormat = NumberFormat('#,##0');

/// Pooling depth balance summary across all samples in a read report.
class CohortBalanceSummary extends StatelessWidget {
  const CohortBalanceSummary({
    super.key,
    required this.cohort,
    required this.qcProfile,
  });

  final ReadCohortData cohort;
  final String qcProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<(String, String)> stats = [
      (
        'Samples',
        cohort.emptySampleCount > 0
            ? '${_countFormat.format(cohort.sampleCount)} '
                '(${_countFormat.format(cohort.emptySampleCount)} empty)'
            : _countFormat.format(cohort.sampleCount),
      ),
      ('Total reads', formatCompact(cohort.totalReads)),
      ('Total bases', formatCompact(cohort.totalBases)),
      ('Median reads', formatCompact(cohort.medianReads)),
      (
        'P10–P90',
        '${formatCompact(cohort.p10Reads)}–${formatCompact(cohort.p90Reads)}',
      ),
      ('P90/P10 ratio', '${cohort.depthP90P10Ratio.toStringAsFixed(2)}×'),
      ('Depth CV', cohort.depthCv.toStringAsFixed(2)),
      ('Depth Gini', cohort.depthGini.toStringAsFixed(2)),
      if (qcProfile.isNotEmpty) ('QC profile', qcProfile),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: SeguiSpacing.md,
          runSpacing: SeguiSpacing.md,
          children: [
            for (final (String label, String value) in stats)
              _CohortStatTile(label: label, value: value),
          ],
        ),
        if (cohort.lowYieldSamples.isNotEmpty) ...[
          const SizedBox(height: SeguiSpacing.lg),
          Text(
            'Low-yield dropouts (<10% of median depth)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: SeguiSpacing.sm),
          Wrap(
            spacing: SeguiSpacing.sm,
            runSpacing: SeguiSpacing.sm,
            children: [
              for (final String sample in cohort.lowYieldSamples)
                QcStatusChip(status: ReadQcStatus.warn, label: sample),
            ],
          ),
        ],
      ],
    );
  }
}

class _CohortStatTile extends StatelessWidget {
  const _CohortStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.lg,
        vertical: SeguiSpacing.md,
      ),
      decoration: getContainerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SeguiSpacing.xs),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// Sortable table of R1/R2 paired-end consistency and quality drops.
class ReadPairsTable extends StatelessWidget {
  const ReadPairsTable({super.key, required this.pairs});

  final List<ReadPairData> pairs;

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) {
      return const ChartPlaceholder(
        message: 'No matched R1/R2 sample pairs in this report.',
      );
    }
    return SizedBox(
      height: SeguiTableLayout.scrollingHeight,
      child: PagedTable<ReadPairData>(
        rows: pairs,
        columns: [
          PagedTableColumn(
            label: 'Pair',
            width: 200,
            sortValue: (p) => NaturalText(p.pairName),
            cell: (p) => Text(p.pairName, overflow: TextOverflow.ellipsis),
          ),
          PagedTableColumn(
            label: 'Status',
            width: 130,
            sortValue: (p) => p.status.index,
            cell: (p) => QcStatusChip(status: p.status),
          ),
          PagedTableColumn(
            label: 'R1 reads',
            width: 130,
            numeric: true,
            sortValue: (p) => p.r1Reads,
            cell: (p) => Text(_countFormat.format(p.r1Reads)),
          ),
          PagedTableColumn(
            label: 'R2 reads',
            width: 130,
            numeric: true,
            sortValue: (p) => p.r2Reads,
            cell: (p) => Text(_countFormat.format(p.r2Reads)),
          ),
          PagedTableColumn(
            label: 'Sync',
            width: 110,
            sortValue: (p) => p.inSync ? 0 : 1,
            cell: (p) => QcStatusChip(
              status: p.inSync ? ReadQcStatus.pass : ReadQcStatus.fail,
              label: p.inSync ? 'In sync' : _signedInt(p.readCountDiff),
            ),
          ),
          PagedTableColumn(
            label: 'Q30 drop (%)',
            width: 130,
            numeric: true,
            sortValue: (p) => p.q30DropPct,
            cell: (p) => Text(_signedDecimal(p.q30DropPct)),
          ),
          PagedTableColumn(
            label: 'Eff Q drop',
            width: 120,
            numeric: true,
            sortValue: (p) => p.effectiveQDrop,
            cell: (p) => Text(_signedDecimal(p.effectiveQDrop)),
          ),
          PagedTableColumn(
            label: 'GC diff (%)',
            width: 120,
            numeric: true,
            sortValue: (p) => p.gcDiffPct.abs(),
            cell: (p) => Text(_signedDecimal(p.gcDiffPct)),
          ),
        ],
      ),
    );
  }

  static String _signedInt(double value) {
    final int v = value.round();
    return v > 0 ? '+${_countFormat.format(v)}' : _countFormat.format(v);
  }

  static String _signedDecimal(double value) {
    final String text = value.toStringAsFixed(1);
    return value > 0 ? '+$text' : text;
  }
}

/// Sortable table of cohort-relative robust outliers.
class CohortOutliersTable extends StatelessWidget {
  const CohortOutliersTable({super.key, required this.outliers});

  final List<ReadCohortOutlierData> outliers;

  @override
  Widget build(BuildContext context) {
    if (outliers.isEmpty) {
      return const ChartPlaceholder(
        message: 'No cohort-relative outliers detected.',
      );
    }
    return SizedBox(
      height: SeguiTableLayout.scrollingHeight,
      child: PagedTable<ReadCohortOutlierData>(
        rows: outliers,
        columns: [
          PagedTableColumn(
            label: 'Sample',
            width: 200,
            sortValue: (o) => NaturalText(o.sample),
            cell: (o) => Text(o.sample, overflow: TextOverflow.ellipsis),
          ),
          PagedTableColumn(
            label: 'Metric',
            width: 160,
            sortValue: (o) => o.metric,
            cell: (o) => Text(o.metric),
          ),
          PagedTableColumn(
            label: 'Value',
            width: 110,
            numeric: true,
            sortValue: (o) => o.value,
            cell: (o) => Text(o.value.toStringAsFixed(1)),
          ),
          PagedTableColumn(
            label: 'Cohort median',
            width: 140,
            numeric: true,
            sortValue: (o) => o.cohortMedian,
            cell: (o) => Text(o.cohortMedian.toStringAsFixed(1)),
          ),
          PagedTableColumn(
            label: 'Modified Z',
            width: 120,
            numeric: true,
            sortValue: (o) => o.modifiedZ.abs(),
            cell: (o) => Text(
              o.modifiedZ > 0
                  ? '+${o.modifiedZ.toStringAsFixed(1)}'
                  : o.modifiedZ.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}
