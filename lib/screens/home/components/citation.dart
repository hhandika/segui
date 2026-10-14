import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/common.dart';
import 'package:segui/services/utils.dart';

/// Opens the SEGUL citation with copy and article links.
class CiteSegulButton extends StatelessWidget {
  const CiteSegulButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.format_quote_outlined),
      label: const Text('Cite SEGUL'),
      onPressed: () => showResponsiveSheet(
        context: context,
        builder: (context) => const CitationContent(),
      ),
    );
  }
}

class CitationContent extends StatelessWidget {
  const CitationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context).textTheme.bodyLarge;
    return SheetContent(
      title: 'Cite SEGUL',
      actions: const [
        CopyCitationButton(),
        ViewArticleButton(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If SEGUI or SEGUL helps your research, please cite:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Lightest tone, so it stands out on both dialog and sheet.
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: SelectableText.rich(
              TextSpan(
                style: style,
                children: const [
                  TextSpan(
                    text: '$segulCitationAuthors $segulCitationTitle ',
                  ),
                  TextSpan(
                    text: segulCitationJournal,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(text: ', $segulCitationIssue. $segulArticleUrl'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Copies the citation, then confirms in its own label.
class CopyCitationButton extends StatefulWidget {
  const CopyCitationButton({super.key});

  @override
  State<CopyCitationButton> createState() => _CopyCitationButtonState();
}

class _CopyCitationButtonState extends State<CopyCitationButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(_isCopied ? Icons.check_rounded : Icons.copy_rounded),
      label: Text(_isCopied ? 'Copied' : 'Copy citation'),
      onPressed: _copy,
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: segulCitation));
    if (mounted) {
      setState(() => _isCopied = true);
    }
  }
}

class ViewArticleButton extends StatelessWidget {
  const ViewArticleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.open_in_new_rounded),
      label: const Text('View article'),
      onPressed: launchSegulArticleUrl,
    );
  }
}
