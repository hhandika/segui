import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:segui/screens/shared/buttons.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/screens/shared/io/io.dart';
import 'package:segui/screens/shared/pages.dart';
import 'package:segui/screens/viewers/report/data_bar.dart';
import 'package:segui/screens/viewers/report/paged_table.dart';
import 'package:segui/services/viewers/csv.dart';
import 'package:segui/styles/decoration.dart';
import 'package:segui/styles/design_tokens.dart';

class TabulatedFileView extends StatelessWidget {
  const TabulatedFileView({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(basename(file.path)),
        backgroundColor: getSEGULBackgroundColor(context),
        actions: [
          InfoButton(file: file),
        ],
      ),
      backgroundColor: getSEGULBackgroundColor(context),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(SeguiSpacing.xl),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: SeguiSpacing.xs),
                  child: Container(
                    decoration: getContainerDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.all(SeguiSpacing.xl),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FileIcon(file: file),
                          const SizedBox(width: SeguiSpacing.md),
                          FileIOSubtitle(file: file),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(SeguiSpacing.md),
                    decoration: getContainerDecoration(context),
                    child: TabulatedFileViewBody(file: file),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class TabulatedFileViewBody extends StatefulWidget {
  const TabulatedFileViewBody({super.key, required this.file});

  final File file;

  @override
  State<TabulatedFileViewBody> createState() => _TabulatedFileViewBodyState();
}

class _TabulatedFileViewBodyState extends State<TabulatedFileViewBody> {
  // Parsed once, so rebuilds do not read the file again.
  late Future<List<List<dynamic>>> _content = _parseContent();

  @override
  void didUpdateWidget(covariant TabulatedFileViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _content = _parseContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _content,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<List<dynamic>> content = snapshot.data!;
          if (content.isEmpty) {
            return const Center(child: Text('Failed to parse file.'));
          }
          if (content.length < 2) {
            return const EmptyScreen(
                title: 'Table is empty.',
                description: 'Try run the analysis again.');
          }
          return CsvTable(content: content);
        });
  }

  Future<List<List<dynamic>>> _parseContent() async {
    try {
      final parser = CsvParser();
      return await parser.parse(widget.file);
    } catch (e) {
      return [];
    }
  }
}

/// Rows of a delimited file in a sortable table shown a page at a time,
/// with the header and pager in place. Columns of numbers are aligned to
/// the end, with a bar behind each value that shows where it sits between
/// the lowest and highest value of the column.
class CsvTable extends StatelessWidget {
  const CsvTable({super.key, required this.content});

  /// The header row followed by the records.
  final List<List<dynamic>> content;

  /// Rows read to size the columns, so very long files size quickly.
  static const int _sizedRows = 200;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> header = content.first;
    final List<List<dynamic>> records = content.sublist(1);
    final Color neutral = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DataBarLegend(),
        const SizedBox(height: SeguiSpacing.sm),
        Expanded(
          child: PagedTable<int>(
            rows: [for (int i = 0; i < records.length; i++) i],
            columns: [
              for (int col = 0; col < header.length; col++)
                _column(header[col].toString().trim(), col, records, neutral),
            ],
          ),
        ),
      ],
    );
  }

  PagedTableColumn<int> _column(
    String label,
    int col,
    List<List<dynamic>> records,
    Color neutral,
  ) {
    dynamic cellAt(int row) =>
        col < records[row].length ? records[row][col] : null;
    final CsvColumnStats stats = CsvColumnStats.of(
      [for (int row = 0; row < records.length; row++) cellAt(row)],
    );
    int longest = label.length;
    for (int row = 0; row < records.length && row < _sizedRows; row++) {
      final int length = _format(cellAt(row)).length;
      if (length > longest) longest = length;
    }
    final double width = (longest * SeguiTableLayout.charWidth +
            2 * SeguiTableLayout.cellPadding +
            SeguiControlSize.iconSmall)
        .clamp(SeguiTableLayout.minColumn, SeguiTableLayout.maxColumn);
    if (!stats.isNumeric) {
      return PagedTableColumn(
        label: label,
        width: width,
        sortValue: (row) => cellAt(row)?.toString() ?? '',
        cell: (row) => Text(
          _format(cellAt(row)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return PagedTableColumn(
      label: label,
      width: width,
      numeric: true,
      sortValue: (row) {
        final dynamic value = cellAt(row);
        return value is num ? value.toDouble() : double.negativeInfinity;
      },
      cell: (row) {
        final dynamic value = cellAt(row);
        final Text text = Text(_format(value), maxLines: 1, softWrap: false);
        // Bars say nothing for empty cells or a column of one value.
        if (value is! num || stats.high <= stats.low) return text;
        return DataBarCell(
          fraction: (value - stats.low) / (stats.high - stats.low),
          color: neutral,
          child: text,
        );
      },
    );
  }

  /// Numbers with thousands separators and at most two decimals.
  static String _format(dynamic value) {
    if (value == null) return '';
    if (value is num) return NumberFormat('#,###.##').format(value);
    return value.toString();
  }
}

/// Whether a column holds numbers, and their range.
class CsvColumnStats {
  const CsvColumnStats({
    required this.isNumeric,
    required this.low,
    required this.high,
  });

  /// Every value that is not empty is a number, and there is at least one.
  final bool isNumeric;
  final double low;
  final double high;

  factory CsvColumnStats.of(List<dynamic> values) {
    double low = double.infinity;
    double high = double.negativeInfinity;
    bool hasNumber = false;
    for (final dynamic value in values) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        continue;
      }
      if (value is! num) {
        return const CsvColumnStats(isNumeric: false, low: 0, high: 0);
      }
      hasNumber = true;
      if (value < low) low = value.toDouble();
      if (value > high) high = value.toDouble();
    }
    return hasNumber
        ? CsvColumnStats(isNumeric: true, low: low, high: high)
        : const CsvColumnStats(isNumeric: false, low: 0, high: 0);
  }
}
