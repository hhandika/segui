"""Generate the gull scenes drawn along the bottom of each SEGUI tool page.

Every scene shares the field sketch of the home illustration and shows the
SEGUL gull with a prop for its tool: stacking blocks to concatenate, a funnel
to filter, scissors to trim, and so on. Colors are the placeholder keys that
`HomeIllustrationColors` swaps for theme colors.

Run from the repository root:

    python3 scripts/illustrations/tool_scenes.py

Writes `assets/images/tools/<tool>.svg`, named after `HomeTool.scene` in
`lib/services/home_features.dart`, and the standalone gull
`assets/images/quick_start_gull.svg` used on the quick start page.
"""

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
    for name, (pose, prop) in SCENES.items():
        svg = scene(pose, prop())
        (OUTPUT / f"{name}.svg").write_text(svg, encoding="utf-8")
    gull_svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="30 28 60 46">'
        f'<g fill="none" stroke="{LINE}" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round">'
        f'{gull_figure("stand")}</g></svg>\n'
    )
    (ROOT / "assets" / "images" / "quick_start_gull.svg").write_text(gull_svg, encoding="utf-8")
    print(f"Wrote {len(SCENES)} scenes to {OUTPUT.relative_to(ROOT)}")


def scene(pose: str, prop: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}">'
        f'<g fill="none" stroke="{LINE}" stroke-width="3" '
        'stroke-linecap="round" stroke-linejoin="round">'
        f"{field()}{prop}{gull(pose)}</g></svg>\n"
    )


def field() -> str:
    """Rolling ground, a horizon, grass, a small tree, and a cloud."""
    return (
        '<path d="M0,140 C150,126 260,132 400,136 C560,140 640,124 800,130 '
        'C960,136 1060,126 1200,132"/>'
        '<path d="M0,156 H1200"/>'
        '<path d="M300,152 l6,-4 M320,148 l6,-4 M340,152 l6,-4 '
        'M620,150 l6,-4 M640,146 l6,-4" stroke-width="2.5"/>'
        '<path d="M150,138 V110 M150,110 H128 V92 M150,110 H174 V86 '
        'M128,92 H118 V80 M128,92 H138 V76 M174,86 H164 V72 M174,86 H186 V74"/>'
        f'<g fill="{ACCENT}" stroke-width="2.5"><circle cx="118" cy="76" r="5"/>'
        '<circle cx="138" cy="72" r="5"/><circle cx="164" cy="68" r="5"/>'
        '<circle cx="186" cy="70" r="5"/></g>'
        f'<path d="M420,40 H460 C465,40 466,32 460,31 C459,24 448,22 445,29 '
        f'C442,24 432,26 432,33 C426,33 420,36 420,40 Z" fill="{FILL}" stroke-width="2.5"/>'
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


# Props sit to the right of the gull, on the ground at GROUND.
PX = 1000


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
    import math

    angle = math.atan2(y2 - y1, x2 - x1)
    left = (x2 - 8 * math.cos(angle - 0.5), y2 - 8 * math.sin(angle - 0.5))
    right = (x2 - 8 * math.cos(angle + 0.5), y2 - 8 * math.sin(angle + 0.5))
    return (
        f'<path d="M{x1},{y1} L{x2},{y2} M{left[0]:.1f},{left[1]:.1f} L{x2},{y2} '
        f'L{right[0]:.1f},{right[1]:.1f}" stroke-width="2.5"/>'
    )


def rows(x, y, lengths, gap=10):
    return "".join(
        f'<path d="M{x},{y + i * gap} H{x + n}" stroke-width="2.5"/>' for i, n in enumerate(lengths)
    )


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
        block(PX - 4, GROUND - 74, w=18, fill=ACCENT)
        + block(PX + 22, GROUND - 78, w=18)
        + block(PX + 46, GROUND - 74, w=18, fill=ACCENT)
        + funnel(PX, GROUND - 52, w=62)
        + f'<circle cx="{PX + 31}" cy="{GROUND - 4}" r="3" fill="{ACCENT}"/>'
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
    return rows(PX - 4, GROUND - 44, [64, 44, 56, 30]) + magnifier(PX + 50, GROUND - 26)


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
    return rows(PX - 4, GROUND - 40, [80, 62, 46, 28, 14], gap=9)


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
    return sheet(PX, GROUND - 44, w=40, h=44) + (
        f'<circle cx="{PX + 58}" cy="{GROUND - 54}" r="11" fill="{ACCENT}"/>'
        f'<path d="M{PX + 58},{GROUND - 60} V{GROUND - 48} M{PX + 52},{GROUND - 54} '
        f'H{PX + 64}" stroke-width="2.5"/>'
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
    return rows(PX - 6, GROUND - 46, [30, 30, 30], gap=10) + funnel(PX + 32, GROUND - 52, w=40)


def remove():
    return rows(PX - 6, GROUND - 44, [70, 40, 70], gap=14) + (
        f'<path d="M{PX + 46},{GROUND - 36} l14,14 M{PX + 60},{GROUND - 36} l-14,14" '
        'stroke-width="3"/>'
    )


def rename():
    return tag(PX - 6, GROUND - 40) + (
        f'<path d="M{PX + 62},{GROUND - 10} L{PX + 86},{GROUND - 52} L{PX + 92},{GROUND - 48} '
        f'L{PX + 68},{GROUND - 6} Z" fill="{ACCENT}" stroke-width="2.5"/>'
    )


def helix(x, y, h=48):
    return (
        f'<path d="M{x},{y} C{x + 18},{y + h * 0.25} {x + 18},{y + h * 0.25} {x},{y + h * 0.5} '
        f'C{x - 18},{y + h * 0.75} {x - 18},{y + h * 0.75} {x},{y + h}" stroke-width="2.5"/>'
        f'<path d="M{x},{y} C{x - 18},{y + h * 0.25} {x - 18},{y + h * 0.25} {x},{y + h * 0.5} '
        f'C{x + 18},{y + h * 0.75} {x + 18},{y + h * 0.75} {x},{y + h}" stroke-width="2.5"/>'
    )


def translate():
    # Rungs sit at the quarter points, where the two strands are widest.
    rungs = "".join(
        f'<path d="M{PX - 8},{GROUND - y} H{PX + 16}" stroke-width="2"/>' for y in (47, 17)
    )
    return (
        rungs
        + helix(PX + 4, GROUND - 62, h=60)
        + arrow(PX + 24, GROUND - 32, PX + 42, GROUND - 32)
        + beads(PX + 52, GROUND - 32, 3, step=13)
    )


def transpose():
    return (
        block(PX - 6, GROUND - 56, w=60, fill=ACCENT)
        + f'<rect x="{PX - 6}" y="{GROUND - 36}" width="14" height="36" rx="3" fill="{FILL}"/>'
        + f'<path d="M{PX + 60},{GROUND - 32} V{GROUND - 18} Q{PX + 60},{GROUND - 6} '
        f'{PX + 46},{GROUND - 6} H{PX + 20}" stroke-width="2.5"/>'
        + arrow(PX + 28, GROUND - 6, PX + 18, GROUND - 6)
    )


# Tool key: (gull pose, prop). Keys match `lib/services/tool_scenes.dart`.
SCENES = {
    "read_summary": ("stand", read_summary),
    "contig_summary": ("post", contig_summary),
    "maf_conversion": ("fly", maf_convert),
    "maf_summary": ("stand", maf_summary),
    "concatenation": ("stand", concatenate),
    "conversion": ("post", convert),
    "distance": ("stand", distance),
    "filter": ("fly", filter_alignments),
    "partition": ("post", partition),
    "split": ("stand", split),
    "summary": ("post", summary),
    "trimming": ("stand", trim),
    "unalignment": ("fly", unalign),
    "addition": ("fly", add),
    "extraction": ("stand", extract),
    "id_extraction": ("post", extract_id),
    "sequence_filtering": ("stand", sequence_filter),
    "removal": ("post", remove),
    "renaming": ("stand", rename),
    "translation": ("post", translate),
    "transposition": ("stand", transpose),
}


if __name__ == "__main__":
    main()
