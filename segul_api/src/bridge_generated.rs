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
fn wire_new__static_method__SegulServices_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "new__static_method__SegulServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(SegulServices::new()),
    )
}
fn wire_concat_alignment__method__SegulServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SegulServices> + UnwindSafe,
    output_fmt: impl Wire2Api<String> + UnwindSafe,
    partition_fmt: impl Wire2Api<String> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "concat_alignment__method__SegulServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_output_fmt = output_fmt.wire2api();
            let api_partition_fmt = partition_fmt.wire2api();
            move |task_callback| {
                Ok(SegulServices::concat_alignment(
                    &api_that,
                    api_output_fmt,
                    api_partition_fmt,
                ))
            }
        },
    )
}
fn wire_convert_sequence__method__SegulServices_impl(
    port_: MessagePort,
    that: impl Wire2Api<SegulServices> + UnwindSafe,
    output_fmt: impl Wire2Api<String> + UnwindSafe,
    sort: impl Wire2Api<bool> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "convert_sequence__method__SegulServices",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_that = that.wire2api();
            let api_output_fmt = output_fmt.wire2api();
            let api_sort = sort.wire2api();
            move |task_callback| {
                Ok(SegulServices::convert_sequence(
                    &api_that,
                    api_output_fmt,
                    api_sort,
                ))
            }
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

// Section: impl IntoDart

impl support::IntoDart for SegulServices {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.dir_path.into_dart(),
            self.file_fmt.into_dart(),
            self.datatype.into_dart(),
            self.output.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SegulServices {}

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

#[cfg(not(target_family = "wasm"))]
#[path = "bridge_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;