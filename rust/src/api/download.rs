use std::collections::HashSet;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};

use flutter_rust_bridge::frb;
use segul_core::core::download::{
    CompletedDownload, DatabaseSource, DownloadCancelled, DownloadConfig, DownloadContent,
    DownloadJob, DownloadOptions, DownloadProgress, DownloadProgressReporter, DownloadRecord,
    DownloadReport, DownloadStage, RecordDownloadStatus, RemoteFile, SequenceGrouping,
    SequenceNaming,
};

use crate::frb_generated::StreamSink;

static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

fn runtime() -> anyhow::Result<&'static tokio::runtime::Runtime> {
    if let Some(rt) = RUNTIME.get() {
        return Ok(rt);
    }
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?;
    let _ = RUNTIME.set(rt);
    Ok(RUNTIME.get().expect("Runtime initialized"))
}

/// Public sequence archive supported by the downloader.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbDatabaseSource {
    GenBank,
    Ena,
}

/// Kind of biological data to download.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbDownloadContent {
    Nucleotide,
    Coding,
    Protein,
    Reads,
    Assembly,
}

/// How sequence outputs are grouped into files.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbSequenceGrouping {
    SingleFile,
    PerRecord,
}

/// How FASTA sequence headers are formatted.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbSequenceNaming {
    SpeciesAccession,
    Accession,
}

/// Current stage of a running download job.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbDownloadStage {
    Connecting,
    Downloading,
    Retrying,
    Verifying,
    Decompressing,
    Preparing,
}

/// Per-record download state.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbRecordStatus {
    Pending,
    Active,
    Done,
    Failed,
}

/// A remote file belonging to a read run or assembly.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbRemoteFile {
    pub url: String,
    pub bytes: Option<u64>,
    pub md5: Option<String>,
}

/// Selected archive record queued for download.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadRecord {
    pub source: FrbDatabaseSource,
    pub content: FrbDownloadContent,
    pub accession: String,
    pub organism: String,
    pub title: String,
    pub length: Option<u64>,
    pub codon_start: u32,
    pub gene: String,
    pub files: Vec<FrbRemoteFile>,
}

/// Output grouping, naming, and gene filter options.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadOptions {
    pub grouping: FrbSequenceGrouping,
    pub naming: FrbSequenceNaming,
    pub gene: String,
    pub file_name: String,
}

/// Full configuration for starting a download job.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadRequest {
    pub records: Vec<FrbDownloadRecord>,
    pub options: FrbDownloadOptions,
    pub ncbi_api_key: Option<String>,
    pub trims_to_frame: bool,
    pub root_dir: String,
    pub taken_names: Vec<String>,
}

/// Key-status pair for a record in a progress snapshot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbRecordStatusEntry {
    pub key: String,
    pub status: FrbRecordStatus,
}

/// Live progress snapshot streamed from Rust to Dart.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadProgress {
    pub done: u32,
    pub total: u32,
    pub bytes: u64,
    pub bytes_total: u64,
    pub bytes_per_second: Option<u64>,
    pub stage: FrbDownloadStage,
    pub retry_attempt: Option<u32>,
    pub retry_max: Option<u32>,
    pub statuses: Vec<FrbRecordStatusEntry>,
}

/// Failure detail for one record.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadFailure {
    pub record_key: String,
    pub accession: String,
    pub reason: String,
}

/// Outcome of a download run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbDownloadReport {
    pub completed: u32,
    pub failures: Vec<FrbDownloadFailure>,
}

/// Committed output files and inferred SEGUL data type.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrbCompletedDownload {
    pub files: Vec<String>,
    pub data_type: Option<String>,
}

struct MonitorInner {
    sink: Mutex<Option<StreamSink<FrbDownloadProgress>>>,
    snapshot: Mutex<Option<FrbDownloadProgress>>,
    cancelled: AtomicBool,
}

impl DownloadProgressReporter for MonitorInner {
    fn on_progress(&self, progress: DownloadProgress) {
        let mapped = FrbDownloadProgress::from(progress);
        if let Ok(mut snap) = self.snapshot.lock() {
            *snap = Some(mapped.clone());
        }
        if let Ok(sink) = self.sink.lock() {
            if let Some(sink) = sink.as_ref() {
                let _ = sink.add(mapped);
            }
        }
    }

    fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::Relaxed)
    }
}

/// Streams progress updates from [`DatabaseDownloadJob`] and supports cancellation.
pub struct DownloadMonitor {
    inner: Arc<MonitorInner>,
}

impl DownloadMonitor {
    #[frb(sync)]
    pub fn new() -> DownloadMonitor {
        DownloadMonitor {
            inner: Arc::new(MonitorInner {
                sink: Mutex::new(None),
                snapshot: Mutex::new(None),
                cancelled: AtomicBool::new(false),
            }),
        }
    }

    /// Subscribes `sink` to live progress updates, replaying the latest snapshot if present.
    pub fn subscribe(&self, sink: StreamSink<FrbDownloadProgress>) {
        if let Ok(snap) = self.inner.snapshot.lock() {
            if let Some(latest) = snap.as_ref() {
                let _ = sink.add(latest.clone());
            }
        }
        if let Ok(mut current) = self.inner.sink.lock() {
            *current = Some(sink);
        }
    }

    /// Requests cancellation of the active download job.
    #[frb(sync)]
    pub fn cancel(&self) {
        self.inner.cancelled.store(true, Ordering::Relaxed);
    }

    #[frb(sync)]
    pub fn is_cancelled(&self) -> bool {
        self.inner.is_cancelled()
    }

    /// Closes the progress stream once the job has returned.
    #[frb(sync)]
    pub fn close(&self) {
        if let Ok(mut sink) = self.inner.sink.lock() {
            sink.take();
        }
    }

    #[frb(ignore)]
    pub(crate) fn reporter(&self) -> Arc<dyn DownloadProgressReporter> {
        Arc::clone(&self.inner) as Arc<dyn DownloadProgressReporter>
    }
}

impl Default for DownloadMonitor {
    fn default() -> Self {
        Self::new()
    }
}

/// Staged GenBank and ENA download job backed by `segul-core`.
pub struct DatabaseDownloadJob {
    inner: Mutex<Option<DownloadJob>>,
}

impl DatabaseDownloadJob {
    #[frb(sync)]
    pub fn new(request: FrbDownloadRequest) -> anyhow::Result<DatabaseDownloadJob> {
        let records = request
            .records
            .into_iter()
            .map(DownloadRecord::from)
            .collect();
        let options = DownloadOptions::from(request.options);
        let config = DownloadConfig {
            ncbi_api_key: request.ncbi_api_key,
            ..Default::default()
        };
        let taken_names: HashSet<String> = request
            .taken_names
            .into_iter()
            .map(|n| n.to_lowercase())
            .collect();
        let job = DownloadJob::new(
            records,
            options,
            config,
            request.trims_to_frame,
            PathBuf::from(request.root_dir),
            taken_names,
        )?;
        Ok(DatabaseDownloadJob {
            inner: Mutex::new(Some(job)),
        })
    }

    /// Runs or retries pending downloads and streams progress through `monitor`.
    pub fn run(&self, monitor: &DownloadMonitor) -> anyhow::Result<FrbDownloadReport> {
        let mut guard = self
            .inner
            .lock()
            .map_err(|_| anyhow::anyhow!("Download job lock poisoned"))?;
        let job = guard
            .as_mut()
            .ok_or_else(|| anyhow::anyhow!("Download job has already finished"))?;
        let rt = runtime()?;
        let reporter = monitor.reporter();
        match rt.block_on(job.run(Some(reporter))) {
            Ok(report) => Ok(FrbDownloadReport::from(report)),
            Err(err) => {
                if err.downcast_ref::<DownloadCancelled>().is_some() {
                    anyhow::bail!("CANCELLED")
                }
                Err(err)
            }
        }
    }

    /// Commits staged files and `sources.tsv` into their final download directory.
    pub fn commit(&self) -> anyhow::Result<FrbCompletedDownload> {
        let mut guard = self
            .inner
            .lock()
            .map_err(|_| anyhow::anyhow!("Download job lock poisoned"))?;
        let job = guard
            .as_mut()
            .ok_or_else(|| anyhow::anyhow!("Download job has already finished"))?;
        let completed = job.commit()?;
        Ok(FrbCompletedDownload::from(completed))
    }

    /// Discards staged files and resets the job.
    pub fn discard(&self) -> anyhow::Result<()> {
        let mut guard = self
            .inner
            .lock()
            .map_err(|_| anyhow::anyhow!("Download job lock poisoned"))?;
        if let Some(job) = guard.as_mut() {
            job.discard();
        }
        Ok(())
    }
}

impl From<FrbDatabaseSource> for DatabaseSource {
    fn from(value: FrbDatabaseSource) -> Self {
        match value {
            FrbDatabaseSource::GenBank => Self::GenBank,
            FrbDatabaseSource::Ena => Self::Ena,
        }
    }
}

impl From<FrbDownloadContent> for DownloadContent {
    fn from(value: FrbDownloadContent) -> Self {
        match value {
            FrbDownloadContent::Nucleotide => Self::Nucleotide,
            FrbDownloadContent::Coding => Self::Coding,
            FrbDownloadContent::Protein => Self::Protein,
            FrbDownloadContent::Reads => Self::Reads,
            FrbDownloadContent::Assembly => Self::Assembly,
        }
    }
}

impl From<FrbSequenceGrouping> for SequenceGrouping {
    fn from(value: FrbSequenceGrouping) -> Self {
        match value {
            FrbSequenceGrouping::SingleFile => Self::SingleFile,
            FrbSequenceGrouping::PerRecord => Self::PerRecord,
        }
    }
}

impl From<FrbSequenceNaming> for SequenceNaming {
    fn from(value: FrbSequenceNaming) -> Self {
        match value {
            FrbSequenceNaming::SpeciesAccession => Self::SpeciesAccession,
            FrbSequenceNaming::Accession => Self::Accession,
        }
    }
}

impl From<DownloadStage> for FrbDownloadStage {
    fn from(value: DownloadStage) -> Self {
        match value {
            DownloadStage::Connecting => Self::Connecting,
            DownloadStage::Downloading => Self::Downloading,
            DownloadStage::Retrying => Self::Retrying,
            DownloadStage::Verifying => Self::Verifying,
            DownloadStage::Decompressing => Self::Decompressing,
            DownloadStage::Preparing => Self::Preparing,
        }
    }
}

impl From<RecordDownloadStatus> for FrbRecordStatus {
    fn from(value: RecordDownloadStatus) -> Self {
        match value {
            RecordDownloadStatus::Pending => Self::Pending,
            RecordDownloadStatus::Active => Self::Active,
            RecordDownloadStatus::Done => Self::Done,
            RecordDownloadStatus::Failed => Self::Failed,
        }
    }
}

impl From<FrbRemoteFile> for RemoteFile {
    fn from(value: FrbRemoteFile) -> Self {
        Self {
            url: value.url,
            bytes: value.bytes,
            md5: value.md5,
        }
    }
}

impl From<FrbDownloadRecord> for DownloadRecord {
    fn from(value: FrbDownloadRecord) -> Self {
        Self {
            source: value.source.into(),
            content: value.content.into(),
            accession: value.accession,
            organism: value.organism,
            title: value.title,
            length: value.length,
            codon_start: value.codon_start,
            gene: value.gene,
            files: value.files.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<FrbDownloadOptions> for DownloadOptions {
    fn from(value: FrbDownloadOptions) -> Self {
        Self {
            grouping: Some(value.grouping.into()),
            naming: Some(value.naming.into()),
            gene: value.gene,
            file_name: value.file_name,
        }
    }
}

impl From<DownloadProgress> for FrbDownloadProgress {
    fn from(value: DownloadProgress) -> Self {
        Self {
            done: value.done,
            total: value.total,
            bytes: value.bytes,
            bytes_total: value.bytes_total,
            bytes_per_second: value.bytes_per_second,
            stage: value.stage.into(),
            retry_attempt: value.retry_attempt,
            retry_max: value.retry_max,
            statuses: value
                .statuses
                .into_iter()
                .map(|(key, status)| FrbRecordStatusEntry {
                    key,
                    status: status.into(),
                })
                .collect(),
        }
    }
}

impl From<DownloadReport> for FrbDownloadReport {
    fn from(value: DownloadReport) -> Self {
        Self {
            completed: value.completed,
            failures: value
                .failures
                .into_iter()
                .map(|f| FrbDownloadFailure {
                    record_key: f.record_key,
                    accession: f.accession,
                    reason: f.reason,
                })
                .collect(),
        }
    }
}

impl From<CompletedDownload> for FrbCompletedDownload {
    fn from(value: CompletedDownload) -> Self {
        Self {
            files: value
                .files
                .into_iter()
                .map(|p| p.to_string_lossy().into_owned())
                .collect(),
            data_type: value.data_type,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_monitor_cancel_and_snapshot() {
        let monitor = DownloadMonitor::new();
        assert!(!monitor.is_cancelled());
        monitor.reporter().on_progress(DownloadProgress {
            done: 1,
            total: 2,
            bytes: 100,
            bytes_total: 200,
            bytes_per_second: Some(50),
            stage: DownloadStage::Downloading,
            retry_attempt: None,
            retry_max: None,
            statuses: vec![("nucleotide:U49845".to_string(), RecordDownloadStatus::Done)],
        });
        let snap = monitor.inner.snapshot.lock().unwrap().clone().unwrap();
        assert_eq!(snap.done, 1);
        assert_eq!(snap.bytes_per_second, Some(50));
        assert_eq!(snap.stage, FrbDownloadStage::Downloading);
        monitor.cancel();
        assert!(monitor.is_cancelled());
        monitor.close();
    }
}
