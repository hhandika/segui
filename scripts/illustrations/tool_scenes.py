"""Generate the gull scenes drawn along the bottom of each SEGUI tool page.

Every scene shares the field sketch of the home illustration. The left
ornament marks the tool group (a DNA vine for genomics, a stone wall for
alignments, bunting for sequences, a tree for trees), and the SEGUL gull stands
by a prop for its tool: stacking blocks to concatenate, a funnel to filter,
scissors to trim, and so on. Colors are the placeholder keys that
`HomeIllustrationColors` swaps for theme colors.

Run from the repository root:

    python3 scripts/illustrations/tool_scenes.py

Writes `assets/images/tools/<tool>.svg`, named after `HomeTool.scene` in
`lib/services/home_features.dart`, and the standalone gull
`assets/images/quick_start_gull.svg` used on the quick start page.
"""

import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "images" / "tools"

LINE = "#005224"
ACCENT = "#FFD64F"
FILL = "#FFFFFF"

WIDTH = 1200
HEIGHT = 160
# Ground height under the gull and its prop.
GROUND = 134

# The gull from the home illustration, in a 96 x 96 box.
GULL_BODY = (
    "M36,50 C42,46 48,44 56,44 C60,44 63,42 64,38 C65,33 70,31 74,33 "
    "C77,35 77,40 75,43 C73,47 72,50 71,54 C69,59 62,61 54,60 "
    "C46,59 40,55 36,50 Z"
)
GULL_BEAK = "M76,37.5 L85,39.5 L75.5,42 Z"
WING_FOLDED = "M62,49 C56,44.5 46,44 35,47 C41,52.5 52,54.5 62,51.5 Z"
WING_TIP = "M35,47 C38.5,46 42,45.5 45,45.6 L41.5,51 C39,50.2 36.8,48.8 35,47 Z"
WING_RAISED = "M60,47 C55,38 48,28 38,20 C41,32 46,43 56,51 Z"
LEGS = "M58,59.5 V70 M63,59 V70 M55,70 H60 M61,70 H66"
SCALE = 1.4


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, (group, pose, prop) in SCENES.items():
        drawn = prop()
        check_prop_box(name, drawn)
        svg = scene(group, pose, drawn)
        (OUTPUT / f"{name}.svg").write_text(svg, encoding="utf-8")
    gull_svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="30 28 60 46">'
        f'<g fill="none" stroke="{LINE}" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round">'
        f'{gull_figure("stand")}</g></svg>\n'
    )
    (ROOT / "assets" / "images" / "quick_start_gull.svg").write_text(gull_svg, encoding="utf-8")
    print(f"Wrote {len(SCENES)} scenes to {OUTPUT.relative_to(ROOT)}")


def scene(group: str, pose: str, prop: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}">'
        f'<g fill="none" stroke="{LINE}" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round">'
        f"{field()}{GROUP_ORNAMENTS[group]()}{prop}{gull(pose)}</g></svg>\n"
    )


def field() -> str:
    """Rolling ground, a horizon, grass, and a cloud."""
    return (
        '<path d="M0,140 C150,126 260,132 400,136 C560,140 640,124 800,130 '
        'C960,136 1060,126 1200,132"/>'
        '<path d="M0,156 H1200"/>'
        '<path d="M300,152 l6,-4 M320,148 l6,-4 M340,152 l6,-4 '
        'M620,150 l6,-4 M640,146 l6,-4" stroke-width="2.5"/>'
        f'<path d="M420,40 H460 C465,40 466,32 460,31 C459,24 448,22 445,29 '
        f'C442,24 432,26 432,33 C426,33 420,36 420,40 Z" fill="{FILL}" stroke-width="2.5"/>'
    )


# Group ornaments stand on the left of the field, around x = 150, and rise
# about as high as the tree (y = 66).
OX = 150
OGROUND = 138


def small_tree() -> str:
    """Trees: a tree with square branches, like a cladogram, and yellow tips."""
    return (
        '<path d="M150,138 V110 M150,110 H128 V92 M150,110 H174 V86 '
        'M128,92 H118 V80 M128,92 H138 V76 M174,86 H164 V72 M174,86 H186 V74"/>'
        f'<g fill="{ACCENT}" stroke-width="2.5"><circle cx="118" cy="76" r="5"/>'
        '<circle cx="138" cy="72" r="5"/><circle cx="164" cy="68" r="5"/>'
        '<circle cx="186" cy="70" r="5"/></g>'
    )


def dna_vine() -> str:
    """Genomics: a DNA helix growing out of the ground like a vine."""
    return (
        helix(OX, OGROUND, h=72, radius=16, pitch=72)
        + f'<path d="M{OX - 14},{OGROUND} C{OX - 24},{OGROUND - 4} {OX - 30},{OGROUND - 12} '
        f'{OX - 28},{OGROUND - 18} C{OX - 20},{OGROUND - 16} {OX - 14},{OGROUND - 8} '
        f'{OX - 12},{OGROUND - 2}" fill="{ACCENT}" stroke-width="2.5"/>'
        f'<path d="M{OX + 12},{OGROUND - 2} C{OX + 18},{OGROUND - 10} {OX + 26},{OGROUND - 14} '
        f'{OX + 32},{OGROUND - 12} C{OX + 30},{OGROUND - 4} {OX + 22},{OGROUND} '
        f'{OX + 14},{OGROUND}" fill="{FILL}" stroke-width="2.5"/>'
    )


def stone_wall() -> str:
    """Alignments: a dry-stone wall, rows of stones like an alignment matrix."""
    width = 84
    left = OX - width // 2
    h = 12
    # Each row: stone widths, with 0 for a gap. Rows are offset like bricks.
    layout = [
        [16, 22, 18, 28],
        [24, 18, 0, 26],
        [14, 26, 20, 24],
        [22, 0, 24, 22],
        [18, 24, 26, 16],
    ]
    accents = {(0, 1), (1, 3), (2, 0), (2, 2), (3, 2), (4, 1)}
    stones = ""
    for r, row in enumerate(layout):
        y = OGROUND - (r + 1) * h
        x = left
        for c, w in enumerate(row):
            if w:
                fill = ACCENT if (r, c) in accents else FILL
                stones += (
                    f'<rect x="{x}" y="{y}" width="{w - 2}" height="{h - 2}" rx="3" '
                    f'fill="{fill}" stroke-width="2.5"/>'
                )
            else:
                w = 18
            x += w
    return stones


def bunting() -> str:
    """Sequences: a line of flags between two posts, one flag per sample."""
    x1, x2 = OX - 42, OX + 42
    top = OGROUND - 64
    sag = 18
    flags = ""
    count = 5
    for i in range(count):
        t = (i + 0.5) / count
        tn = t + 0.5 / count * 0.9
        t0 = t - 0.5 / count * 0.9

        def point(u):
            # Quadratic curve from (x1, top) through control (OX, top + 2 * sag).
            x = (1 - u) ** 2 * x1 + 2 * (1 - u) * u * OX + u ** 2 * x2
            y = (1 - u) ** 2 * top + 2 * (1 - u) * u * (top + 2 * sag) + u ** 2 * top
            return x, y

        a, b, m = point(t0), point(tn), point(t)
        fill = ACCENT if i % 2 == 0 else FILL
        flags += (
            f'<path d="M{a[0]:.1f},{a[1]:.1f} L{b[0]:.1f},{b[1]:.1f} '
            f'L{m[0]:.1f},{m[1] + 18:.1f} Z" fill="{fill}" stroke-width="2.5"/>'
        )
    return (
        f'<path d="M{x1},{OGROUND} V{top - 6} M{x2},{OGROUND} V{top - 6}"/>'
        f'<path d="M{x1},{top} Q{OX},{top + 2 * sag} {x2},{top}" stroke-width="2"/>'
        f"{flags}"
    )


def gull(pose: str) -> str:
    """The gull at the right of the scene: standing, on a post, or flying."""
    if pose == "stand":
        x, y = 850, GROUND - 70 * SCALE
    elif pose == "post":
        x, y = 850, GROUND - 100 * SCALE
    else:
        x, y = 860, 10
    post = ""
    if pose == "post":
        # A signpost under the gull's feet.
        top = y + 70 * SCALE
        post = (
            f'<path d="M{x + 60 * SCALE:.0f},{top:.0f} V{GROUND + 2}"/>'
            f'<path d="M{x + 40 * SCALE:.0f},{top:.0f} H{x + 84 * SCALE:.0f}"/>'
        )
    return (
        f"{post}<g transform=\"translate({x:.0f} {y:.0f}) scale({SCALE})\">"
        f"{gull_figure(pose)}</g>"
    )


def gull_figure(pose: str) -> str:
    """The gull in its own 96 x 96 box."""
    wing = WING_RAISED if pose == "fly" else WING_FOLDED
    tip = "" if pose == "fly" else f'<path d="{WING_TIP}" fill="{LINE}" stroke-width="2"/>'
    legs = "" if pose == "fly" else f'<path d="{LEGS}" stroke-width="2.5"/>'
    return (
        f"{legs}"
        f'<path d="{GULL_BODY}" fill="{FILL}"/>'
        f'<path d="{GULL_BEAK}" fill="{ACCENT}" stroke-width="2"/>'
        f'<circle cx="71.5" cy="37" r="1.8" fill="{LINE}" stroke="none"/>'
        f'<path d="{wing}" fill="{FILL}"/>{tip}'
    )


# Props sit to the right of the gull, on the ground at GROUND, inside one box
# so every tool's prop reads at the same size.
PX = 1000
PROP_BOX = (PX - 14, GROUND - 62, PX + 96, GROUND + 6)


def block(x, y, w=26, h=14, fill=FILL):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{fill}"/>'


def sheet(x, y, w=34, h=42, lines=True):
    fold = 9
    body = (
        f'<path d="M{x},{y} h{w - fold} l{fold},{fold} v{h - fold} h{-w} Z" fill="{FILL}"/>'
        f'<path d="M{x + w - fold},{y} v{fold} h{fold}" stroke-width="2"/>'
    )
    if lines:
        body += (
            f'<path d="M{x + 7},{y + 18} H{x + w - 8} M{x + 7},{y + 26} H{x + w - 12} '
            f'M{x + 7},{y + 34} H{x + w - 10}" stroke-width="2"/>'
        )
    return body


def arrow(x1, y1, x2, y2):
    angle = math.atan2(y2 - y1, x2 - x1)
    left = (x2 - 8 * math.cos(angle - 0.5), y2 - 8 * math.sin(angle - 0.5))
    right = (x2 - 8 * math.cos(angle + 0.5), y2 - 8 * math.sin(angle + 0.5))
    return (
        f'<path d="M{x1},{y1} L{x2},{y2} M{left[0]:.1f},{left[1]:.1f} L{x2},{y2} '
        f'L{right[0]:.1f},{right[1]:.1f}" stroke-width="2.5"/>'
    )


def rows(x, y, lengths, gap=10, width=2.5):
    return "".join(
        f'<path d="M{x},{y + i * gap} H{x + n}" stroke-width="{width}"/>'
        for i, n in enumerate(lengths)
    )


def card(x, y, w, h):
    """A plain backing card so thin rows stand out from the grass."""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{FILL}" stroke-width="2.5"/>'


def bars(x, heights, width=10, gap=6, fill=ACCENT):
    return "".join(
        f'<rect x="{x + i * (width + gap)}" y="{GROUND - h}" width="{width}" height="{h}" '
        f'rx="2" fill="{fill}" stroke-width="2.5"/>'
        for i, h in enumerate(heights)
    )


def concatenate():
    return (
        block(PX - 6, GROUND - 52, fill=ACCENT)
        + block(PX + 40, GROUND - 52)
        + arrow(PX + 7, GROUND - 34, PX + 22, GROUND - 22)
        + arrow(PX + 53, GROUND - 34, PX + 38, GROUND - 22)
        + block(PX, GROUND - 16, w=60, fill=FILL)
        + f'<path d="M{PX + 30},{GROUND - 16} V{GROUND - 2}" stroke-width="2.5"/>'
        + f'<rect x="{PX}" y="{GROUND - 16}" width="30" height="14" rx="3" fill="{ACCENT}"/>'
    )


def convert():
    return (
        sheet(PX - 6, GROUND - 44)
        + sheet(PX + 46, GROUND - 44)
        + arrow(PX + 32, GROUND - 34, PX + 44, GROUND - 34)
        + arrow(PX + 44, GROUND - 14, PX + 32, GROUND - 14)
    )


def distance():
    return (
        f'<circle cx="{PX}" cy="{GROUND - 8}" r="7" fill="{ACCENT}"/>'
        f'<circle cx="{PX + 76}" cy="{GROUND - 8}" r="7" fill="{FILL}"/>'
        + arrow(PX + 38, GROUND - 30, PX + 4, GROUND - 30)
        + arrow(PX + 38, GROUND - 30, PX + 72, GROUND - 30)
        + f'<path d="M{PX},{GROUND - 38} V{GROUND - 22} M{PX + 76},{GROUND - 38} '
        f'V{GROUND - 22}" stroke-width="2"/>'
    )


def funnel(x, y, w=44):
    return (
        f'<path d="M{x},{y} H{x + w} L{x + w * 0.62:.0f},{y + 22} V{y + 36} '
        f'L{x + w * 0.38:.0f},{y + 42} V{y + 22} Z" fill="{FILL}"/>'
    )


def filter_alignments():
    return (
        block(PX + 2, GROUND - 60, w=16, h=10, fill=ACCENT)
        + block(PX + 23, GROUND - 60, w=16, h=10)
        + block(PX + 44, GROUND - 60, w=16, h=10, fill=ACCENT)
        + funnel(PX, GROUND - 46, w=62)
        + f'<circle cx="{PX + 31}" cy="{GROUND}" r="3" fill="{ACCENT}"/>'
    )


def partition():
    return (
        block(PX - 4, GROUND - 16, w=84, fill=FILL)
        + f'<rect x="{PX - 4}" y="{GROUND - 16}" width="28" height="14" rx="3" fill="{ACCENT}"/>'
        + f'<path d="M{PX + 52},{GROUND - 16} V{GROUND - 2}" stroke-width="2.5"/>'
        + f'<path d="M{PX - 4},{GROUND - 26} v-6 h28 v6 M{PX + 26},{GROUND - 26} v-6 h24 v6 '
        f'M{PX + 54},{GROUND - 26} v-6 h26 v6" stroke-width="2"/>'
    )


def split():
    return (
        block(PX + 6, GROUND - 52, w=60, fill=FILL)
        + f'<rect x="{PX + 6}" y="{GROUND - 52}" width="30" height="14" rx="3" fill="{ACCENT}"/>'
        + arrow(PX + 22, GROUND - 34, PX + 8, GROUND - 22)
        + arrow(PX + 50, GROUND - 34, PX + 64, GROUND - 22)
        + block(PX - 10, GROUND - 16, w=30, fill=ACCENT)
        + block(PX + 52, GROUND - 16, w=30)
    )


def magnifier(x, y, r=13):
    return (
        f'<circle cx="{x}" cy="{y}" r="{r}" fill="{FILL}"/>'
        f'<path d="M{x + r * 0.7:.0f},{y + r * 0.7:.0f} l12,12" stroke-width="4"/>'
    )


def summary():
    return (
        card(PX - 12, GROUND - 54, 76, 54)
        + rows(PX - 2, GROUND - 42, [56, 38, 48, 26], width=3)
        + magnifier(PX + 58, GROUND - 22)
    )


def trim():
    return (
        block(PX - 6, GROUND - 16, w=80, fill=FILL)
        + f'<path d="M{PX + 30},{GROUND - 22} V{GROUND + 4}" stroke-dasharray="4 4" stroke-width="2"/>'
        + f'<circle cx="{PX + 22}" cy="{GROUND - 48}" r="6" fill="{FILL}"/>'
        + f'<circle cx="{PX + 38}" cy="{GROUND - 48}" r="6" fill="{FILL}"/>'
        + f'<path d="M{PX + 25},{GROUND - 43} L{PX + 34},{GROUND - 24} '
        f'M{PX + 35},{GROUND - 43} L{PX + 26},{GROUND - 24}" stroke-width="2.5"/>'
    )


def beads(x, y, count, fill=ACCENT, step=14):
    return "".join(
        f'<circle cx="{x + i * step}" cy="{y}" r="5" fill="{fill if i % 2 == 0 else FILL}" '
        'stroke-width="2.5"/>'
        for i in range(count)
    )


def unalign():
    return (
        f'<path d="M{PX - 6},{GROUND - 40} H{PX + 74}" stroke-width="2"/>'
        + beads(PX, GROUND - 40, 3)
        + beads(PX + 50, GROUND - 40, 2, step=18)
        + arrow(PX + 34, GROUND - 30, PX + 34, GROUND - 18)
        + beads(PX + 6, GROUND - 8, 5, step=13)
    )


def read_summary():
    return bars(PX - 4, [18, 30, 44, 38, 26, 14])


def contig_summary():
    return card(PX - 12, GROUND - 56, 100, 56) + rows(
        PX - 2, GROUND - 46, [80, 62, 46, 28, 14], gap=9, width=3
    )


def maf_blocks(x, y):
    return (
        block(x, y, w=24, h=10, fill=ACCENT)
        + block(x, y + 14, w=24, h=10)
        + block(x + 30, y + 6, w=20, h=10)
        + block(x + 30, y + 20, w=20, h=10, fill=ACCENT)
    )


def maf_convert():
    return maf_blocks(PX - 10, GROUND - 32) + arrow(PX + 44, GROUND - 18, PX + 56, GROUND - 18) + sheet(
        PX + 60, GROUND - 44
    )


def maf_summary():
    return maf_blocks(PX - 10, GROUND - 32) + bars(PX + 50, [16, 30, 22], width=8, gap=5)


def add():
    return sheet(PX + 4, GROUND - 44, w=40, h=44) + (
        f'<circle cx="{PX + 46}" cy="{GROUND - 44}" r="11" fill="{ACCENT}"/>'
        f'<path d="M{PX + 46},{GROUND - 50} V{GROUND - 38} M{PX + 40},{GROUND - 44} '
        f'H{PX + 52}" stroke-width="2.5"/>'
    )


def extract():
    return (
        sheet(PX - 6, GROUND - 44, w=40, h=44)
        + arrow(PX + 28, GROUND - 22, PX + 56, GROUND - 22)
        + block(PX + 58, GROUND - 29, w=28, fill=ACCENT)
    )


def tag(x, y, text_lines=2):
    return (
        f'<path d="M{x},{y} H{x + 46} L{x + 58},{y + 12} L{x + 46},{y + 24} H{x} Z" fill="{FILL}"/>'
        f'<circle cx="{x + 46}" cy="{y + 12}" r="2.5" fill="{ACCENT}"/>'
        + rows(x + 7, y + 8, [26, 18][:text_lines], gap=8)
    )


def extract_id():
    return tag(PX - 4, GROUND - 52) + tag(PX + 14, GROUND - 24)


def sequence_filter():
    return (
        card(PX - 12, GROUND - 52, 44, 40)
        + rows(PX - 4, GROUND - 42, [28, 28, 28], gap=10, width=3)
        + funnel(PX + 40, GROUND - 46, w=44)
    )


def remove():
    return (
        card(PX - 12, GROUND - 52, 90, 52)
        + rows(PX - 2, GROUND - 40, [70, 30, 70], gap=14, width=3)
        + f'<path d="M{PX + 42},{GROUND - 33} l12,12 M{PX + 54},{GROUND - 33} l-12,12" '
        'stroke-width="3"/>'
    )


def rename():
    return tag(PX - 6, GROUND - 40) + (
        f'<path d="M{PX + 62},{GROUND - 10} L{PX + 86},{GROUND - 52} L{PX + 92},{GROUND - 48} '
        f'L{PX + 68},{GROUND - 6} Z" fill="{ACCENT}" stroke-width="2.5"/>'
    )


def helix(x, base, h=60, radius=12, pitch=60, offset=135):
    """A right-handed DNA helix centered on `x`, rising `h` from `base`.

    The backbones sit `offset` degrees apart around the axis, as in B-DNA,
    rather than opposite each other. Each strand is split into the half facing
    the viewer and a dimmed half behind the axis, so the front halves show the
    minor and major grooves alternating. Both strands cross at the base, and
    base pairs sit in each lobe between crossings.
    """
    omega = 2 * math.pi / pitch
    half = math.radians(offset) / 2

    def angle(t):
        return omega * t + math.pi / 2

    def strand(phase):
        paths = {"front": "", "back": ""}
        previous = None
        steps = int(h / 2)
        for i in range(steps + 1):
            t = h * i / steps
            theta = angle(t) + phase
            # Split where the strand passes behind the axis.
            side = "front" if math.cos(angle(t + h / steps / 2) + phase) > 0 else "back"
            point = f"{x + radius * math.sin(theta):.1f},{base - t:.1f}"
            if side == previous:
                paths[side] += f" {point}"
            else:
                # Close the previous half at this point, then start the next.
                if previous is not None:
                    paths[previous] += f" {point}"
                paths[side] += f" M{point}"
            previous = side
        return paths

    strands = [strand(half), strand(-half)]
    rungs = ""
    for center in range(int(pitch / 4), int(h), int(pitch / 2)):
        for shift in (-6, 0, 6):
            t = center + shift
            x1 = x + radius * math.sin(angle(t) + half)
            x2 = x + radius * math.sin(angle(t) - half)
            rungs += f"M{x1:.1f},{base - t:.1f} H{x2:.1f} "
    back = "".join(f'<path d="{s["back"].strip()}" stroke-width="2.5" opacity="0.45"/>'
                   for s in strands)
    front = "".join(f'<path d="{s["front"].strip()}" stroke-width="2.5"/>' for s in strands)
    return f'{back}<path d="{rungs.strip()}" stroke-width="2"/>{front}'


def translate():
    # Three nucleotides make a codon, which becomes one amino acid.
    codon = "".join(
        block(PX - 10 + i * 13, GROUND - 40, w=12, h=16, fill=ACCENT if i == 1 else FILL)
        for i in range(3)
    )
    return (
        codon
        + f'<path d="M{PX - 10},{GROUND - 18} H{PX + 28}" stroke-width="2"/>'
        + arrow(PX + 36, GROUND - 32, PX + 52, GROUND - 32)
        + beads(PX + 62, GROUND - 32, 3, step=13)
    )


def transpose():
    return (
        block(PX - 6, GROUND - 56, w=60, fill=ACCENT)
        + f'<rect x="{PX - 6}" y="{GROUND - 36}" width="14" height="36" rx="3" fill="{FILL}"/>'
        + f'<path d="M{PX + 60},{GROUND - 32} V{GROUND - 18} Q{PX + 60},{GROUND - 6} '
        f'{PX + 46},{GROUND - 6} H{PX + 20}" stroke-width="2.5"/>'
        + arrow(PX + 28, GROUND - 6, PX + 18, GROUND - 6)
    )


def cladogram(x, y):
    """A small rooted tree with three tips."""
    return (
        f'<path d="M{x + 30},{y} H{x + 18} V{y + 16} H{x + 30} '
        f'M{x + 18},{y + 8} H{x + 6} V{y + 32} H{x + 30} M{x},{y + 20} H{x + 6}" '
        'stroke-width="2.5"/>'
        + "".join(
            f'<circle cx="{x + 34}" cy="{y + dy}" r="4" fill="{ACCENT}" stroke-width="2.5"/>'
            for dy in (0, 16, 32)
        )
    )


def tree_convert():
    return cladogram(PX - 10, GROUND - 40) + arrow(PX + 34, GROUND - 22, PX + 54, GROUND - 22) + sheet(
        PX + 60, GROUND - 44
    )


# Tool key: (group, gull pose, prop). Keys match `HomeTool.scene` in
# `lib/services/home_features.dart`.
SCENES = {
    "read_summary": ("genomics", "stand", read_summary),
    "contig_summary": ("genomics", "post", contig_summary),
    "maf_conversion": ("genomics", "fly", maf_convert),
    "maf_summary": ("genomics", "stand", maf_summary),
    "concatenation": ("alignment", "stand", concatenate),
    "conversion": ("alignment", "post", convert),
    "distance": ("alignment", "stand", distance),
    "filter": ("alignment", "fly", filter_alignments),
    "partition": ("alignment", "post", partition),
    "split": ("alignment", "stand", split),
    "summary": ("alignment", "post", summary),
    "trimming": ("alignment", "stand", trim),
    "unalignment": ("alignment", "fly", unalign),
    "addition": ("sequence", "fly", add),
    "extraction": ("sequence", "stand", extract),
    "id_extraction": ("sequence", "post", extract_id),
    "sequence_filtering": ("sequence", "stand", sequence_filter),
    "removal": ("sequence", "post", remove),
    "renaming": ("sequence", "stand", rename),
    "translation": ("sequence", "post", translate),
    "transposition": ("sequence", "stand", transpose),
    "tree_conversion": ("tree", "post", tree_convert),
}

GROUP_ORNAMENTS = {
    "genomics": dna_vine,
    "alignment": stone_wall,
    "sequence": bunting,
    "tree": small_tree,
}


def prop_points(svg: str):
    """Yield the (x, y) points a prop draws, enough to check its bounds."""
    for match in re.finditer(r"<(rect|circle|path)([^>]*)/>", svg):
        kind, attrs = match.groups()
        values = dict(re.findall(r'([\w-]+)="([^"]*)"', attrs))
        if kind == "rect":
            x, y = float(values["x"]), float(values["y"])
            yield x, y
            yield x + float(values["width"]), y + float(values["height"])
        elif kind == "circle":
            cx, cy, r = (float(values[k]) for k in ("cx", "cy", "r"))
            yield cx - r, cy - r
            yield cx + r, cy + r
        else:
            x = y = 0.0
            for command, args in re.findall(r"([MLHVCQZmlhvcqz])([^MLHVCQZmlhvcqz]*)", values["d"]):
                nums = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", args)]
                if command in "HhVv":
                    for n in nums:
                        if command == "H":
                            x = n
                        elif command == "h":
                            x += n
                        elif command == "V":
                            y = n
                        else:
                            y += n
                        yield x, y
                    continue
                for i in range(0, len(nums) - 1, 2):
                    if command.isupper():
                        x, y = nums[i], nums[i + 1]
                    else:
                        x, y = x + nums[i], y + nums[i + 1]
                    yield x, y


def check_prop_box(name: str, prop: str) -> None:
    """Warn when a prop draws outside `PROP_BOX`."""
    left, top, right, bottom = PROP_BOX
    for x, y in prop_points(prop):
        if not (left <= x <= right and top <= y <= bottom):
            print(f"warning: {name} prop reaches ({x:.0f}, {y:.0f}) outside {PROP_BOX}")
            return

if __name__ == "__main__":
    main()
