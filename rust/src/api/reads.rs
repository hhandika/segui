use std::path::{Path, PathBuf};
use std::time::Instant;

use segul_core::core::read::summarize::GenomicReadSummary;
use segul_core::helper::logger::ReadLogger;
use segul_core::helper::types::{PhredOffset, SeqReadFmt, SummaryMode};
use segul_core::helper::utils;
use segul_core::stats::fastq::qc::{self, QcCheck, QcProfile, QcStatus};
use segul_core::stats::fastq::report::{
    CohortOutlier, CohortSummary, ExpectedErrorBucket, LengthQualityBin, PairedReadSummary,
    PositionSummary, ReadReport, RelativePositionSummary, SampleReadReport,
};
use segul_core::stats::fastq::DEFAULT_DUP_SKETCH_SIZE;

use crate::api::progress::RunMonitor;

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
    /// `dup_sketch_size` is the number of distinct sequences kept to estimate
    /// duplication in Complete mode, zero to count all, or SEGUL's default.
    /// `qc_profile` is "auto", "short-wgs", "amplicon", "long-ont", or "long-hifi".
    /// `monitor` reports progress and can cancel the run.
    pub fn summarize(
        &self,
        mode: String,
        prefix: Option<String>,
        phred: Option<String>,
        dup_sketch_size: Option<u32>,
        qc_profile: Option<String>,
        monitor: &RunMonitor,
    ) -> anyhow::Result<ReadSummaryOutput> {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt()?;
        let mut files = self.find_input_files();
        let sum_mode = self.match_mode(&mode)?;
        let phred = self.match_phred(phred.as_deref())?;
        let qc_profile = self.match_qc_profile(qc_profile.as_deref())?;
        ReadLogger::new(None, &input_fmt, files.len()).log("Read Summary");
        let outputs = GenomicReadSummary::new(
            &mut files,
            &input_fmt,
            &sum_mode,
            output_path,
            prefix.as_deref(),
        )
        .with_phred(phred)
        .with_dup_sketch_size(dup_sketch_size.map_or(DEFAULT_DUP_SKETCH_SIZE, |size| size as usize))
        .with_qc_profile(qc_profile)
        .with_progress(monitor)
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

    fn match_qc_profile(&self, profile: Option<&str>) -> anyhow::Result<QcProfile> {
        profile
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
        let profile = report.qc_profile;
        Ok(ReadReportData {
            samples: report
                .samples
                .iter()
                .map(|s| ReadSampleData::from_report(s, profile))
                .collect(),
            qc_profile: profile.label().to_string(),
            pairs: report.pairs.iter().map(ReadPairData::from).collect(),
            cohort: report.cohort.as_ref().map(ReadCohortData::from),
        })
    }
}

// Counts are sent as f64 so Dart charts can use them directly.
// They stay exact up to 2^53.

pub struct ReadReportData {
    pub samples: Vec<ReadSampleData>,
    pub qc_profile: String,
    pub pairs: Vec<ReadPairData>,
    pub cohort: Option<ReadCohortData>,
}

pub struct ReadPairData {
    pub pair_name: String,
    pub r1_sample: String,
    pub r2_sample: String,
    pub r1_reads: f64,
    pub r2_reads: f64,
    pub read_count_diff: f64,
    pub in_sync: bool,
    pub q30_drop_pct: f64,
    pub effective_q_drop: f64,
    pub mean_length_diff: f64,
    pub gc_diff_pct: f64,
    pub status: ReadQcStatus,
}

pub struct ReadCohortData {
    pub sample_count: f64,
    pub empty_sample_count: f64,
    pub total_reads: f64,
    pub total_bases: f64,
    pub median_reads: f64,
    pub p10_reads: f64,
    pub p90_reads: f64,
    pub depth_p90_p10_ratio: f64,
    pub depth_cv: f64,
    pub depth_gini: f64,
    pub low_yield_samples: Vec<String>,
    pub outliers: Vec<ReadCohortOutlierData>,
}

pub struct ReadCohortOutlierData {
    pub sample: String,
    pub metric: String,
    pub value: f64,
    pub cohort_median: f64,
    pub modified_z: f64,
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
    pub relative_positions: ReadRelativePositionData,
    pub length_quality: Vec<ReadLengthQualityData>,
    pub expected_errors: Vec<ReadExpectedErrorData>,
    pub complexity_counts: Vec<f64>,
    pub duplication: Option<ReadDuplicationData>,
    pub overrepresented: Vec<OverrepresentedData>,
    pub adapters: Vec<AdapterContentData>,
    /// Quality checks, from the thresholds shared with the SEGUL viewer.
    pub checks: Vec<ReadQcCheckData>,
    /// The worst status among the checks.
    pub status: ReadQcStatus,
    /// Resolved QC profile label for this sample.
    pub qc_profile: String,
}

/// Outcome of a quality check, from best to worst.
pub enum ReadQcStatus {
    Pass,
    Warn,
    Fail,
}

/// One quality check of a sample.
pub struct ReadQcCheckData {
    pub name: String,
    /// The value as shown with the check, such as "92.4%".
    pub value: String,
    pub status: ReadQcStatus,
    /// What the check measures.
    pub description: String,
    /// The values of each status, from pass to fail.
    pub ranges: Vec<ReadQcRangeData>,
}

pub struct ReadQcRangeData {
    pub status: ReadQcStatus,
    pub range: String,
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
    pub n90_read_length: f64,
    pub l50_read_length: f64,
    pub aun_read_length: f64,
    pub empty_reads: f64,
    pub other_count: f64,
    pub gc_content: f64,
    pub n_content: f64,
    pub at_skew: f64,
    pub gc_skew: f64,
    pub gc_stdev: f64,
    pub gc_normal_divergence_pct: f64,
    pub gc_peaks: f64,
    pub mean_qscore: f64,
    pub effective_mean_qscore: f64,
    pub mean_error_rate: f64,
    pub q10_pct: f64,
    pub q15_pct: f64,
    pub q20_pct: f64,
    pub q30_pct: f64,
    pub q40_pct: f64,
    pub distinct_qscores: f64,
    pub mean_read_qscore: f64,
    pub low_quality_reads: f64,
    pub mean_expected_errors: f64,
    pub expected_errors_per_100bp: f64,
    pub expected_error_free_reads_pct: f64,
    pub reads_ee_lt_1_pct: f64,
    pub q10_read_bases_pct: f64,
    pub q20_read_bases_pct: f64,
    pub q30_read_bases_pct: f64,
    pub mean_complexity: f64,
    pub low_complexity_reads_pct: f64,
    pub homopolymer_bases_pct: f64,
    pub max_homopolymer_length: f64,
    pub homopolymer_mean_qscore: f64,
    pub non_homopolymer_mean_qscore: f64,
    pub homopolymer_qscore_gap: f64,
    pub poly_g_tail_reads_pct: f64,
    pub poly_a_tail_reads_pct: f64,
    pub poly_t_tail_reads_pct: f64,
    pub poly_c_tail_reads_pct: f64,
    pub platform: Option<String>,
    pub chastity_failed_reads: f64,
    pub chastity_failed_pct: f64,
    pub run_group_count: f64,
    pub phred_offset: u32,
    pub duplicate_pct: Option<f64>,
    pub adapter_reads_pct: Option<f64>,
    pub poly_g_reads_pct: Option<f64>,
    pub overrepresented_count: Option<f64>,
    pub qscore_tail_drop: Option<f64>,
    pub effective_q20_span: Option<f64>,
    pub effective_q30_span: Option<f64>,
    pub head_bias_bp: Option<f64>,
}

/// Per-position statistics in columns, one value per position or bin.
pub struct ReadPositionData {
    pub start: Vec<f64>,
    pub end: Vec<f64>,
    pub mean_qscore: Vec<f64>,
    pub effective_mean_qscore: Vec<f64>,
    pub read_survival_pct: Vec<f64>,
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

/// Per-relative-position statistics in columns (20 bins of 5% each).
pub struct ReadRelativePositionData {
    pub start_pct: Vec<f64>,
    pub end_pct: Vec<f64>,
    pub mean_qscore: Vec<f64>,
    pub effective_mean_qscore: Vec<f64>,
    pub p10_qscore: Vec<f64>,
    pub q1_qscore: Vec<f64>,
    pub median_qscore: Vec<f64>,
    pub q3_qscore: Vec<f64>,
    pub p90_qscore: Vec<f64>,
    pub a_pct: Vec<f64>,
    pub c_pct: Vec<f64>,
    pub g_pct: Vec<f64>,
    pub t_pct: Vec<f64>,
    pub n_pct: Vec<f64>,
}

pub struct ReadLengthQualityData {
    pub label: String,
    pub reads: f64,
    pub bases: f64,
    pub mean_qscore: f64,
    pub effective_mean_qscore: f64,
    pub q1_qscore: f64,
    pub median_qscore: f64,
    pub q3_qscore: f64,
    pub mean_expected_errors: f64,
}

pub struct ReadExpectedErrorData {
    pub label: String,
    pub reads: f64,
    pub reads_pct: f64,
}

pub struct ReadDuplicationData {
    /// Reads counted, which is every read with bases.
    pub reads: f64,
    /// Distinct sequences, estimated unless `exact`.
    pub distinct_sequences: f64,
    pub duplicate_pct: f64,
    /// Distinct sequences kept, or zero when all were kept.
    pub sketch_size: f64,
    pub exact: bool,
    pub labels: Vec<String>,
    pub distinct_pct: Vec<f64>,
    pub reads_pct: Vec<f64>,
}

pub struct OverrepresentedData {
    pub sequence: String,
    pub count: f64,
    /// Share of all reads, in percent.
    pub percent: f64,
    /// Largest amount `percent` can be short by.
    pub max_error_pct: f64,
    pub source: String,
}

pub struct AdapterContentData {
    pub name: String,
    pub sequence: String,
    /// Share of reads with the adapter at or before each position, in percent.
    pub cumulative_pct: Vec<f64>,
}

impl ReadSampleData {
    fn from_report(report: &SampleReadReport, requested_profile: QcProfile) -> Self {
        let m = &report.metrics;
        let counts = |values: &[u64]| values.iter().map(|v| *v as f64).collect();
        let resolved = qc::effective_profile(report, requested_profile);
        let checks = qc::qc_checks_with_profile(report, requested_profile);
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
                n90_read_length: m.n90_read_length as f64,
                l50_read_length: m.l50_read_length as f64,
                aun_read_length: m.aun_read_length,
                empty_reads: m.empty_reads as f64,
                other_count: m.other_count as f64,
                gc_content: m.gc_content,
                n_content: m.n_content,
                at_skew: m.at_skew,
                gc_skew: m.gc_skew,
                gc_stdev: m.gc_stdev,
                gc_normal_divergence_pct: m.gc_normal_divergence_pct,
                gc_peaks: m.gc_peaks as f64,
                mean_qscore: m.mean_qscore,
                effective_mean_qscore: m.effective_mean_qscore,
                mean_error_rate: m.mean_error_rate,
                q10_pct: m.q10_pct,
                q15_pct: m.q15_pct,
                q20_pct: m.q20_pct,
                q30_pct: m.q30_pct,
                q40_pct: m.q40_pct,
                distinct_qscores: m.distinct_qscores as f64,
                mean_read_qscore: m.mean_read_qscore,
                low_quality_reads: m.low_quality_reads as f64,
                mean_expected_errors: m.mean_expected_errors,
                expected_errors_per_100bp: m.expected_errors_per_100bp,
                expected_error_free_reads_pct: m.expected_error_free_reads_pct,
                reads_ee_lt_1_pct: m.reads_ee_lt_1_pct,
                q10_read_bases_pct: m.q10_read_bases_pct,
                q20_read_bases_pct: m.q20_read_bases_pct,
                q30_read_bases_pct: m.q30_read_bases_pct,
                mean_complexity: m.mean_complexity,
                low_complexity_reads_pct: m.low_complexity_reads_pct,
                homopolymer_bases_pct: m.homopolymer_bases_pct,
                max_homopolymer_length: m.max_homopolymer_length as f64,
                homopolymer_mean_qscore: m.homopolymer_mean_qscore,
                non_homopolymer_mean_qscore: m.non_homopolymer_mean_qscore,
                homopolymer_qscore_gap: m.homopolymer_qscore_gap,
                poly_g_tail_reads_pct: m.poly_g_tail_reads_pct,
                poly_a_tail_reads_pct: m.poly_a_tail_reads_pct,
                poly_t_tail_reads_pct: m.poly_t_tail_reads_pct,
                poly_c_tail_reads_pct: m.poly_c_tail_reads_pct,
                platform: m.platform.clone(),
                chastity_failed_reads: m.chastity_failed_reads as f64,
                chastity_failed_pct: m.chastity_failed_pct,
                run_group_count: m.run_group_count as f64,
                phred_offset: u32::from(m.phred_offset),
                duplicate_pct: m.duplicate_pct_est,
                adapter_reads_pct: m.adapter_reads_pct,
                poly_g_reads_pct: m.poly_g_reads_pct,
                overrepresented_count: m.overrepresented_count.map(|c| c as f64),
                qscore_tail_drop: m.qscore_tail_drop,
                effective_q20_span: m.effective_q20_span.map(|v| v as f64),
                effective_q30_span: m.effective_q30_span.map(|v| v as f64),
                head_bias_bp: m.head_bias_bp.map(|v| v as f64),
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
            relative_positions: ReadRelativePositionData::from(report),
            length_quality: report
                .length_quality
                .iter()
                .map(ReadLengthQualityData::from)
                .collect(),
            expected_errors: report
                .expected_error_distribution
                .iter()
                .map(ReadExpectedErrorData::from)
                .collect(),
            complexity_counts: counts(&report.complexity_distribution),
            duplication: report.duplication.as_ref().map(|d| ReadDuplicationData {
                reads: d.reads as f64,
                distinct_sequences: d.distinct_sequences,
                duplicate_pct: d.duplicate_pct,
                sketch_size: d.sketch_size as f64,
                exact: d.exact,
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
                    max_error_pct: o.max_error_pct,
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
            checks: checks.iter().map(ReadQcCheckData::from).collect(),
            status: ReadQcStatus::from(qc::overall_status(&checks)),
            qc_profile: resolved.label().to_string(),
        }
    }
}

impl From<&PairedReadSummary> for ReadPairData {
    fn from(pair: &PairedReadSummary) -> Self {
        let checks = qc::pair_qc_checks(pair);
        ReadPairData {
            pair_name: pair.pair_name.clone(),
            r1_sample: pair.r1_sample.clone(),
            r2_sample: pair.r2_sample.clone(),
            r1_reads: pair.r1_reads as f64,
            r2_reads: pair.r2_reads as f64,
            read_count_diff: pair.read_count_diff as f64,
            in_sync: pair.in_sync,
            q30_drop_pct: pair.q30_drop_pct,
            effective_q_drop: pair.effective_q_drop,
            mean_length_diff: pair.mean_length_diff,
            gc_diff_pct: pair.gc_diff_pct,
            status: ReadQcStatus::from(qc::overall_status(&checks)),
        }
    }
}

impl From<&CohortSummary> for ReadCohortData {
    fn from(cohort: &CohortSummary) -> Self {
        ReadCohortData {
            sample_count: cohort.sample_count as f64,
            empty_sample_count: cohort.empty_sample_count as f64,
            total_reads: cohort.total_reads as f64,
            total_bases: cohort.total_bases as f64,
            median_reads: cohort.median_reads,
            p10_reads: cohort.p10_reads,
            p90_reads: cohort.p90_reads,
            depth_p90_p10_ratio: cohort.depth_p90_p10_ratio,
            depth_cv: cohort.depth_cv,
            depth_gini: cohort.depth_gini,
            low_yield_samples: cohort.low_yield_samples.clone(),
            outliers: cohort
                .outliers
                .iter()
                .map(ReadCohortOutlierData::from)
                .collect(),
        }
    }
}

impl From<&CohortOutlier> for ReadCohortOutlierData {
    fn from(outlier: &CohortOutlier) -> Self {
        ReadCohortOutlierData {
            sample: outlier.sample.clone(),
            metric: outlier.metric.clone(),
            value: outlier.value,
            cohort_median: outlier.cohort_median,
            modified_z: outlier.modified_z,
        }
    }
}

impl From<&LengthQualityBin> for ReadLengthQualityData {
    fn from(bin: &LengthQualityBin) -> Self {
        ReadLengthQualityData {
            label: bin.label.clone(),
            reads: bin.reads as f64,
            bases: bin.bases as f64,
            mean_qscore: bin.mean_qscore,
            effective_mean_qscore: bin.effective_mean_qscore,
            q1_qscore: bin.q1_qscore as f64,
            median_qscore: bin.median_qscore as f64,
            q3_qscore: bin.q3_qscore as f64,
            mean_expected_errors: bin.mean_expected_errors,
        }
    }
}

impl From<&ExpectedErrorBucket> for ReadExpectedErrorData {
    fn from(bucket: &ExpectedErrorBucket) -> Self {
        ReadExpectedErrorData {
            label: bucket.label.clone(),
            reads: bucket.reads as f64,
            reads_pct: bucket.reads_pct,
        }
    }
}

impl From<QcStatus> for ReadQcStatus {
    fn from(status: QcStatus) -> Self {
        match status {
            QcStatus::Pass => ReadQcStatus::Pass,
            QcStatus::Warn => ReadQcStatus::Warn,
            QcStatus::Fail => ReadQcStatus::Fail,
        }
    }
}

impl From<&QcCheck> for ReadQcCheckData {
    fn from(check: &QcCheck) -> Self {
        ReadQcCheckData {
            name: check.name.to_string(),
            value: check.value_text(),
            status: ReadQcStatus::from(check.status),
            description: check.rule.description.to_string(),
            ranges: check
                .rule
                .ranges()
                .into_iter()
                .map(|(status, range)| ReadQcRangeData {
                    status: ReadQcStatus::from(status),
                    range,
                })
                .collect(),
        }
    }
}

impl From<&SampleReadReport> for ReadPositionData {
    fn from(report: &SampleReadReport) -> Self {
        let positions = &report.positions;
        let column =
            |f: &dyn Fn(&PositionSummary) -> f64| positions.iter().map(f).collect::<Vec<f64>>();
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
            effective_mean_qscore: column(&|p| p.effective_mean_qscore),
            read_survival_pct: column(&|p| p.read_survival_pct),
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

impl From<&SampleReadReport> for ReadRelativePositionData {
    fn from(report: &SampleReadReport) -> Self {
        let rel = &report.relative_positions;
        let column = |f: &dyn Fn(&RelativePositionSummary) -> f64| {
            rel.iter().map(f).collect::<Vec<f64>>()
        };
        let total = |p: &RelativePositionSummary| {
            p.a_count + p.c_count + p.g_count + p.t_count + p.n_count
        };
        let share = |count: u64, total: u64| {
            if total == 0 {
                0.0
            } else {
                100.0 * count as f64 / total as f64
            }
        };
        ReadRelativePositionData {
            start_pct: column(&|p| p.start_pct as f64),
            end_pct: column(&|p| p.end_pct as f64),
            mean_qscore: column(&|p| p.mean_qscore),
            effective_mean_qscore: column(&|p| p.effective_mean_qscore),
            p10_qscore: column(&|p| p.p10_qscore as f64),
            q1_qscore: column(&|p| p.q1_qscore as f64),
            median_qscore: column(&|p| p.median_qscore as f64),
            q3_qscore: column(&|p| p.q3_qscore as f64),
            p90_qscore: column(&|p| p.p90_qscore as f64),
            a_pct: column(&|p| share(p.a_count, total(p))),
            c_pct: column(&|p| share(p.c_count, total(p))),
            g_pct: column(&|p| share(p.g_count, total(p))),
            t_pct: column(&|p| share(p.t_count, total(p))),
            n_pct: column(&|p| share(p.n_count, total(p))),
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
        let names: Vec<&str> = sample.checks.iter().map(|c| c.name.as_str()).collect();
        assert_eq!(names[..3], ["Q30 bases", "Mean quality", "N content"]);
        let q30 = &sample.checks[0];
        assert!(q30.value.ends_with('%'));
        assert_eq!(q30.ranges.len(), 3);
        assert_eq!(q30.ranges[0].range, "80% or higher");
        assert!(matches!(q30.ranges[2].status, ReadQcStatus::Fail));
    }
}
