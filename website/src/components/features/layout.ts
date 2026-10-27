/// Shared sizes and sample data for the feature diagrams.

/// Height of a `ListCard` holding `count` lines.
export function listCardHeight(count: number, lineHeight = 20): number {
  return 34 + count * lineHeight + 6;
}

/// Sample IDs and two loci used by the concatenation and splitting diagrams.
export const sampleIds = ["seq1", "seq2", "seq3"];
export const locusOne = ["AGTCCCCA--", "AGTCCCCAAT", "AGTC-CCTTA"];
export const locusTwo = ["GGCTAA-T", "GGCTAACT", "GG-TAACT"];

/// Column tones for `locusOne` followed by `locusTwo`.
export const concatTones = [
  ...Array(locusOne[0].length).fill("l1"),
  ...Array(locusTwo[0].length).fill("l2"),
];
/// Width of a `Chip` with this text, for laying out chips in a row.
export function chipWidth(text: string, mono = false): number {
  return text.length * (mono ? 8.2 : 7.4) + 18;
}

/// Left edges for a row of chips starting at `x` with `gap` between them.
export function chipRow(texts: string[], x: number, gap = 8, mono = false): number[] {
  const lefts: number[] = [];
  let cursor = x;
  for (const text of texts) {
    lefts.push(cursor);
    cursor += chipWidth(text, mono) + gap;
  }
  return lefts;
}
