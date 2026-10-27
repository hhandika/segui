"""Export the website's feature diagrams as standalone SVGs for SEGUI.

The website draws each diagram with CSS classes from
`website/src/components/features/Figure.astro`. Flutter's SVG renderer
ignores CSS, so this script resolves every class into SVG attributes.
Theme colors become placeholder keys that SEGUI swaps for its own theme
colors at runtime (see `FeatureDiagramColors` in
`lib/screens/shared/feature_diagram.dart`).

Build the website first, then run from the repository root:

    (cd website && bun run build)
    python3 scripts/illustrations/export_feature_diagrams.py
"""

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "website" / "dist" / "docs" / "features" / "index.html"
OUTPUT = ROOT / "assets" / "images" / "features"
SVG_NS = "http://www.w3.org/2000/svg"

# Placeholder colors. Keep in sync with `FeatureDiagramColors`.
TEXT = "#010203"
MUTED = "#040506"
ACCENT = "#070809"
ACCENT_LOW = "#0a0b0c"
PANEL = "#0d0e0f"
OUTLINE = "#101112"
GAP = "#131415"

SANS = "sans-serif"
MONO = "monospace"

# Rules in the order of Figure.astro's stylesheet. Later rules win, like CSS.
RULES = [
    ({"fx-mono"}, {"font-family": MONO}),
    ({"fx-title"}, {"font-size": "15", "font-weight": "700"}),
    ({"fx-muted"}, {"fill": MUTED, "font-size": "13"}),
    ({"fx-small"}, {"font-size": "12"}),
    ({"fx-accent-text"}, {"fill": ACCENT, "font-weight": "700"}),
    ({"fx-danger-text"}, {"fill": "#d9534f", "font-weight": "700"}),
    ({"fx-panel"}, {"fill": PANEL, "stroke": OUTLINE, "stroke-width": "1.5"}),
    ({"fx-panel-accent"}, {"fill": ACCENT_LOW, "stroke": ACCENT, "stroke-width": "1.5"}),
    (
        {"fx-line"},
        {
            "fill": "none",
            "stroke": MUTED,
            "stroke-width": "2",
            "stroke-linecap": "round",
            "stroke-linejoin": "round",
        },
    ),
    (
        {"fx-line-accent"},
        {"fill": "none", "stroke": ACCENT, "stroke-width": "2", "stroke-linecap": "round"},
    ),
    ({"fx-dashed"}, {"stroke-dasharray": "5 4"}),
    ({"fx-head"}, {"fill": MUTED}),
    ({"fx-faded"}, {"opacity": "0.35"}),
    ({"fx-A"}, {"fill": "#00843f"}),
    ({"fx-C"}, {"fill": "#2565b0"}),
    ({"fx-G"}, {"fill": "#ffc423"}),
    ({"fx-T"}, {"fill": "#c0392b"}),
    ({"fx-N"}, {"fill": "#6b7280"}),
    ({"fx-aa"}, {"fill": "#5e7a3a"}),
    ({"fx-l1"}, {"fill": "#009245"}),
    ({"fx-l2"}, {"fill": "#ffd64f"}),
    ({"fx-l3"}, {"fill": "#1f7f6b"}),
    ({"fx-on"}, {"fill": ACCENT}),
    ({"fx-gap"}, {"fill": "none", "stroke": GAP, "stroke-width": "1"}),
    ({"fx-cell-text"}, {"fill": "#ffffff", "font-family": MONO, "font-weight": "700"}),
    ({"fx-cell-text", "fx-dark"}, {"fill": "#3a2a00"}),
    ({"fx-cell-text", "fx-gap-text"}, {"fill": MUTED, "font-weight": "400"}),
]
TEXT_DEFAULTS = {"font-family": SANS, "font-size": "14", "fill": TEXT}


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing {SOURCE}. Build the website first.", file=sys.stderr)
        return 1
    html = SOURCE.read_text(encoding="utf-8")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    ids = re.findall(r'<title id="([a-z0-9-]+)-title"', html)
    for figure_id in ids:
        svg = extract_svg(html, figure_id)
        (OUTPUT / f"{figure_id}.svg").write_text(svg, encoding="utf-8")
    print(f"Exported {len(ids)} diagrams to {OUTPUT.relative_to(ROOT)}")
    return 0


def extract_svg(html: str, figure_id: str) -> str:
    title = html.index(f'id="{figure_id}-title"')
    start = html.rfind("<svg", 0, title)
    end = html.index("</svg>", title) + len("</svg>")
    ET.register_namespace("", SVG_NS)
    root = ET.fromstring(html[start:end])
    for attr in ("style", "role", "aria-labelledby"):
        root.attrib.pop(attr, None)
    resolve(root, {})
    return ET.tostring(root, encoding="unicode") + "\n"


def resolve(element: ET.Element, inherited: dict) -> None:
    """Replace classes and inline styles with attributes on every element."""
    tag = element.tag.split("}")[-1]
    classes = set(element.attrib.pop("class", "").split())
    style = parse_style(element.attrib.pop("style", ""))
    attributes = dict(TEXT_DEFAULTS) if tag == "text" else {}
    for selector, values in RULES:
        if selector <= classes:
            attributes.update(values)
    attributes.update(style)
    for key in [k for k in element.attrib if k.startswith("data-")]:
        del element.attrib[key]
    for key, value in attributes.items():
        element.set(key, value)
    if tag == "text" and element.attrib.pop("dominant-baseline", None) == "central":
        # Flutter ignores dominant-baseline. Shift the baseline down instead.
        size = float(element.get("font-size", "14").replace("px", ""))
        element.set("dy", f"{size * 0.35:.1f}")
    for child in element:
        resolve(child, attributes)


def parse_style(style: str) -> dict:
    values = {}
    for declaration in style.split(";"):
        if ":" in declaration:
            key, value = declaration.split(":", 1)
            values[key.strip()] = value.strip().replace("px", "")
    return values


if __name__ == "__main__":
    sys.exit(main())
