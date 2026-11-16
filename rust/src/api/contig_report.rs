use std::path::Path;

use segul_core::stats::contig_report::ContigReport;

/// Loads `contig-report.json` for the interactive contig report.
pub struct ContigReportServices {
    pub path: String,
}

impl ContigReportServices {
    pub fn new() -> ContigReportServices {
        ContigReportServices {
            path: String::new(),
        }
    }

    pub fn load(&self) -> anyhow::Result<ContigReportData> {
        let report = ContigReport::from_path(Path::new(&self.path))?;
        Ok(ContigReportData::from(&report))
    }
}

// Counts are sent as f64 so Dart charts can use them directly, and samples
// are sent in columns, like the alignment report.

pub struct ContigReportData {
    pub summary: ContigOverviewData,
    /// Labels of the contig length bins, shortest first, such as `500-1k`.
    pub length_bins: Vec<String>,
    pub samples: ContigSamplesData,
}

pub struct ContigOverviewData {
    pub samples: f64,
    pub contigs: f64,
    pub bases: f64,
    pub nucleotides: f64,
    pub n_count: f64,
    pub unknown: f64,
    pub gc: f64,
    pub at: f64,
    pub prop_n: f64,
    pub min_contigs: f64,
    pub max_contigs: f64,
    pub mean_contigs: f64,
    pub min_n50: f64,
    pub max_n50: f64,
    pub median_n50: f64,
    pub longest: f64,
}

/// One value per sample in each column, in the order of `names`.
pub struct ContigSamplesData {
    pub names: Vec<String>,
    pub paths: Vec<String>,
    pub contigs: Vec<f64>,
    pub bases: Vec<f64>,
    pub min: Vec<f64>,
    pub max: Vec<f64>,
    pub mean: Vec<f64>,
    pub median: Vec<f64>,
    pub n50: Vec<f64>,
    pub n75: Vec<f64>,
    pub n90: Vec<f64>,
    /// Contigs longer than 1000 bp.
    pub long_contigs: Vec<f64>,
    pub gc: Vec<f64>,
    pub prop_n: Vec<f64>,
    /// Contigs per length bin for each sample, aligned with `length_bins`.
    pub length_distribution: Vec<Vec<f64>>,
}

/// Length of the contigs counted in [`ContigSamplesData::long_contigs`].
const LONG_CONTIG_LENGTH: usize = 1000;

impl From<&ContigReport> for ContigReportData {
    fn from(report: &ContigReport) -> Self {
        let s = &report.summary;
        let samples = &report.samples;
        let column = |value: fn(&_) -> f64| samples.iter().map(value).collect();
        ContigReportData {
            summary: ContigOverviewData {
                samples: s.samples as f64,
                contigs: s.contigs as f64,
                bases: s.bases as f64,
                nucleotides: s.nucleotides as f64,
                n_count: s.n_count as f64,
                unknown: s.unknown as f64,
                gc: s.gc,
                at: s.at,
                prop_n: s.prop_n,
                min_contigs: s.min_contigs as f64,
                max_contigs: s.max_contigs as f64,
                mean_contigs: s.mean_contigs,
                min_n50: s.min_n50 as f64,
                max_n50: s.max_n50 as f64,
                median_n50: s.median_n50,
                longest: s.longest as f64,
            },
            length_bins: report.length_bins.iter().map(|b| b.label()).collect(),
            samples: ContigSamplesData {
                names: samples.iter().map(|s| s.name.clone()).collect(),
                paths: samples.iter().map(|s| s.path.clone()).collect(),
                contigs: column(|s| s.contigs as f64),
                bases: column(|s| s.bases as f64),
                min: column(|s| s.min as f64),
                max: column(|s| s.max as f64),
                mean: column(|s| s.mean),
                median: column(|s| s.median),
                n50: column(|s| s.n50 as f64),
                n75: column(|s| s.n75 as f64),
                n90: column(|s| s.n90 as f64),
                long_contigs: samples
                    .iter()
                    .map(|s| {
                        s.long_contigs
                            .iter()
                            .find(|c| c.length == LONG_CONTIG_LENGTH)
                            .map_or(0.0, |c| c.contigs as f64)
                    })
                    .collect(),
                gc: column(|s| s.gc),
                prop_n: column(|s| s.prop_n),
                length_distribution: samples
                    .iter()
                    .map(|s| s.length_distribution.iter().map(|&c| c as f64).collect())
                    .collect(),
            },
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    const REPORT: &str = "src/tests/contig-report.json";

    #[test]
    fn test_report_columns() {
        let data = ContigReportServices {
            path: String::from(REPORT),
        }
        .load()
        .unwrap();
        assert_eq!(data.summary.samples, 2.0);
        assert_eq!(data.samples.names, vec!["contigs1", "contigs2"]);
        assert_eq!(data.samples.n50, vec![258.0, 316.0]);
        assert_eq!(data.samples.long_contigs, vec![0.0, 0.0]);
        assert_eq!(data.length_bins[2], "500-1k");
        assert_eq!(
            data.samples.length_distribution[0].len(),
            data.length_bins.len()
        );
        assert_eq!(data.samples.length_distribution[1][1], 2.0);
    }
}
