/// Compares strings with runs of digits as numbers, ignoring case.
int compareNatural(String a, String b) {
  final RegExp chunks = RegExp(r'\d+|\D+');
  final List<String> left =
      chunks.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final List<String> right =
      chunks.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (int i = 0; i < left.length && i < right.length; i++) {
    final int? x = int.tryParse(left[i]);
    final int? y = int.tryParse(right[i]);
    final int result =
        x != null && y != null ? x.compareTo(y) : left[i].compareTo(right[i]);
    if (result != 0) return result;
  }
  return left.length.compareTo(right.length);
}

/// Text that sorts naturally, so `locus_2` comes before `locus_10`. Use it
/// as a sort value where a [Comparable] is expected.
class NaturalText implements Comparable<NaturalText> {
  const NaturalText(this.text);

  final String text;

  @override
  int compareTo(NaturalText other) => compareNatural(text, other.text);

  @override
  String toString() => text;
}
