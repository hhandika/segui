use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::core::read::summarize::GenomicReadSummary;
use segul::helper::logger::ReadLogger;
use segul::helper::types::{PhredOffset, SeqReadFmt, SummaryMode};
use segul::helper::utils;
use segul::stats::fastq::report::{PositionSummary, ReadReport, SampleReadReport};

pub struct RawReadServices {
    pub files: Vec<String>,
    pub file_fmt: String,
    pub output_dir: String,
}

/// Files written by a read summary.
pub struct ReadSummaryOutput {
    pub summary_path: String,
    pub positions_path: Option<String>,
    pub distributions_path: Option<String>,
    /// All statistics as JSON, written in Complete mode.
    pub report_path: Option<String>,
}

impl RawReadServices {
    pub fn new() -> RawReadServices {
        RawReadServices {
            files: Vec::new(),
            file_fmt: String::new(),
            output_dir: String::new(),
        }
    }

    /// Summarize reads. `phred` is "auto", "33", or "64", and defaults to "auto".
    pub fn summarize(
        &self,
        mode: String,
        prefix: Option<String>,
        phred: Option<String>,
    ) -> anyhow::Result<ReadSummaryOutput> {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt()?;
        let mut files = self.find_input_files();
        let sum_mode = self.match_mode(&mode)?;
        let phred = self.match_phred(phred.as_deref())?;
        ReadLogger::new(None, &input_fmt, files.len()).log("Read Summary");
        let outputs = GenomicReadSummary::new(
            &mut files,
            &input_fmt,
            &sum_mode,
            output_path,
            prefix.as_deref(),
        )
        .with_phred(phred)
        .try_summarize()?;
        let duration = time.elapsed();
        utils::print_execution_time(duration);
        let path_string = |p: &PathBuf| p.display().to_string();
        Ok(ReadSummaryOutput {
            summary_path: path_string(&outputs.summary),
            positions_path: outputs.positions.as_ref().map(path_string),
            distributions_path: outputs.distributions.as_ref().map(path_string),
            report_path: outputs.report.as_ref().map(path_string),
        })
    }

    fn match_input_fmt(&self) -> anyhow::Result<SeqReadFmt> {
        self.file_fmt
            .to_lowercase()
            .parse()
            .map_err(anyhow::Error::msg)
    }

    fn match_mode(&self, mode: &str) -> anyhow::Result<SummaryMode> {
        mode.to_lowercase().parse().map_err(anyhow::Error::msg)
    }

    fn match_phred(&self, phred: Option<&str>) -> anyhow::Result<PhredOffset> {
        phred
            .unwrap_or("auto")
            .to_lowercase()
            .parse()
            .map_err(anyhow::Error::msg)
    }

    fn find_input_files(&self) -> Vec<PathBuf> {
        self.files.iter().map(PathBuf::from).collect()
    }
}

/// Loads `read-report.json` for the interactive read report.
pub struct ReadReportServices {
    pub path: String,
}

impl ReadReportServices {
    pub fn new() -> ReadReportServices {
        ReadReportServices {
            path: String::new(),
        }
    }

    pub fn load(&self) -> anyhow::Result<ReadReportData> {
        let report = ReadReport::from_path(Path::new(&self.path))?;
        Ok(ReadReportData {
            samples: report.samples.iter().map(ReadSampleData::from).collect(),
        })
    }
}

// Counts are sent as f64 so Dart charts can use them directly.
// They stay exact up to 2^53.

pub struct ReadReportData {
    pub samples: Vec<ReadSampleData>,
}

pub struct ReadSampleData {
    pub sample: String,
    pub file_name: String,
    pub file_path: String,
    pub metrics: ReadMetricsData,
    pub length_values: Vec<f64>,
    pub length_counts: Vec<f64>,
    /// Reads by mean quality. Index is the quality score.
    pub read_quality_counts: Vec<f64>,
    /// Reads by GC percentage. Index is the percentage. Reads between two
    /// percentages count partly toward each.
    pub gc_counts: Vec<f64>,
    pub gc_theoretical: Vec<f64>,
    pub positions: ReadPositionData,
    pub duplication: Option<ReadDuplicationData>,
    pub overrepresented: Vec<OverrepresentedData>,
    pub adapters: Vec<AdapterContentData>,
}

pub struct ReadMetricsData {
    pub read_count: f64,
    pub base_count: f64,
    pub min_read_length: f64,
    pub max_read_length: f64,
    pub mean_read_length: f64,
    pub median_read_length: f64,
    pub stdev_read_length: f64,
    pub n50_read_length: f64,
    pub gc_content: f64,
    pub n_content: f64,
    pub mean_qscore: f64,
    pub q20_pct: f64,
    pub q30_pct: f64,
    pub mean_read_qscore: f64,
    pub low_quality_reads: f64,
    pub phred_offset: u32,
    pub duplicate_pct: Option<f64>,
    pub adapter_reads_pct: Option<f64>,
    pub poly_g_reads_pct: Option<f64>,
    pub overrepresented_count: Option<f64>,
}

/// Per-position statistics in columns, one value per position or bin.
pub struct ReadPositionData {
    pub start: Vec<f64>,
    pub end: Vec<f64>,
    pub mean_qscore: Vec<f64>,
    pub p10_qscore: Vec<f64>,
    pub q1_qscore: Vec<f64>,
    pub median_qscore: Vec<f64>,
    pub q3_qscore: Vec<f64>,
    pub p90_qscore: Vec<f64>,
    /// Base shares in percent of all bases at the position.
    pub a_pct: Vec<f64>,
    pub c_pct: Vec<f64>,
    pub g_pct: Vec<f64>,
    pub t_pct: Vec<f64>,
    pub n_pct: Vec<f64>,
}

pub struct ReadDuplicationData {
    pub sampled_reads: f64,
    pub duplicate_pct: f64,
    pub labels: Vec<String>,
    pub distinct_pct: Vec<f64>,
    pub reads_pct: Vec<f64>,
}

pub struct OverrepresentedData {
    pub sequence: String,
    pub count: f64,
    pub percent: f64,
    pub source: String,
}

pub struct AdapterContentData {
    pub name: String,
    pub sequence: String,
    /// Share of reads with the adapter at or before each position, in percent.
    pub cumulative_pct: Vec<f64>,
}

impl From<&SampleReadReport> for ReadSampleData {
    fn from(report: &SampleReadReport) -> Self {
        let m = &report.metrics;
        let counts = |values: &[u64]| values.iter().map(|v| *v as f64).collect();
        ReadSampleData {
            sample: report.sample.clone(),
            file_name: report.file_name.clone(),
            file_path: report.file_path.clone(),
            metrics: ReadMetricsData {
                read_count: m.read_count as f64,
                base_count: m.base_count as f64,
                min_read_length: m.min_read_length as f64,
                max_read_length: m.max_read_length as f64,
                mean_read_length: m.mean_read_length,
                median_read_length: m.median_read_length,
                stdev_read_length: m.stdev_read_length,
                n50_read_length: m.n50_read_length as f64,
                gc_content: m.gc_content,
                n_content: m.n_content,
                mean_qscore: m.mean_qscore,
                q20_pct: m.q20_pct,
                q30_pct: m.q30_pct,
                mean_read_qscore: m.mean_read_qscore,
                low_quality_reads: m.low_quality_reads as f64,
                phred_offset: u32::from(m.phred_offset),
                duplicate_pct: m.duplicate_pct_est,
                adapter_reads_pct: m.adapter_reads_pct,
                poly_g_reads_pct: m.poly_g_reads_pct,
                overrepresented_count: m.overrepresented_count.map(|c| c as f64),
            },
            length_values: report
                .length_distribution
                .iter()
                .map(|l| l.length as f64)
                .collect(),
            length_counts: report
                .length_distribution
                .iter()
                .map(|l| l.reads as f64)
                .collect(),
            read_quality_counts: counts(&report.read_quality_distribution),
            gc_counts: report.gc_distribution.clone(),
            gc_theoretical: report.gc_theoretical.clone(),
            positions: ReadPositionData::from(report),
            duplication: report.duplication.as_ref().map(|d| ReadDuplicationData {
                sampled_reads: d.sampled_reads as f64,
                duplicate_pct: d.duplicate_pct,
                labels: d.levels.iter().map(|l| l.label.clone()).collect(),
                distinct_pct: d.levels.iter().map(|l| l.distinct_pct).collect(),
                reads_pct: d.levels.iter().map(|l| l.reads_pct).collect(),
            }),
            overrepresented: report
                .overrepresented
                .iter()
                .map(|o| OverrepresentedData {
                    sequence: o.sequence.clone(),
                    count: o.count as f64,
                    percent: o.percent,
                    source: o.source.clone(),
                })
                .collect(),
            adapters: report
                .adapters
                .iter()
                .map(|a| AdapterContentData {
                    name: a.name.clone(),
                    sequence: a.sequence.clone(),
                    cumulative_pct: a.cumulative_pct.clone(),
                })
                .collect(),
        }
    }
}

impl From<&SampleReadReport> for ReadPositionData {
    fn from(report: &SampleReadReport) -> Self {
        let positions = &report.positions;
        let column = |f: &dyn Fn(&PositionSummary) -> f64| {
            positions.iter().map(f).collect::<Vec<f64>>()
        };
        let share = |count: u64, total: u64| {
            if total == 0 {
                0.0
            } else {
                100.0 * count as f64 / total as f64
            }
        };
        ReadPositionData {
            start: column(&|p| p.start as f64),
            end: column(&|p| p.end as f64),
            mean_qscore: column(&|p| p.mean_qscore),
            p10_qscore: column(&|p| p.p10_qscore as f64),
            q1_qscore: column(&|p| p.q1_qscore as f64),
            median_qscore: column(&|p| p.median_qscore as f64),
            q3_qscore: column(&|p| p.q3_qscore as f64),
            p90_qscore: column(&|p| p.p90_qscore as f64),
            a_pct: column(&|p| share(p.a_count, p.base_count())),
            c_pct: column(&|p| share(p.c_count, p.base_count())),
            g_pct: column(&|p| share(p.g_count, p.base_count())),
            t_pct: column(&|p| share(p.t_count, p.base_count())),
            n_pct: column(&|p| share(p.n_count, p.base_count())),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_load_read_report() {
        let services = ReadReportServices {
            path: String::from("src/tests/read-report.json"),
        };
        let report = services.load().unwrap();
        let sample = report
            .samples
            .iter()
            .find(|s| s.sample == "read_1")
            .unwrap();
        assert_eq!(sample.metrics.read_count, 2.0);
        assert_eq!(sample.positions.start.len(), 36);
        assert_eq!(sample.adapters.len(), 5);
        let total: f64 = sample.positions.a_pct[1]
            + sample.positions.c_pct[1]
            + sample.positions.g_pct[1]
            + sample.positions.t_pct[1]
            + sample.positions.n_pct[1];
        assert!((total - 100.0).abs() < 1e-9);
    }
}
