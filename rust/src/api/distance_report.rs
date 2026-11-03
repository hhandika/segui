use std::path::Path;

use segul::stats::distance_report::{DistanceReport, PairStats};

/// Loads `distance-report.json` for the interactive distance report.
pub struct DistanceReportServices {
    pub path: String,
}

impl DistanceReportServices {
    pub fn new() -> DistanceReportServices {
        DistanceReportServices {
            path: String::new(),
        }
    }

    pub fn load(&self) -> anyhow::Result<DistanceReportData> {
        let report = DistanceReport::from_path(Path::new(&self.path))?;
        Ok(DistanceReportData::from(&report))
    }
}

// Counts are sent as f64 so Dart charts can use them directly. Missing
// statistics, such as the mean of a locus without pairs, are sent as NaN,
// so each column crosses the bridge as one typed list.

pub struct DistanceReportData {
    /// `dna` or `aa`.
    pub datatype: String,
    /// Distance model, such as `K2P`.
    pub model: String,
    pub summary: DistanceOverviewData,
    /// Width of each histogram bin, starting at zero.
    pub bin_width: f64,
    /// Pairwise distances in each bin, across loci.
    pub histogram: Vec<f64>,
    pub loci: DistanceLociData,
    pub samples: DistanceSamplesData,
    /// Mean distance between samples, or `None` for too many samples.
    pub matrix: Option<DistanceMatrixData>,
    /// `None` without grouping.
    pub groups: Option<DistanceGroupsData>,
}

pub struct DistanceOverviewData {
    pub loci: f64,
    pub samples: f64,
    pub pairs: f64,
    pub undefined_pairs: f64,
    pub min: f64,
    pub max: f64,
    pub mean: f64,
    pub sd: f64,
    pub median_locus_mean: f64,
    pub mean_compared_sites: f64,
    /// `None` without grouping.
    pub groups: Option<f64>,
    pub unassigned: f64,
}

/// One value per locus in each column, in the order of `names`.
pub struct DistanceLociData {
    pub names: Vec<String>,
    pub paths: Vec<String>,
    pub ntax: Vec<f64>,
    pub nchar: Vec<f64>,
    pub pairs: Vec<f64>,
    pub undefined_pairs: Vec<f64>,
    pub mean: Vec<f64>,
    pub median: Vec<f64>,
    pub sd: Vec<f64>,
    pub min: Vec<f64>,
    pub max: Vec<f64>,
    pub mean_compared_sites: Vec<f64>,
}

/// One value per sample in each column, in the order of `names`.
pub struct DistanceSamplesData {
    pub names: Vec<String>,
    /// Empty strings for samples without a group.
    pub groups: Vec<String>,
    pub loci: Vec<f64>,
    pub pairs: Vec<f64>,
    pub mean: Vec<f64>,
    pub sd: Vec<f64>,
    pub min: Vec<f64>,
    pub max: Vec<f64>,
    /// Empty strings when there is no sample matrix.
    pub nearest: Vec<String>,
    pub nearest_distance: Vec<f64>,
    pub max_within: Vec<f64>,
    pub min_between: Vec<f64>,
}

/// A square matrix, row by row: `values[i * names.len() + j]`.
pub struct DistanceMatrixData {
    pub names: Vec<String>,
    pub values: Vec<f64>,
}

/// One value per group in each column, and the mean between groups.
pub struct DistanceGroupsData {
    pub names: Vec<String>,
    pub samples: Vec<f64>,
    pub pairs: Vec<f64>,
    pub mean_within: Vec<f64>,
    pub sd_within: Vec<f64>,
    pub max_within: Vec<f64>,
    /// Mean distance within and between groups.
    pub matrix: DistanceMatrixData,
}

fn nan(value: Option<f64>) -> f64 {
    value.unwrap_or(f64::NAN)
}

impl From<&DistanceReport> for DistanceReportData {
    fn from(report: &DistanceReport) -> Self {
        let s = &report.summary;
        let loci = &report.loci;
        let samples = &report.samples;
        DistanceReportData {
            datatype: report.datatype.clone(),
            model: report.model.clone(),
            summary: DistanceOverviewData {
                loci: s.loci as f64,
                samples: s.samples as f64,
                pairs: s.pairs as f64,
                undefined_pairs: s.undefined_pairs as f64,
                min: nan(s.min),
                max: nan(s.max),
                mean: nan(s.mean),
                sd: nan(s.sd),
                median_locus_mean: nan(s.median_locus_mean),
                mean_compared_sites: nan(s.mean_compared_sites),
                groups: s.groups.map(|g| g as f64),
                unassigned: s.unassigned as f64,
            },
            bin_width: report.histogram.bin_width,
            histogram: report.histogram.counts.iter().map(|&c| c as f64).collect(),
            loci: DistanceLociData {
                names: loci.iter().map(|l| l.name.clone()).collect(),
                paths: loci.iter().map(|l| l.path.clone()).collect(),
                ntax: loci.iter().map(|l| l.ntax as f64).collect(),
                nchar: loci.iter().map(|l| l.nchar as f64).collect(),
                pairs: loci.iter().map(|l| l.pairs as f64).collect(),
                undefined_pairs: loci.iter().map(|l| l.undefined_pairs as f64).collect(),
                mean: loci.iter().map(|l| nan(l.mean)).collect(),
                median: loci.iter().map(|l| nan(l.median)).collect(),
                sd: loci.iter().map(|l| nan(l.sd)).collect(),
                min: loci.iter().map(|l| nan(l.min)).collect(),
                max: loci.iter().map(|l| nan(l.max)).collect(),
                mean_compared_sites: loci.iter().map(|l| nan(l.mean_compared_sites)).collect(),
            },
            samples: DistanceSamplesData {
                names: samples.iter().map(|s| s.name.clone()).collect(),
                groups: samples
                    .iter()
                    .map(|s| s.group.clone().unwrap_or_default())
                    .collect(),
                loci: samples.iter().map(|s| s.loci as f64).collect(),
                pairs: samples.iter().map(|s| s.stats.pairs as f64).collect(),
                mean: samples.iter().map(|s| nan(s.stats.mean)).collect(),
                sd: samples.iter().map(|s| nan(s.stats.sd)).collect(),
                min: samples.iter().map(|s| nan(s.stats.min)).collect(),
                max: samples.iter().map(|s| nan(s.stats.max)).collect(),
                nearest: samples
                    .iter()
                    .map(|s| s.nearest.clone().unwrap_or_default())
                    .collect(),
                nearest_distance: samples.iter().map(|s| nan(s.nearest_distance)).collect(),
                max_within: samples.iter().map(|s| nan(s.max_within)).collect(),
                min_between: samples.iter().map(|s| nan(s.min_between)).collect(),
            },
            matrix: report.matrix.as_ref().map(|m| DistanceMatrixData {
                names: m.names.clone(),
                values: m.mean.iter().flatten().map(|&v| nan(v)).collect(),
            }),
            groups: report.groups.as_ref().map(|g| {
                let names: Vec<String> = g.groups.iter().map(|g| g.name.clone()).collect();
                let n = names.len();
                let mut values = vec![f64::NAN; n * n];
                let position = |name: &str| names.iter().position(|g| g == name);
                for pair in &g.pairs {
                    if let (Some(i), Some(j)) = (position(&pair.group_1), position(&pair.group_2)) {
                        values[i * n + j] = nan(pair.stats.mean);
                        values[j * n + i] = nan(pair.stats.mean);
                    }
                }
                let within = |value: fn(&PairStats) -> Option<f64>| {
                    g.groups.iter().map(|g| nan(value(&g.within))).collect()
                };
                DistanceGroupsData {
                    samples: g.groups.iter().map(|g| g.samples as f64).collect(),
                    pairs: g.groups.iter().map(|g| g.within.pairs as f64).collect(),
                    mean_within: within(|w| w.mean),
                    sd_within: within(|w| w.sd),
                    max_within: within(|w| w.max),
                    matrix: DistanceMatrixData {
                        names: names.clone(),
                        values,
                    },
                    names,
                }
            }),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    const REPORT: &str = "src/tests/distance-report.json";

    #[test]
    fn test_report_columns() {
        let data = DistanceReportServices {
            path: REPORT.to_string(),
        }
        .load()
        .unwrap();
        assert_eq!(data.model, "K2P");
        assert_eq!(data.loci.names, vec!["locus_1", "locus_2", "locus_3"]);
        assert_eq!(data.samples.names.len(), 6);
        assert_eq!(data.samples.groups[0], "Mus_musculus");
        assert_eq!(data.samples.nearest[0], "Mus_musculus_B");
        let matrix = data.matrix.unwrap();
        assert_eq!(matrix.values.len(), 36);
        assert_eq!(matrix.values[0], 0.0);
        assert_eq!(matrix.values[1], matrix.values[6]);
        let groups = data.groups.unwrap();
        assert_eq!(groups.names.len(), 3);
        assert_eq!(groups.matrix.values[1], groups.matrix.values[3]);
        assert!(!groups.matrix.values[0].is_nan());
        assert_eq!(data.histogram.iter().sum::<f64>(), 31.0);
    }
}
