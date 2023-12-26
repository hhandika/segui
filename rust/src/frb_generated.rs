// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.3.

#![allow(
    non_camel_case_types,
    unused,
    non_snake_case,
    clippy::needless_return,
    clippy::redundant_closure_call,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    clippy::unused_unit,
    clippy::double_parens,
    clippy::let_and_return,
    clippy::too_many_arguments
)]

// Section: imports

use flutter_rust_bridge::for_generated::byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use flutter_rust_bridge::for_generated::transform_result_dco;
use flutter_rust_bridge::{Handler, IntoIntoDart};

// Section: boilerplate

flutter_rust_bridge::frb_generated_boilerplate!();

// Section: executor

flutter_rust_bridge::frb_generated_default_handler!();

// Section: wire_funcs

fn wire_init_logger_impl(
    path: impl CstDecode<String> + core::panic::UnwindSafe,
) -> flutter_rust_bridge::for_generated::WireSyncRust2DartDco {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_sync::<flutter_rust_bridge::for_generated::DcoCodec, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "init_logger",
            port: None,
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Sync,
        },
        move || {
            let api_path = path.cst_decode();
            transform_result_dco((move || {
                Result::<_, ()>::Ok(crate::api::common::init_logger(api_path))
            })())
        },
    )
}
fn wire_ContigServices_new_impl(port_: flutter_rust_bridge::for_generated::MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "ContigServices_new",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::contig::ContigServices::new())
                })())
            }
        },
    )
}
fn wire_ContigServices_summarize_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::contig::ContigServices> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "ContigServices_summarize",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::contig::ContigServices::summarize(&api_that))
                })())
            }
        },
    )
}
fn wire_FastqServices_new_impl(port_: flutter_rust_bridge::for_generated::MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "FastqServices_new",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::fastq::FastqServices::new())
                })())
            }
        },
    )
}
fn wire_FastqServices_summarize_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::fastq::FastqServices> + core::panic::UnwindSafe,
    mode: impl CstDecode<String> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "FastqServices_summarize",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_mode = mode.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::fastq::FastqServices::summarize(
                        &api_that, api_mode,
                    ))
                })())
            }
        },
    )
}
fn wire_SequenceServices_concat_alignment_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::sequence::SequenceServices> + core::panic::UnwindSafe,
    out_fname: impl CstDecode<String> + core::panic::UnwindSafe,
    out_fmt_str: impl CstDecode<String> + core::panic::UnwindSafe,
    partition_fmt: impl CstDecode<String> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_concat_alignment",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_out_fname = out_fname.cst_decode();
            let api_out_fmt_str = out_fmt_str.cst_decode();
            let api_partition_fmt = partition_fmt.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::SequenceServices::concat_alignment(
                        &api_that,
                        api_out_fname,
                        api_out_fmt_str,
                        api_partition_fmt,
                    ))
                })())
            }
        },
    )
}
fn wire_SequenceServices_convert_sequence_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::sequence::SequenceServices> + core::panic::UnwindSafe,
    output_fmt: impl CstDecode<String> + core::panic::UnwindSafe,
    sort: impl CstDecode<bool> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_convert_sequence",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_output_fmt = output_fmt.cst_decode();
            let api_sort = sort.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::SequenceServices::convert_sequence(
                        &api_that,
                        api_output_fmt,
                        api_sort,
                    ))
                })())
            }
        },
    )
}
fn wire_SequenceServices_new_impl(port_: flutter_rust_bridge::for_generated::MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_new",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::SequenceServices::new())
                })())
            }
        },
    )
}
fn wire_SequenceServices_parse_sequence_id_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::sequence::SequenceServices> + core::panic::UnwindSafe,
    is_map: impl CstDecode<bool> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_parse_sequence_id",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_is_map = is_map.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::SequenceServices::parse_sequence_id(
                        &api_that, api_is_map,
                    ))
                })())
            }
        },
    )
}
fn wire_SequenceServices_summarize_alignment_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::sequence::SequenceServices> + core::panic::UnwindSafe,
    output_prefix: impl CstDecode<String> + core::panic::UnwindSafe,
    interval: impl CstDecode<usize> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_summarize_alignment",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_output_prefix = output_prefix.cst_decode();
            let api_interval = interval.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(
                        crate::api::sequence::SequenceServices::summarize_alignment(
                            &api_that,
                            api_output_prefix,
                            api_interval,
                        ),
                    )
                })())
            }
        },
    )
}
fn wire_SequenceServices_translate_sequence_impl(
    port_: flutter_rust_bridge::for_generated::MessagePort,
    that: impl CstDecode<crate::api::sequence::SequenceServices> + core::panic::UnwindSafe,
    table: impl CstDecode<String> + core::panic::UnwindSafe,
    reading_frame: impl CstDecode<usize> + core::panic::UnwindSafe,
    output_fmt: impl CstDecode<String> + core::panic::UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "SequenceServices_translate_sequence",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            let api_that = that.cst_decode();
            let api_table = table.cst_decode();
            let api_reading_frame = reading_frame.cst_decode();
            let api_output_fmt = output_fmt.cst_decode();
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::SequenceServices::translate_sequence(
                        &api_that,
                        api_table,
                        api_reading_frame,
                        api_output_fmt,
                    ))
                })())
            }
        },
    )
}
fn wire_show_dna_uppercase_impl(port_: flutter_rust_bridge::for_generated::MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap_normal::<flutter_rust_bridge::for_generated::DcoCodec, _, _>(
        flutter_rust_bridge::for_generated::TaskInfo {
            debug_name: "show_dna_uppercase",
            port: Some(port_),
            mode: flutter_rust_bridge::for_generated::FfiCallMode::Normal,
        },
        move || {
            move |context| {
                transform_result_dco((move || {
                    Result::<_, ()>::Ok(crate::api::sequence::show_dna_uppercase())
                })())
            }
        },
    )
}

// Section: dart2rust

impl CstDecode<bool> for bool {
    fn cst_decode(self) -> bool {
        self
    }
}
impl CstDecode<u8> for u8 {
    fn cst_decode(self) -> u8 {
        self
    }
}
impl CstDecode<usize> for usize {
    fn cst_decode(self) -> usize {
        self
    }
}
impl SseDecode for String {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut inner = <Vec<u8>>::sse_decode(deserializer);
        return String::from_utf8(inner).unwrap();
    }
}

impl SseDecode for bool {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        deserializer.cursor.read_u8().unwrap() != 0
    }
}

impl SseDecode for crate::api::contig::ContigServices {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut var_dirPath = <Option<String>>::sse_decode(deserializer);
        let mut var_files = <Vec<String>>::sse_decode(deserializer);
        let mut var_fileFmt = <String>::sse_decode(deserializer);
        let mut var_outputDir = <String>::sse_decode(deserializer);
        return crate::api::contig::ContigServices {
            dir_path: var_dirPath,
            files: var_files,
            file_fmt: var_fileFmt,
            output_dir: var_outputDir,
        };
    }
}

impl SseDecode for crate::api::fastq::FastqServices {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut var_dirPath = <Option<String>>::sse_decode(deserializer);
        let mut var_files = <Vec<String>>::sse_decode(deserializer);
        let mut var_fileFmt = <String>::sse_decode(deserializer);
        let mut var_outputDir = <String>::sse_decode(deserializer);
        return crate::api::fastq::FastqServices {
            dir_path: var_dirPath,
            files: var_files,
            file_fmt: var_fileFmt,
            output_dir: var_outputDir,
        };
    }
}

impl SseDecode for Vec<String> {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut len_ = <i32>::sse_decode(deserializer);
        let mut ans_ = vec![];
        for idx_ in 0..len_ {
            ans_.push(<String>::sse_decode(deserializer));
        }
        return ans_;
    }
}

impl SseDecode for Vec<u8> {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut len_ = <i32>::sse_decode(deserializer);
        let mut ans_ = vec![];
        for idx_ in 0..len_ {
            ans_.push(<u8>::sse_decode(deserializer));
        }
        return ans_;
    }
}

impl SseDecode for Option<String> {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        if (<bool>::sse_decode(deserializer)) {
            return Some(<String>::sse_decode(deserializer));
        } else {
            return None;
        }
    }
}

impl SseDecode for crate::api::sequence::SequenceServices {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        let mut var_dirPath = <Option<String>>::sse_decode(deserializer);
        let mut var_files = <Vec<String>>::sse_decode(deserializer);
        let mut var_fileFmt = <String>::sse_decode(deserializer);
        let mut var_datatype = <String>::sse_decode(deserializer);
        let mut var_outputDir = <String>::sse_decode(deserializer);
        return crate::api::sequence::SequenceServices {
            dir_path: var_dirPath,
            files: var_files,
            file_fmt: var_fileFmt,
            datatype: var_datatype,
            output_dir: var_outputDir,
        };
    }
}

impl SseDecode for u8 {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        deserializer.cursor.read_u8().unwrap()
    }
}

impl SseDecode for () {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {}
}

impl SseDecode for usize {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        deserializer.cursor.read_u64::<NativeEndian>().unwrap() as _
    }
}

impl SseDecode for i32 {
    fn sse_decode(deserializer: &mut flutter_rust_bridge::for_generated::SseDeserializer) -> Self {
        deserializer.cursor.read_i32::<NativeEndian>().unwrap()
    }
}

// Section: rust2dart

impl flutter_rust_bridge::IntoDart for crate::api::contig::ContigServices {
    fn into_dart(self) -> flutter_rust_bridge::for_generated::DartAbi {
        vec![
            self.dir_path.into_into_dart().into_dart(),
            self.files.into_into_dart().into_dart(),
            self.file_fmt.into_into_dart().into_dart(),
            self.output_dir.into_into_dart().into_dart(),
        ]
        .into_dart()
    }
}
impl flutter_rust_bridge::for_generated::IntoDartExceptPrimitive
    for crate::api::contig::ContigServices
{
}
impl flutter_rust_bridge::IntoIntoDart<crate::api::contig::ContigServices>
    for crate::api::contig::ContigServices
{
    fn into_into_dart(self) -> crate::api::contig::ContigServices {
        self
    }
}
impl flutter_rust_bridge::IntoDart for crate::api::fastq::FastqServices {
    fn into_dart(self) -> flutter_rust_bridge::for_generated::DartAbi {
        vec![
            self.dir_path.into_into_dart().into_dart(),
            self.files.into_into_dart().into_dart(),
            self.file_fmt.into_into_dart().into_dart(),
            self.output_dir.into_into_dart().into_dart(),
        ]
        .into_dart()
    }
}
impl flutter_rust_bridge::for_generated::IntoDartExceptPrimitive
    for crate::api::fastq::FastqServices
{
}
impl flutter_rust_bridge::IntoIntoDart<crate::api::fastq::FastqServices>
    for crate::api::fastq::FastqServices
{
    fn into_into_dart(self) -> crate::api::fastq::FastqServices {
        self
    }
}
impl flutter_rust_bridge::IntoDart for crate::api::sequence::SequenceServices {
    fn into_dart(self) -> flutter_rust_bridge::for_generated::DartAbi {
        vec![
            self.dir_path.into_into_dart().into_dart(),
            self.files.into_into_dart().into_dart(),
            self.file_fmt.into_into_dart().into_dart(),
            self.datatype.into_into_dart().into_dart(),
            self.output_dir.into_into_dart().into_dart(),
        ]
        .into_dart()
    }
}
impl flutter_rust_bridge::for_generated::IntoDartExceptPrimitive
    for crate::api::sequence::SequenceServices
{
}
impl flutter_rust_bridge::IntoIntoDart<crate::api::sequence::SequenceServices>
    for crate::api::sequence::SequenceServices
{
    fn into_into_dart(self) -> crate::api::sequence::SequenceServices {
        self
    }
}

impl SseEncode for String {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <Vec<u8>>::sse_encode(self.into_bytes(), serializer);
    }
}

impl SseEncode for bool {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        serializer.cursor.write_u8(self as _).unwrap();
    }
}

impl SseEncode for crate::api::contig::ContigServices {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <Option<String>>::sse_encode(self.dir_path, serializer);
        <Vec<String>>::sse_encode(self.files, serializer);
        <String>::sse_encode(self.file_fmt, serializer);
        <String>::sse_encode(self.output_dir, serializer);
    }
}

impl SseEncode for crate::api::fastq::FastqServices {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <Option<String>>::sse_encode(self.dir_path, serializer);
        <Vec<String>>::sse_encode(self.files, serializer);
        <String>::sse_encode(self.file_fmt, serializer);
        <String>::sse_encode(self.output_dir, serializer);
    }
}

impl SseEncode for Vec<String> {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <i32>::sse_encode(self.len() as _, serializer);
        for item in self {
            <String>::sse_encode(item, serializer);
        }
    }
}

impl SseEncode for Vec<u8> {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <i32>::sse_encode(self.len() as _, serializer);
        for item in self {
            <u8>::sse_encode(item, serializer);
        }
    }
}

impl SseEncode for Option<String> {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <bool>::sse_encode(self.is_some(), serializer);
        if let Some(value) = self {
            <String>::sse_encode(value, serializer);
        }
    }
}

impl SseEncode for crate::api::sequence::SequenceServices {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        <Option<String>>::sse_encode(self.dir_path, serializer);
        <Vec<String>>::sse_encode(self.files, serializer);
        <String>::sse_encode(self.file_fmt, serializer);
        <String>::sse_encode(self.datatype, serializer);
        <String>::sse_encode(self.output_dir, serializer);
    }
}

impl SseEncode for u8 {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        serializer.cursor.write_u8(self).unwrap();
    }
}

impl SseEncode for () {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {}
}

impl SseEncode for usize {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        serializer
            .cursor
            .write_u64::<NativeEndian>(self as _)
            .unwrap();
    }
}

impl SseEncode for i32 {
    fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
        serializer.cursor.write_i32::<NativeEndian>(self).unwrap();
    }
}

#[cfg(not(target_family = "wasm"))]
#[path = "frb_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;

/// cbindgen:ignore
#[cfg(target_family = "wasm")]
#[path = "frb_generated.web.rs"]
mod web;
#[cfg(target_family = "wasm")]
pub use web::*;
