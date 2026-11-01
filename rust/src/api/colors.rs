//! Chart, table, and alignment colors from the SEGUL color library
//! (`segul_core::color`), so SEGUI draws the same colors as SEGUL plots and
//! terminal viewers.
//!
//! Colors cross the bridge as `0xAARRGGBB` integers, the layout of Flutter's
//! `Color`. Palette, colormap, and scheme names are the SEGUL names, such as
//! `dark2` (the default palette) or `viridis`.
use anyhow::anyhow;
use flutter_rust_bridge::frb;
use segul_core::color::residue::{ResiduePalette, ResidueScheme};
use segul_core::color::ui::StatusColors;
use segul_core::color::{self, Colormap, ColormapKind, CvdKind, Palette, Rgb, Theme, NON_TEXT};
use segul_core::helper::types::DataType;

/// A choice in a settings list.
pub struct ColorOption {
    /// SEGUL name, saved in preferences.
    pub name: String,
    /// Name shown to the user.
    pub label: String,
}

/// A categorical palette and how colorblind safe it is.
pub struct PaletteOption {
    pub name: String,
    pub label: String,
    /// Distinct colors before the palette repeats.
    pub size: u32,
    /// Colors, from the start, that stay distinct with color vision
    /// deficiencies.
    pub colorblind_safe: u32,
}

/// A continuous colormap.
pub struct ColormapOption {
    pub name: String,
    pub label: String,
    pub diverging: bool,
}

/// Series colors for a chart background.
pub struct PaletteColors {
    /// Published palette colors, for bars, areas, and swatches.
    pub fill: Vec<u32>,
    /// Fills adjusted to reach 3:1 against the background, for lines,
    /// points, and outlines (WCAG 2.2 SC 1.4.11).
    pub line: Vec<u32>,
}

/// Quality status colors, as fills and as lines that reach 3:1.
pub struct StatusColorsData {
    pub pass: u32,
    pub warn: u32,
    pub fail: u32,
    pub open: u32,
    pub outlier: u32,
    pub pass_line: u32,
    pub warn_line: u32,
    pub fail_line: u32,
    pub open_line: u32,
    pub outlier_line: u32,
}

/// Every color an alignment viewer needs. Groups are in legend order.
pub struct ResidueColors {
    pub group_labels: Vec<String>,
    /// Residue letters of each group, such as `AILMFWV`.
    pub group_codes: Vec<String>,
    pub group_colors: Vec<u32>,
    pub fallback: u32,
    pub gap: u32,
    pub on_residue: u32,
    pub mono: u32,
    pub identity: u32,
    pub on_identity: u32,
    pub accent: u32,
    pub tertiary: u32,
    pub selection: u32,
    /// Largest share of `selection` to mix into a cell.
    pub max_wash: f64,
}

#[frb(sync)]
pub fn palette_options() -> Vec<PaletteOption> {
    Palette::all()
        .iter()
        .map(|p| PaletteOption {
            name: p.to_string(),
            label: p.label().to_string(),
            size: p.len() as u32,
            colorblind_safe: p.colorblind_safe_classes() as u32,
        })
        .collect()
}

#[frb(sync)]
pub fn colormap_options() -> Vec<ColormapOption> {
    Colormap::all()
        .iter()
        .map(|c| ColormapOption {
            name: c.to_string(),
            label: c.label().to_string(),
            diverging: c.kind() == ColormapKind::Diverging,
        })
        .collect()
}

#[frb(sync)]
pub fn residue_scheme_options() -> Vec<ColorOption> {
    ResidueScheme::all()
        .iter()
        .map(|s| ColorOption {
            name: s.to_string(),
            label: s.label().to_string(),
        })
        .collect()
}

#[frb(sync)]
pub fn cvd_options() -> Vec<ColorOption> {
    CvdKind::all()
        .iter()
        .map(|k| ColorOption {
            name: k.to_string(),
            label: k.label().to_string(),
        })
        .collect()
}

/// The first `n` colors of a palette, with line colors for `background`.
#[frb(sync)]
pub fn palette_colors(name: String, n: u32, background: u32) -> anyhow::Result<PaletteColors> {
    let palette = name.parse::<Palette>().map_err(|e| anyhow!(e))?;
    let background = Rgb::from_argb(background);
    let fills = palette.colors(n as usize);
    let line = fills
        .iter()
        .map(|c| color::ensure_contrast(*c, background, NON_TEXT).to_argb())
        .collect();
    Ok(PaletteColors {
        fill: fills.iter().map(Rgb::to_argb).collect(),
        line,
    })
}

/// `n` evenly spaced colors of a colormap, from low to high.
#[frb(sync)]
pub fn colormap_stops(name: String, n: u32) -> anyhow::Result<Vec<u32>> {
    let colormap = name.parse::<Colormap>().map_err(|e| anyhow!(e))?;
    Ok(colormap
        .stops(n as usize)
        .iter()
        .map(Rgb::to_argb)
        .collect())
}

#[frb(sync)]
pub fn status_colors(background: u32) -> StatusColorsData {
    let background = Rgb::from_argb(background);
    let s = StatusColors::default();
    let line = |c: Rgb| color::ensure_contrast(c, background, NON_TEXT).to_argb();
    StatusColorsData {
        pass: s.pass.to_argb(),
        warn: s.warn.to_argb(),
        fail: s.fail.to_argb(),
        open: s.open.to_argb(),
        outlier: s.outlier.to_argb(),
        pass_line: line(s.pass),
        warn_line: line(s.warn),
        fail_line: line(s.fail),
        open_line: line(s.open),
        outlier_line: line(s.outlier),
    }
}

#[frb(sync)]
pub fn residue_colors(scheme: String, dark: bool, is_dna: bool) -> anyhow::Result<ResidueColors> {
    let scheme = scheme.parse::<ResidueScheme>().map_err(|e| anyhow!(e))?;
    let theme = if dark { Theme::Dark } else { Theme::Light };
    let datatype = if is_dna { DataType::Dna } else { DataType::Aa };
    let palette = ResiduePalette::new(&scheme, &theme, &datatype);
    Ok(ResidueColors {
        group_labels: palette.groups.iter().map(|g| g.label.to_string()).collect(),
        group_codes: palette
            .groups
            .iter()
            .map(|g| String::from_utf8_lossy(g.codes).into_owned())
            .collect(),
        group_colors: palette.groups.iter().map(|g| g.color.to_argb()).collect(),
        fallback: palette.fallback.to_argb(),
        gap: palette.gap.to_argb(),
        on_residue: palette.on_residue.to_argb(),
        mono: palette.mono.to_argb(),
        identity: palette.identity.to_argb(),
        on_identity: palette.on_identity.to_argb(),
        accent: palette.accent.to_argb(),
        tertiary: palette.tertiary.to_argb(),
        selection: palette.selection.to_argb(),
        max_wash: ResiduePalette::MAX_WASH,
    })
}

/// WCAG 2.2 contrast ratio, from 1 to 21. Alpha is ignored.
#[frb(sync)]
pub fn contrast_ratio(a: u32, b: u32) -> f64 {
    color::contrast_ratio(Rgb::from_argb(a), Rgb::from_argb(b))
}

/// `color` darkened or lightened until it reaches `min` against `background`.
#[frb(sync)]
pub fn ensure_contrast(color: u32, background: u32, min: f64) -> u32 {
    color::ensure_contrast(Rgb::from_argb(color), Rgb::from_argb(background), min).to_argb()
}

/// Black or white, whichever reads better on `background`.
#[frb(sync)]
pub fn best_text_on(background: u32) -> u32 {
    color::best_text_on(Rgb::from_argb(background)).to_argb()
}

/// `color` as seen with a color vision deficiency, such as `deuteranopia`.
#[frb(sync)]
pub fn simulate_cvd(color: u32, kind: String) -> anyhow::Result<u32> {
    let kind = kind.parse::<CvdKind>().map_err(|e| anyhow!(e))?;
    Ok(color::simulate_cvd(Rgb::from_argb(color), &kind, 1.0).to_argb())
}

#[cfg(test)]
mod tests {
    use super::*;

    const WHITE: u32 = 0xFFFFFFFF;

    #[test]
    fn test_palette_lines_reach_contrast() {
        for option in palette_options() {
            let colors = palette_colors(option.name, option.size, WHITE).unwrap();
            assert_eq!(colors.fill.len(), option.size as usize);
            for line in colors.line {
                assert!(contrast_ratio(line, WHITE) >= NON_TEXT);
            }
        }
    }

    #[test]
    fn test_okabe_ito_starts_blue() {
        let colors = palette_colors("okabe-ito".to_string(), 1, WHITE).unwrap();
        assert_eq!(colors.fill[0], 0xFF0072B2);
    }

    #[test]
    fn test_colormap_stops() {
        let stops = colormap_stops("viridis".to_string(), 3).unwrap();
        assert_eq!(stops.len(), 3);
        assert_eq!(stops[0], 0xFF440154);
        assert!(colormap_stops("rainbow".to_string(), 3).is_err());
    }

    #[test]
    fn test_residue_colors() {
        let colors = residue_colors("clustal".to_string(), false, true).unwrap();
        assert_eq!(colors.group_labels, ["A", "C", "G", "T"]);
        assert_eq!(colors.group_codes[3], "TU");
        assert!(residue_colors("rainbow".to_string(), false, true).is_err());
    }

    #[test]
    fn test_simulate_cvd() {
        let gray = simulate_cvd(0xFFE69F00, "achromatopsia".to_string()).unwrap();
        let rgb = Rgb::from_argb(gray);
        assert_eq!(rgb.r, rgb.g);
        assert!(simulate_cvd(WHITE, "x".to_string()).is_err());
    }
}
