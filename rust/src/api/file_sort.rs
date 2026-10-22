//! Order and size files for the viewer's file list.

use std::cmp::Ordering;
use std::fs;
use std::path::Path;

use flutter_rust_bridge::frb;

/// What a file list is ordered by.
pub enum FileSortKey {
    /// The whole path, so files group by folder.
    Path,
    /// The file name only.
    Name,
    /// File size, then name. Files without a size go last.
    Size,
}

pub struct FileListServices {
    pub paths: Vec<String>,
}

impl FileListServices {
    #[frb(sync)]
    pub fn new(paths: Vec<String>) -> FileListServices {
        FileListServices { paths }
    }

    /// Positions of the paths in sorted order. Names compare naturally:
    /// digit runs as numbers, so `uce-2` comes before `uce-10`, and letters
    /// ignoring case. `sizes` lines up with the paths and is only read when
    /// sorting by size; files without a size go last either way.
    #[frb(sync)]
    pub fn order(&self, key: FileSortKey, ascending: bool, sizes: Vec<Option<i64>>) -> Vec<u32> {
        let mut order: Vec<usize> = (0..self.paths.len()).collect();
        order.sort_by(|&a, &b| self.compare(a, b, &key, ascending, &sizes));
        order
            .into_iter()
            .map(|i| u32::try_from(i).unwrap_or(u32::MAX))
            .collect()
    }

    /// Size in bytes of each path, or none when it cannot be read.
    pub fn sizes(&self) -> Vec<Option<i64>> {
        self.paths
            .iter()
            .map(|path| {
                fs::metadata(path)
                    .ok()
                    .and_then(|meta| i64::try_from(meta.len()).ok())
            })
            .collect()
    }

    fn compare(
        &self,
        a: usize,
        b: usize,
        key: &FileSortKey,
        ascending: bool,
        sizes: &[Option<i64>],
    ) -> Ordering {
        let directed = |ordering: Ordering| {
            if ascending {
                ordering
            } else {
                ordering.reverse()
            }
        };
        if let FileSortKey::Size = key {
            let size_a = sizes.get(a).copied().flatten();
            let size_b = sizes.get(b).copied().flatten();
            match (size_a, size_b) {
                (Some(x), Some(y)) if x != y => return directed(x.cmp(&y)),
                (Some(_), None) => return Ordering::Less,
                (None, Some(_)) => return Ordering::Greater,
                _ => {}
            }
        }
        let by_text = match key {
            FileSortKey::Path => compare_natural(&self.paths[a], &self.paths[b]),
            _ => compare_natural(file_name(&self.paths[a]), file_name(&self.paths[b])),
        };
        // Equal names keep their original order.
        match by_text {
            Ordering::Equal => a.cmp(&b),
            ordering => directed(ordering),
        }
    }
}

fn file_name(path: &str) -> &str {
    Path::new(path)
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or(path)
}

/// Compares text the way people read it: digit runs as numbers, ignoring
/// leading zeros, and other characters ignoring case. Ties fall back to the
/// raw text, so the order is total.
fn compare_natural(a: &str, b: &str) -> Ordering {
    let (x, y) = (a.as_bytes(), b.as_bytes());
    let (mut i, mut j) = (0, 0);
    while i < x.len() && j < y.len() {
        if x[i].is_ascii_digit() && y[j].is_ascii_digit() {
            let end_x = digits_end(x, i);
            let end_y = digits_end(y, j);
            match compare_digits(&x[i..end_x], &y[j..end_y]) {
                Ordering::Equal => {}
                ordering => return ordering,
            }
            i = end_x;
            j = end_y;
            continue;
        }
        match x[i].to_ascii_lowercase().cmp(&y[j].to_ascii_lowercase()) {
            Ordering::Equal => {}
            ordering => return ordering,
        }
        i += 1;
        j += 1;
    }
    (x.len() - i).cmp(&(y.len() - j)).then_with(|| a.cmp(b))
}

fn digits_end(text: &[u8], start: usize) -> usize {
    text[start..]
        .iter()
        .position(|c| !c.is_ascii_digit())
        .map_or(text.len(), |offset| start + offset)
}

/// Compares digit runs of any length without parsing them.
fn compare_digits(a: &[u8], b: &[u8]) -> Ordering {
    let trim = |digits: &[u8]| {
        let zeros = digits.iter().take_while(|&&c| c == b'0').count();
        // Keep one digit so "0" still compares as a number.
        digits[zeros.min(digits.len().saturating_sub(1))..].to_vec()
    };
    let (x, y) = (trim(a), trim(b));
    x.len().cmp(&y.len()).then_with(|| x.cmp(&y))
}

#[cfg(test)]
mod test {
    use super::*;

    fn services(paths: &[&str]) -> FileListServices {
        FileListServices::new(paths.iter().map(|p| p.to_string()).collect())
    }

    fn names(list: &FileListServices, order: &[u32]) -> Vec<String> {
        order
            .iter()
            .map(|&i| file_name(&list.paths[i as usize]).to_string())
            .collect()
    }

    #[test]
    fn test_natural_name_order() {
        let list = services(&[
            "uce-10.fas",
            "uce-2.fas",
            "UCE-1.fas",
            "uce-100.fas",
            "uce-02b.fas",
        ]);
        let order = list.order(FileSortKey::Name, true, Vec::new());
        assert_eq!(
            names(&list, &order),
            [
                "UCE-1.fas",
                "uce-2.fas",
                "uce-02b.fas",
                "uce-10.fas",
                "uce-100.fas"
            ]
        );
        let reversed = list.order(FileSortKey::Name, false, Vec::new());
        assert_eq!(
            names(&list, &reversed),
            [
                "uce-100.fas",
                "uce-10.fas",
                "uce-02b.fas",
                "uce-2.fas",
                "UCE-1.fas"
            ]
        );
    }

    #[test]
    fn test_path_groups_by_folder() {
        let join = |dir: &str, name: &str| Path::new(dir).join(name).to_string_lossy().into_owned();
        let list = FileListServices::new(vec![
            join("b", "locus-1.fas"),
            join("a", "locus-2.fas"),
            join("a", "locus-10.fas"),
        ]);
        let order = list.order(FileSortKey::Path, true, Vec::new());
        assert_eq!(order, [1, 2, 0]);
    }

    #[test]
    fn test_size_order_puts_unsized_last() {
        let list = services(&["a.fas", "b.fas", "c.fas"]);
        let sizes = vec![Some(10), None, Some(30)];
        assert_eq!(
            list.order(FileSortKey::Size, true, sizes.clone()),
            [0, 2, 1]
        );
        assert_eq!(list.order(FileSortKey::Size, false, sizes), [2, 0, 1]);
    }

    #[test]
    fn test_equal_names_keep_order() {
        let list = services(&["x/a.fas", "y/a.fas"]);
        assert_eq!(list.order(FileSortKey::Name, true, Vec::new()), [0, 1]);
        assert_eq!(list.order(FileSortKey::Name, false, Vec::new()), [0, 1]);
    }

    #[test]
    fn test_sizes_reads_files() {
        let fixture = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
            .join("alignments")
            .join("gene_1.fas");
        let missing = Path::new(env!("CARGO_MANIFEST_DIR")).join("no-such-file.fas");
        let list = FileListServices::new(vec![
            fixture.to_string_lossy().into_owned(),
            missing.to_string_lossy().into_owned(),
        ]);
        let sizes = list.sizes();
        assert!(sizes[0].is_some_and(|size| size > 0));
        assert_eq!(sizes[1], None);
    }
}
