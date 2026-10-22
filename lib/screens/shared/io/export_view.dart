import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/io/export.dart';
import 'package:segui/src/rust/api/archive.dart';
import 'package:segui/styles/design_tokens.dart';

/// What the user chose in [ExportFilesSheet].
typedef ExportRequest = ({ExportFormat format, bool isSharing});

/// Picks the archive format for [count] files, then exports or shares
/// them. Pops with an [ExportRequest], or null on Cancel.
class ExportFilesSheet extends StatefulWidget {
  const ExportFilesSheet({
    super.key,
    required this.count,
    this.canShare = true,
  });

  final int count;

  /// Whether to offer Share next to Export.
  final bool canShare;

  @override
  State<ExportFilesSheet> createState() => _ExportFilesSheetState();
}

class _ExportFilesSheetState extends State<ExportFilesSheet> {
  ExportFormat _format = ExportFormat.zip;

  @override
  Widget build(BuildContext context) {
    final String files = widget.count == 1 ? '1 file' : '${widget.count} files';
    return SheetContent(
      title: 'Export $files',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.canShare)
          OutlinedButton.icon(
            onPressed: () => _finish(isSharing: true),
            icon: Icon(Icons.adaptive.share_rounded),
            label: const Text('Share'),
          ),
        FilledButton.icon(
          onPressed: () => _finish(isSharing: false),
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bundle the selected files into one archive.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: SeguiSpacing.md),
          RadioGroup<ExportFormat>(
            groupValue: _format,
            onChanged: (value) {
              if (value != null) {
                setState(() => _format = value);
              }
            },
            child: Column(
              children: [
                for (final ExportFormat format in ExportFormat.values)
                  RadioListTile<ExportFormat>(
                    value: format,
                    contentPadding: EdgeInsets.zero,
                    title: Text(format.label),
                    subtitle: Text(format.description),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _finish({required bool isSharing}) {
    Navigator.of(context).pop<ExportRequest>(
      (format: _format, isSharing: isSharing),
    );
  }
}
