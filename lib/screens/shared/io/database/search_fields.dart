import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/services/databases/compatibility.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/providers/databases.dart';
import 'package:segui/styles/design_tokens.dart';

/// What the user typed in the panel, kept while the panel rebuilds.
class DatabaseSearchInput {
  final TextEditingController organism = TextEditingController();
  final TextEditingController gene = TextEditingController();
  final TextEditingController keyword = TextEditingController();
  final TextEditingController minLength = TextEditingController();
  final TextEditingController maxLength = TextEditingController();
  final TextEditingController accessions = TextEditingController();
  final TextEditingController fileName = TextEditingController();
  final FocusNode organismFocus = FocusNode();

  void dispose() {
    for (final controller in [
      organism,
      gene,
      keyword,
      minLength,
      maxLength,
      accessions,
      fileName,
    ]) {
      controller.dispose();
    }
    organismFocus.dispose();
  }
}

/// Where and what to search, and the button that starts it.
class DatabaseSearchFields extends ConsumerStatefulWidget {
  const DatabaseSearchFields({
    super.key,
    required this.target,
    required this.support,
    required this.input,
  });

  final DatabaseTarget target;
  final DatabaseAvailable support;
  final DatabaseSearchInput input;

  @override
  ConsumerState<DatabaseSearchFields> createState() =>
      DatabaseSearchFieldsState();
}

class DatabaseSearchFieldsState extends ConsumerState<DatabaseSearchFields> {
  bool _isRefSeqOnly = false;

  @override
  Widget build(BuildContext context) {
    final DatabaseState state =
        ref.watch(databaseSessionProvider(widget.target));
    final List<DatabaseSource> sources = widget.support.sources;
    final List<DownloadContent> contents =
        widget.support.contentsOf(state.source);
    final bool isSearch = state.mode == DatabaseEntryMode.search;
    final DownloadContent content = state.content;
    return FormCard(
      children: [
        if (sources.length > 1)
          SegmentedField(
            label: 'Database',
            value: state.source.label,
            items: [for (final source in sources) source.label],
            onChanged: (label) => _session.setSource(
              sources.firstWhere((source) => source.label == label),
            ),
          ),
        if (contents.length > 1)
          SharedMapDropdownField(
            // A dropdown keeps its first value unless it is built again.
            key: ValueKey((state.source, content)),
            label: 'Content',
            value: content.name,
            items: {for (final item in contents) item.name: item.label},
            onChanged: (name) {
              if (name != null) {
                _session.setContent(DownloadContent.values.byName(name));
              }
            },
          ),
        SegmentedField(
          label: 'Find records by',
          value: state.mode.label,
          items: [for (final mode in DatabaseEntryMode.values) mode.label],
          onChanged: (label) => _session.setMode(
            DatabaseEntryMode.values.firstWhere((mode) => mode.label == label),
          ),
        ),
        if (isSearch) ...[
          OrganismField(
            target: widget.target,
            input: widget.input,
            onSubmitted: _submit,
          ),
          if (content.isSequence)
            DatabaseTextField(
              controller: widget.input.gene,
              label: 'Gene',
              hint: 'CYTB',
              onSubmitted: _submit,
            ),
          DatabaseTextField(
            controller: widget.input.keyword,
            label: 'Keyword',
            hint: _keywordHint(content),
            onSubmitted: _submit,
          ),
          if (_hasLength(state))
            Row(
              spacing: SeguiSpacing.lg,
              children: [
                Expanded(
                  child: DatabaseTextField(
                    controller: widget.input.minLength,
                    label: 'Min length',
                    hint: '500',
                    isNumber: true,
                    onSubmitted: _submit,
                  ),
                ),
                Expanded(
                  child: DatabaseTextField(
                    controller: widget.input.maxLength,
                    label: 'Max length',
                    hint: '20000',
                    isNumber: true,
                    onSubmitted: _submit,
                  ),
                ),
              ],
            ),
          if (state.source == DatabaseSource.genBank)
            SwitchForm(
              label: 'RefSeq only',
              value: _isRefSeqOnly,
              onPressed: (value) => setState(() => _isRefSeqOnly = value),
            ),
        ] else
          TextField(
            controller: widget.input.accessions,
            minLines: 2,
            maxLines: 5,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Accessions',
              hintText: _accessionHint(content),
              helperText: 'Separate with commas, spaces, or lines.',
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: state.isSearching
              ? OutlinedButton.icon(
                  onPressed: _session.stopSearch,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Stop'),
                )
              : FilledButton.tonalIcon(
                  onPressed: _submit,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(isSearch ? 'Search' : 'Find'),
                ),
        ),
      ],
    );
  }

  DatabaseSession get _session =>
      ref.read(databaseSessionProvider(widget.target).notifier);

  void _submit() {
    FocusScope.of(context).unfocus();
    final DatabaseState state =
        ref.read(databaseSessionProvider(widget.target));
    final DatabaseSearchInput input = widget.input;
    if (state.mode == DatabaseEntryMode.paste) {
      _session.lookUp(input.accessions.text);
      return;
    }
    // Hidden fields must not narrow the search.
    final bool hasLength = _hasLength(state);
    _session.search(DatabaseQuery(
      content: state.content,
      organism: input.organism.text,
      gene: state.content.isSequence ? input.gene.text : '',
      keyword: input.keyword.text,
      minLength: hasLength ? int.tryParse(input.minLength.text) : null,
      maxLength: hasLength ? int.tryParse(input.maxLength.text) : null,
      refSeqOnly: state.source == DatabaseSource.genBank && _isRefSeqOnly,
    ));
  }

  // NCBI cannot filter assemblies by length, and runs have none.
  bool _hasLength(DatabaseState state) {
    return state.content.isSequence ||
        (state.content == DownloadContent.assembly &&
            state.source == DatabaseSource.ena);
  }

  String _keywordHint(DownloadContent content) {
    return switch (content) {
      DownloadContent.reads => 'amplicon',
      DownloadContent.assembly => 'strain or project',
      _ => 'cytochrome b',
    };
  }

  String _accessionHint(DownloadContent content) {
    return switch (content) {
      DownloadContent.nucleotide => 'U49845.1',
      DownloadContent.coding => 'U49845.1',
      DownloadContent.protein => 'NP_904340.1',
      DownloadContent.reads => 'SRR, ERR, DRR, or a study',
      DownloadContent.assembly => 'GCA_000146045.2',
    };
  }
}

/// Text field that searches when submitted.
class DatabaseTextField extends StatelessWidget {
  const DatabaseTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onSubmitted,
    this.isNumber = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onSubmitted;
  final bool isNumber;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: isNumber ? TextInputType.number : null,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

/// Organism field with names from the selected database as the user types.
class OrganismField extends ConsumerWidget {
  const OrganismField({
    super.key,
    required this.target,
    required this.input,
    required this.onSubmitted,
  });

  final DatabaseTarget target;
  final DatabaseSearchInput input;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<String>(
      textEditingController: input.organism,
      focusNode: input.organismFocus,
      optionsMaxHeight: SeguiContentWidth.statTile,
      optionsBuilder: (value) => ref
          .read(databaseSessionProvider(target).notifier)
          .suggest(value.text),
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          // Enter searches what was typed, not the first suggestion.
          onSubmitted: (_) => onSubmitted(),
          decoration: const InputDecoration(
            labelText: 'Organism',
            hintText: 'Rattus norvegicus',
          ),
        );
      },
    );
  }
}
