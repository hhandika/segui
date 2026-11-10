use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::sync::Mutex;

use flutter_rust_bridge::frb;
use segul_core::helper::progress::ProgressReporter;

use crate::frb_generated::StreamSink;

/// Progress of a running task, sent each time a file starts or finishes.
#[derive(Debug, Clone, Default)]
pub struct TaskProgress {
    /// Files finished.
    pub done: u32,
    /// Files in the run.
    pub total: u32,
    /// Name of the file that started most recently.
    pub current_file: Option<String>,
    /// A step after the files are read, such as writing outputs.
    pub stage: Option<String>,
}

/// Follows a running task and cancels it. Create one per run, listen to
/// [`RunMonitor::subscribe`], and pass it to the task.
pub struct RunMonitor {
    sink: Mutex<Option<StreamSink<TaskProgress>>>,
    progress: Mutex<TaskProgress>,
    done: AtomicU32,
    cancelled: AtomicBool,
}

impl RunMonitor {
    #[frb(sync)]
    pub fn new() -> RunMonitor {
        RunMonitor {
            sink: Mutex::new(None),
            progress: Mutex::new(TaskProgress::default()),
            done: AtomicU32::new(0),
            cancelled: AtomicBool::new(false),
        }
    }

    /// Stream of progress updates for this run. Starts with the current
    /// progress, so updates sent before Dart subscribed are not lost.
    pub fn subscribe(&self, sink: StreamSink<TaskProgress>) {
        // Holding the progress lock keeps the snapshot ahead of later updates.
        let Ok(progress) = self.progress.lock() else {
            return;
        };
        let _ = sink.add(progress.clone());
        if let Ok(mut current) = self.sink.lock() {
            *current = Some(sink);
        }
    }

    /// Ends the progress stream. Call it when the task returns; until then
    /// the stream stays open and cancelling a Dart subscription waits.
    #[frb(sync)]
    pub fn close(&self) {
        if let Ok(mut sink) = self.sink.lock() {
            sink.take();
        }
    }

    /// Stop the run. Running files stop at their next block of reads or alignments.
    #[frb(sync)]
    pub fn cancel(&self) {
        self.cancelled.store(true, Ordering::Relaxed);
    }

    #[frb(sync)]
    pub fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::Relaxed)
    }

    fn update(&self, change: impl FnOnce(&mut TaskProgress)) {
        let Ok(mut progress) = self.progress.lock() else {
            return;
        };
        change(&mut progress);
        progress.done = self.done.load(Ordering::Relaxed);
        if let Ok(sink) = self.sink.lock() {
            if let Some(sink) = sink.as_ref() {
                // The Dart side may have stopped listening; progress is best effort.
                let _ = sink.add(progress.clone());
            }
        }
    }
}

impl ProgressReporter for RunMonitor {
    fn on_start(&self, total_files: usize) {
        self.done.store(0, Ordering::Relaxed);
        self.update(|p| {
            p.total = total_files as u32;
            p.current_file = None;
            p.stage = None;
        });
    }

    fn on_file_started(&self, path: &Path) {
        let name = path
            .file_name()
            .map(|name| name.to_string_lossy().into_owned());
        self.update(|p| p.current_file = name);
    }

    fn on_file_finished(&self, _path: &Path) {
        self.done.fetch_add(1, Ordering::Relaxed);
        self.update(|_| {});
    }

    fn on_stage(&self, stage: &str) {
        self.update(|p| {
            p.current_file = None;
            p.stage = Some(stage.to_string());
        });
    }

    fn is_cancelled(&self) -> bool {
        RunMonitor::is_cancelled(self)
    }
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::*;

    #[test]
    fn test_counts_files_without_listener() {
        let monitor = RunMonitor::new();
        monitor.on_start(2);
        monitor.on_file_started(Path::new("a.fastq"));
        monitor.on_file_finished(Path::new("a.fastq"));
        let progress = monitor.progress.lock().unwrap().clone();
        assert_eq!(progress.done, 1);
        assert_eq!(progress.total, 2);
        assert_eq!(progress.current_file.as_deref(), Some("a.fastq"));
    }

    #[test]
    fn test_cancel() {
        let monitor = RunMonitor::new();
        assert!(!ProgressReporter::is_cancelled(&monitor));
        monitor.cancel();
        assert!(ProgressReporter::is_cancelled(&monitor));
    }
}
