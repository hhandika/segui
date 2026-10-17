import 'package:material_ui/material_ui.dart';
import 'package:segui/screens/shared/forms.dart';
import 'package:segui/src/rust/api/sequence.dart';
import 'package:segui/styles/design_tokens.dart';

/// Most group chips shown before the rest are summarized as a count.
const int _maxGroupChips = 24;

/// Most unassigned sample names listed in the warning.
const int _maxUnassignedNames = 5;

/// Groups assigned to the samples of the input alignments,
/// with a warning for samples that match no group.
class SampleGroupPreview extends StatelessWidget {
  const SampleGroupPreview({super.key, required this.preview});

  final DistanceGroupPreview preview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int hidden = preview.groups.length - _maxGroupChips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SeguiSpacing.md,
      children: [
        Text(_title, style: theme.textTheme.titleSmall),
        if (preview.delimiter != null)
          FieldHelperText(
            text: 'Detected: split on "${preview.delimiter}" and keep '
                '${preview.fields} ${preview.fields == BigInt.one ? 'field' : 'fields'}.',
          ),
        Wrap(
          spacing: SeguiSpacing.sm,
          runSpacing: SeguiSpacing.sm,
          children: [
            for (final group in preview.groups.take(_maxGroupChips))
              GroupCountChip(name: group.name, count: group.count.toInt()),
            if (hidden > 0) GroupCountChip(name: 'More groups', count: hidden),
          ],
        ),
        if (preview.unassigned.isNotEmpty)
          UnassignedSamplesText(samples: preview.unassigned),
      ],
    );
  }

  String get _title {
    final int groups = preview.groups.length;
    final BigInt samples = preview.sampleCount;
    return '$groups ${groups == 1 ? 'group' : 'groups'} from '
        '$samples ${samples == BigInt.one ? 'sample' : 'samples'}';
  }
}

/// Group name with its sample count.
class GroupCountChip extends StatelessWidget {
  const GroupCountChip({super.key, required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeguiSpacing.md,
        vertical: SeguiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(SeguiRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SeguiSpacing.sm,
        children: [
          Flexible(
            child: Text(
              name,
              style: textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Warns that [samples] match no group and are left out of group means.
class UnassignedSamplesText extends StatelessWidget {
  const UnassignedSamplesText({super.key, required this.samples});

  final List<String> samples;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String names = samples.take(_maxUnassignedNames).join(', ');
    final String more = samples.length > _maxUnassignedNames ? ', …' : '';
    final String noun =
        samples.length == 1 ? 'sample matches' : 'samples match';
    return Text(
      '${samples.length} $noun no group and will be left out of group '
      'means: $names$more',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}
