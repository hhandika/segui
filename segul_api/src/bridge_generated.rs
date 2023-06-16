#![allow(
    non_camel_case_types,
    unused,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    clippy::double_parens,
    non_snake_case,
    clippy::too_many_arguments
)]
// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.74.0.

use crate::segul_api::*;
use core::panic::UnwindSafe;
use flutter_rust_bridge::*;
use std::ffi::c_void;
use std::sync::Arc;

// Section: imports

// Section: wire functions

fn wire_show_dna_uppercase_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "show_dna_uppercase",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(show_dna_uppercase()),
    )
}
fn wire_new__static_method__SequenceServices_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "new__static_method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(SequenceServices::new()),
    )
}
fn wire_concat_alignment__method__SequenceServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SequenceServices> + UnwindSafe,
    out_fname: impl Wire2Api<String> + UnwindSafe,
    out_fmt_str: impl Wire2Api<String> + UnwindSafe,
    partition_fmt: impl Wire2Api<String> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "concat_alignment__method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_out_fname = out_fname.wire2api();
            let api_out_fmt_str = out_fmt_str.wire2api();
            let api_partition_fmt = partition_fmt.wire2api();
            move |task_callback| {
                Ok(SequenceServices::concat_alignment(
                    &api_that,
                    api_out_fname,
                    api_out_fmt_str,
                    api_partition_fmt,
                ))
            }
        },
    )
}
fn wire_convert_sequence__method__SequenceServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SequenceServices> + UnwindSafe,
    output_fmt: impl Wire2Api<String> + UnwindSafe,
    sort: impl Wire2Api<bool> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "convert_sequence__method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_output_fmt = output_fmt.wire2api();
            let api_sort = sort.wire2api();
            move |task_callback| {
                Ok(SequenceServices::convert_sequence(
                    &api_that,
                    api_output_fmt,
                    api_sort,
                ))
            }
        },
    )
}
fn wire_parse_sequence_id__method__SequenceServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SequenceServices> + UnwindSafe,
    is_map: impl Wire2Api<bool> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "parse_sequence_id__method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_is_map = is_map.wire2api();
            move |task_callback| Ok(SequenceServices::parse_sequence_id(&api_that, api_is_map))
        },
    )
}
fn wire_summarize_alignment__method__SequenceServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SequenceServices> + UnwindSafe,
    output_prefix: impl Wire2Api<String> + UnwindSafe,
    interval: impl Wire2Api<usize> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "summarize_alignment__method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_output_prefix = output_prefix.wire2api();
            let api_interval = interval.wire2api();
            move |task_callback| {
                Ok(SequenceServices::summarize_alignment(
                    &api_that,
                    api_output_prefix,
                    api_interval,
                ))
            }
        },
    )
}
fn wire_translate_sequence__method__SequenceServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SequenceServices> + UnwindSafe,
    table: impl Wire2Api<String> + UnwindSafe,
    reading_frame: impl Wire2Api<usize> + UnwindSafe,
    output_fmt: impl Wire2Api<String> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "translate_sequence__method__SequenceServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_table = table.wire2api();
            let api_reading_frame = reading_frame.wire2api();
            let api_output_fmt = output_fmt.wire2api();
            move |task_callback| {
                Ok(SequenceServices::translate_sequence(
                    &api_that,
                    api_table,
                    api_reading_frame,
                    api_output_fmt,
                ))
            }
        },
    )
}
fn wire_new__static_method__FastqServices_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "new__static_method__FastqServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(FastqServices::new()),
    )
}
fn wire_summarize__method__FastqServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<FastqServices> + UnwindSafe,
    mode: impl Wire2Api<String> + UnwindSafe,
    lowmem: impl Wire2Api<bool> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "summarize__method__FastqServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_mode = mode.wire2api();
            let api_lowmem = lowmem.wire2api();
            move |task_callback| Ok(FastqServices::summarize(&api_that, api_mode, api_lowmem))
        },
    )
}
fn wire_new__static_method__ContigServices_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "new__static_method__ContigServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(ContigServices::new()),
    )
}
fn wire_summarize__method__ContigServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<ContigServices> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "summarize__method__ContigServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            move |task_callback| Ok(ContigServices::summarize(&api_that))
        },
    )
}
// Section: wrapper structs

// Section: static checks

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

pub trait Wire2Api<T> {
    fn wire2api(self) -> T;
}

impl<T, S> Wire2Api<Option<T>> for *mut S
where
    *mut S: Wire2Api<T>,
{
    fn wire2api(self) -> Option<T> {
        (!self.is_null()).then(|| self.wire2api())
    }
}

impl Wire2Api<bool> for bool {
    fn wire2api(self) -> bool {
        self
    }
}

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

impl Wire2Api<usize> for usize {
    fn wire2api(self) -> usize {
        self
    }
}
// Section: impl IntoDart

impl support::IntoDart for ContigServices {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.dir_path.into_dart(),
            self.files.into_dart(),
            self.file_fmt.into_dart(),
            self.output_dir.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for ContigServices {}

impl support::IntoDart for FastqServices {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.dir_path.into_dart(),
            self.files.into_dart(),
            self.file_fmt.into_dart(),
            self.output_dir.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for FastqServices {}

impl support::IntoDart for SequenceServices {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.dir_path.into_dart(),
            self.files.into_dart(),
            self.file_fmt.into_dart(),
            self.datatype.into_dart(),
            self.output_dir.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SequenceServices {}

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

#[cfg(not(target_family = "wasm"))]
#[path = "bridge_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;
