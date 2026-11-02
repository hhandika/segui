// Shared model and layout helpers for the static layered diagrams on the
// architecture page. The design follows the NAHPU architecture figures, in
// SEGUL colors and without motion or interaction.

// `app` marks a product people run, `ui` the layers that front the library
// (Flutter/Dart in the GUI, the `segul` crate in the CLI), `rust` the Rust
// library and bindings, and `data` files on disk.
export type Tone = "app" | "ui" | "rust" | "data";

export interface NodeText {
  title: string;
  path?: string;
  sub?: string;
  chips?: string[];
}

export interface NodeDef extends NodeText {
  id: string;
  tone: Tone;
  badge?: string;
}

export interface Box {
  x: number;
  y: number;
  w: number;
  h: number;
  text?: Partial<NodeText>;
}

export interface Edge {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  label?: string;
  // A plain connector segment, such as a shared trunk, has no arrowhead.
  arrow?: boolean;
}

// Two layouts share one node list: a wide one for larger screens and a
// stacked one for phones.
export interface Layout {
  name: "wide" | "narrow";
  width: number;
  height: number;
  badges: boolean;
  chipCharW: number;
  boxes: Record<string, Box>;
  edges: Edge[];
  boundary?: { x1: number; x2: number; y: number };
  legend: { x: number; y: number; vertical: boolean };
}

export interface LegendItem {
  tone: Tone;
  label: string;
}

// Offsets of horizontal legend entries, sized to each label.
export function legendOffsets(items: LegendItem[], charW: number): number[] {
  let x = 0;
  return items.map((item) => {
    const at = x;
    x += 20 + Math.round(item.label.length * charW) + 18;
    return at;
  });
}

interface Chip {
  label: string;
  x: number;
  y: number;
  w: number;
}

// Lay chips out left to right, wrapping when a row runs past maxW.
export function wrapChips(labels: string[], x: number, y: number, maxW: number, charW: number): Chip[] {
  const chips: Chip[] = [];
  let cx = x;
  let cy = y;
  for (const label of labels) {
    const w = Math.round(label.length * charW + 16);
    if (cx + w > x + maxW && cx > x) {
      cx = x;
      cy += 26;
    }
    chips.push({ label, x: cx, y: cy, w });
    cx += w + 6;
  }
  return chips;
}

// Triangle at the end of a straight connector pointing from (x1,y1) to (x2,y2).
export function arrowHead(x1: number, y1: number, x2: number, y2: number, size = 6): string {
  const a = Math.atan2(y2 - y1, x2 - x1);
  const p = (da: number) =>
    `${(x2 - size * Math.cos(a + da)).toFixed(1)},${(y2 - size * Math.sin(a + da)).toFixed(1)}`;
  return `${x2},${y2} ${p(0.5)} ${p(-0.5)}`;
}

// Resolve text, badge width, and chip positions for each node in a layout.
export function place(nodes: NodeDef[], layout: Layout) {
  return nodes.map((n) => {
    const b = layout.boxes[n.id];
    const text: NodeText = { title: n.title, path: n.path, sub: n.sub, chips: n.chips, ...b.text };
    const badge =
      layout.badges && n.badge
        ? { label: n.badge.toUpperCase(), w: Math.round(n.badge.length * 6.6 + 14) }
        : null;
    // Chips start below the subtitle when a node has one.
    let chips = text.chips
      ? wrapChips(text.chips, b.x + 14, b.y + (text.sub ? 68 : 50), b.w - 24, layout.chipCharW)
      : [];
    if (n.tone === "app" && chips.length) {
      // App chips: right-aligned on wide, below the title on narrow.
      if (layout.name === "wide") {
        const last = chips[chips.length - 1];
        const shift = b.x + b.w - 16 - (last.x + last.w);
        chips = chips.map((c) => ({ ...c, x: c.x + shift, y: b.y + (b.h - 22) / 2 }));
      } else {
        chips = chips.map((c) => ({ ...c, y: b.y + 52 }));
      }
    }
    return { ...n, ...b, text, badge, chips };
  });
}
