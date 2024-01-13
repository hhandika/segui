// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.18.

// Section: imports

use super::*;
use flutter_rust_bridge::for_generated::byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use flutter_rust_bridge::for_generated::transform_result_dco;
use flutter_rust_bridge::{Handler, IntoIntoDart};

// Section: dart2rust

impl CstDecode<String> for *mut wire_cst_list_prim_u_8_strict {
    fn cst_decode(self) -> String {
        let vec: Vec<u8> = self.cst_decode();
        String::from_utf8(vec).unwrap()
    }
}
impl CstDecode<crate::api::sequence::AlignmentServices> for wire_cst_alignment_services {
    fn cst_decode(self) -> crate::api::sequence::AlignmentServices {
        crate::api::sequence::AlignmentServices {
            dir: self.dir.cst_decode(),
            input_files: self.input_files.cst_decode(),
            input_fmt: self.input_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::sequence::AlignmentServices> for *mut wire_cst_alignment_services {
    fn cst_decode(self) -> crate::api::sequence::AlignmentServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::AlignmentServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::contig::ContigServices> for *mut wire_cst_contig_services {
    fn cst_decode(self) -> crate::api::contig::ContigServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::contig::ContigServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::sequence::FilteringServices> for *mut wire_cst_filtering_services {
    fn cst_decode(self) -> crate::api::sequence::FilteringServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::FilteringServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::sequence::PartitionServices> for *mut wire_cst_partition_services {
    fn cst_decode(self) -> crate::api::sequence::PartitionServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::PartitionServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::reads::RawReadServices> for *mut wire_cst_raw_read_services {
    fn cst_decode(self) -> crate::api::reads::RawReadServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::reads::RawReadServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::sequence::SequenceRemoval> for *mut wire_cst_sequence_removal {
    fn cst_decode(self) -> crate::api::sequence::SequenceRemoval {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::SequenceRemoval>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::sequence::SequenceServices> for *mut wire_cst_sequence_services {
    fn cst_decode(self) -> crate::api::sequence::SequenceServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::SequenceServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<crate::api::sequence::SplitAlignmentServices>
    for *mut wire_cst_split_alignment_services
{
    fn cst_decode(self) -> crate::api::sequence::SplitAlignmentServices {
        let wrap = unsafe { flutter_rust_bridge::for_generated::box_from_leak_ptr(self) };
        CstDecode::<crate::api::sequence::SplitAlignmentServices>::cst_decode(*wrap).into()
    }
}
impl CstDecode<usize> for *mut usize {
    fn cst_decode(self) -> usize {
        unsafe { *flutter_rust_bridge::for_generated::box_from_leak_ptr(self) }
    }
}
impl CstDecode<crate::api::contig::ContigServices> for wire_cst_contig_services {
    fn cst_decode(self) -> crate::api::contig::ContigServices {
        crate::api::contig::ContigServices {
            dir_path: self.dir_path.cst_decode(),
            files: self.files.cst_decode(),
            file_fmt: self.file_fmt.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::sequence::FilteringServices> for wire_cst_filtering_services {
    fn cst_decode(self) -> crate::api::sequence::FilteringServices {
        crate::api::sequence::FilteringServices {
            dir: self.dir.cst_decode(),
            input_files: self.input_files.cst_decode(),
            input_fmt: self.input_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
            is_concat: self.is_concat.cst_decode(),
        }
    }
}
impl CstDecode<Vec<String>> for *mut wire_cst_list_String {
    fn cst_decode(self) -> Vec<String> {
        let vec = unsafe {
            let wrap = flutter_rust_bridge::for_generated::box_from_leak_ptr(self);
            flutter_rust_bridge::for_generated::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(CstDecode::cst_decode).collect()
    }
}
impl CstDecode<Vec<u8>> for *mut wire_cst_list_prim_u_8_strict {
    fn cst_decode(self) -> Vec<u8> {
        unsafe {
            let wrap = flutter_rust_bridge::for_generated::box_from_leak_ptr(self);
            flutter_rust_bridge::for_generated::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
impl CstDecode<crate::api::sequence::PartitionServices> for wire_cst_partition_services {
    fn cst_decode(self) -> crate::api::sequence::PartitionServices {
        crate::api::sequence::PartitionServices {
            input_files: self.input_files.cst_decode(),
            input_part_fmt: self.input_part_fmt.cst_decode(),
            output: self.output.cst_decode(),
            output_part_fmt: self.output_part_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            is_uncheck: self.is_uncheck.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::reads::RawReadServices> for wire_cst_raw_read_services {
    fn cst_decode(self) -> crate::api::reads::RawReadServices {
        crate::api::reads::RawReadServices {
            dir_path: self.dir_path.cst_decode(),
            files: self.files.cst_decode(),
            file_fmt: self.file_fmt.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::sequence::SequenceRemoval> for wire_cst_sequence_removal {
    fn cst_decode(self) -> crate::api::sequence::SequenceRemoval {
        crate::api::sequence::SequenceRemoval {
            input_files: self.input_files.cst_decode(),
            input_fmt: self.input_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
            output_fmt: self.output_fmt.cst_decode(),
            remove_regex: self.remove_regex.cst_decode(),
            remove_list: self.remove_list.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::sequence::SequenceServices> for wire_cst_sequence_services {
    fn cst_decode(self) -> crate::api::sequence::SequenceServices {
        crate::api::sequence::SequenceServices {
            dir: self.dir.cst_decode(),
            input_files: self.input_files.cst_decode(),
            input_fmt: self.input_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
        }
    }
}
impl CstDecode<crate::api::sequence::SplitAlignmentServices> for wire_cst_split_alignment_services {
    fn cst_decode(self) -> crate::api::sequence::SplitAlignmentServices {
        crate::api::sequence::SplitAlignmentServices {
            dir: self.dir.cst_decode(),
            input_file: self.input_file.cst_decode(),
            input_fmt: self.input_fmt.cst_decode(),
            datatype: self.datatype.cst_decode(),
            input_partition: self.input_partition.cst_decode(),
            input_partition_fmt: self.input_partition_fmt.cst_decode(),
            output_dir: self.output_dir.cst_decode(),
            prefix: self.prefix.cst_decode(),
            output_fmt: self.output_fmt.cst_decode(),
            is_uncheck: self.is_uncheck.cst_decode(),
        }
    }
}
pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}
impl NewWithNullPtr for wire_cst_alignment_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir: core::ptr::null_mut(),
            input_files: core::ptr::null_mut(),
            input_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}
impl Default for wire_cst_alignment_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_contig_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            files: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}
impl Default for wire_cst_contig_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_filtering_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir: core::ptr::null_mut(),
            input_files: core::ptr::null_mut(),
            input_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
            is_concat: Default::default(),
        }
    }
}
impl Default for wire_cst_filtering_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_partition_services {
    fn new_with_null_ptr() -> Self {
        Self {
            input_files: core::ptr::null_mut(),
            input_part_fmt: core::ptr::null_mut(),
            output: core::ptr::null_mut(),
            output_part_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            is_uncheck: Default::default(),
        }
    }
}
impl Default for wire_cst_partition_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_raw_read_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            files: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}
impl Default for wire_cst_raw_read_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_sequence_removal {
    fn new_with_null_ptr() -> Self {
        Self {
            input_files: core::ptr::null_mut(),
            input_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
            output_fmt: core::ptr::null_mut(),
            remove_regex: core::ptr::null_mut(),
            remove_list: core::ptr::null_mut(),
        }
    }
}
impl Default for wire_cst_sequence_removal {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_sequence_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir: core::ptr::null_mut(),
            input_files: core::ptr::null_mut(),
            input_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}
impl Default for wire_cst_sequence_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}
impl NewWithNullPtr for wire_cst_split_alignment_services {
    fn new_with_null_ptr() -> Self {
        Self {
            dir: core::ptr::null_mut(),
            input_file: core::ptr::null_mut(),
            input_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            input_partition: core::ptr::null_mut(),
            input_partition_fmt: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
            prefix: core::ptr::null_mut(),
            output_fmt: core::ptr::null_mut(),
            is_uncheck: Default::default(),
        }
    }
}
impl Default for wire_cst_split_alignment_services {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

#[no_mangle]
pub extern "C" fn frbgen_segui_dart_fn_deliver_output(
    call_id: i32,
    ptr_: *mut u8,
    rust_vec_len_: i32,
    data_len_: i32,
) {
    let message = unsafe {
        flutter_rust_bridge::for_generated::Dart2RustMessageSse::from_wire(
            ptr_,
            rust_vec_len_,
            data_len_,
        )
    };
    FLUTTER_RUST_BRIDGE_HANDLER.dart_fn_handle_output(call_id, message)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_init_logger(
    port_: i64,
    log_dir: *mut wire_cst_list_prim_u_8_strict,
) {
    wire_init_logger_impl(port_, log_dir)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_ContigServices_new(port_: i64) {
    wire_ContigServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_ContigServices_summarize(
    port_: i64,
    that: *mut wire_cst_contig_services,
) {
    wire_ContigServices_summarize_impl(port_, that)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_RawReadServices_new(port_: i64) {
    wire_RawReadServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_RawReadServices_summarize(
    port_: i64,
    that: *mut wire_cst_raw_read_services,
    mode: *mut wire_cst_list_prim_u_8_strict,
) {
    wire_RawReadServices_summarize_impl(port_, that, mode)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_AlignmentServices_concat_alignment(
    port_: i64,
    that: *mut wire_cst_alignment_services,
    out_fname: *mut wire_cst_list_prim_u_8_strict,
    out_fmt_str: *mut wire_cst_list_prim_u_8_strict,
    partition_fmt: *mut wire_cst_list_prim_u_8_strict,
) {
    wire_AlignmentServices_concat_alignment_impl(port_, that, out_fname, out_fmt_str, partition_fmt)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_AlignmentServices_new(port_: i64) {
    wire_AlignmentServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_AlignmentServices_summarize_alignment(
    port_: i64,
    that: *mut wire_cst_alignment_services,
    output_prefix: *mut wire_cst_list_prim_u_8_strict,
    interval: usize,
) {
    wire_AlignmentServices_summarize_alignment_impl(port_, that, output_prefix, interval)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_FilteringServices_filter_minimal_length(
    port_: i64,
    that: *mut wire_cst_filtering_services,
    length: usize,
) {
    wire_FilteringServices_filter_minimal_length_impl(port_, that, length)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_FilteringServices_filter_minimal_taxa(
    port_: i64,
    that: *mut wire_cst_filtering_services,
    percent: f64,
    taxon_count: *mut usize,
) {
    wire_FilteringServices_filter_minimal_taxa_impl(port_, that, percent, taxon_count)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_FilteringServices_filter_parsimony_inf_count(
    port_: i64,
    that: *mut wire_cst_filtering_services,
    count: usize,
) {
    wire_FilteringServices_filter_parsimony_inf_count_impl(port_, that, count)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_FilteringServices_filter_percent_informative(
    port_: i64,
    that: *mut wire_cst_filtering_services,
    percent: f64,
) {
    wire_FilteringServices_filter_percent_informative_impl(port_, that, percent)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_FilteringServices_new(port_: i64) {
    wire_FilteringServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_PartitionServices_convert_partition(
    port_: i64,
    that: *mut wire_cst_partition_services,
) {
    wire_PartitionServices_convert_partition_impl(port_, that)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_PartitionServices_new(port_: i64) {
    wire_PartitionServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceRemoval_new(port_: i64) {
    wire_SequenceRemoval_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceRemoval_remove_sequence(
    port_: i64,
    that: *mut wire_cst_sequence_removal,
) {
    wire_SequenceRemoval_remove_sequence_impl(port_, that)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceServices_convert_sequence(
    port_: i64,
    that: *mut wire_cst_sequence_services,
    output_fmt: *mut wire_cst_list_prim_u_8_strict,
    sort: bool,
) {
    wire_SequenceServices_convert_sequence_impl(port_, that, output_fmt, sort)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceServices_new(port_: i64) {
    wire_SequenceServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceServices_parse_sequence_id(
    port_: i64,
    that: *mut wire_cst_sequence_services,
    output_fname: *mut wire_cst_list_prim_u_8_strict,
    is_map: bool,
) {
    wire_SequenceServices_parse_sequence_id_impl(port_, that, output_fname, is_map)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SequenceServices_translate_sequence(
    port_: i64,
    that: *mut wire_cst_sequence_services,
    table: *mut wire_cst_list_prim_u_8_strict,
    reading_frame: usize,
    output_fmt: *mut wire_cst_list_prim_u_8_strict,
) {
    wire_SequenceServices_translate_sequence_impl(port_, that, table, reading_frame, output_fmt)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SplitAlignmentServices_new(port_: i64) {
    wire_SplitAlignmentServices_new_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_SplitAlignmentServices_split_alignment(
    port_: i64,
    that: *mut wire_cst_split_alignment_services,
) {
    wire_SplitAlignmentServices_split_alignment_impl(port_, that)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_wire_show_dna_uppercase(port_: i64) {
    wire_show_dna_uppercase_impl(port_)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_alignment_services(
) -> *mut wire_cst_alignment_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_alignment_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_contig_services() -> *mut wire_cst_contig_services
{
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_contig_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_filtering_services(
) -> *mut wire_cst_filtering_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_filtering_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_partition_services(
) -> *mut wire_cst_partition_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_partition_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_raw_read_services(
) -> *mut wire_cst_raw_read_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_raw_read_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_sequence_removal(
) -> *mut wire_cst_sequence_removal {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_sequence_removal::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_sequence_services(
) -> *mut wire_cst_sequence_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_sequence_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_split_alignment_services(
) -> *mut wire_cst_split_alignment_services {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(
        wire_cst_split_alignment_services::new_with_null_ptr(),
    )
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_box_autoadd_usize(value: usize) -> *mut usize {
    flutter_rust_bridge::for_generated::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_list_String(len: i32) -> *mut wire_cst_list_String {
    let wrap = wire_cst_list_String {
        ptr: flutter_rust_bridge::for_generated::new_leak_vec_ptr(
            <*mut wire_cst_list_prim_u_8_strict>::new_with_null_ptr(),
            len,
        ),
        len,
    };
    flutter_rust_bridge::for_generated::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn frbgen_segui_cst_new_list_prim_u_8_strict(
    len: i32,
) -> *mut wire_cst_list_prim_u_8_strict {
    let ans = wire_cst_list_prim_u_8_strict {
        ptr: flutter_rust_bridge::for_generated::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    flutter_rust_bridge::for_generated::new_leak_box_ptr(ans)
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_alignment_services {
    dir: *mut wire_cst_list_prim_u_8_strict,
    input_files: *mut wire_cst_list_String,
    input_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_contig_services {
    dir_path: *mut wire_cst_list_prim_u_8_strict,
    files: *mut wire_cst_list_String,
    file_fmt: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_filtering_services {
    dir: *mut wire_cst_list_prim_u_8_strict,
    input_files: *mut wire_cst_list_String,
    input_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
    is_concat: bool,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_list_String {
    ptr: *mut *mut wire_cst_list_prim_u_8_strict,
    len: i32,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_list_prim_u_8_strict {
    ptr: *mut u8,
    len: i32,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_partition_services {
    input_files: *mut wire_cst_list_String,
    input_part_fmt: *mut wire_cst_list_prim_u_8_strict,
    output: *mut wire_cst_list_prim_u_8_strict,
    output_part_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    is_uncheck: bool,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_raw_read_services {
    dir_path: *mut wire_cst_list_prim_u_8_strict,
    files: *mut wire_cst_list_String,
    file_fmt: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_sequence_removal {
    input_files: *mut wire_cst_list_String,
    input_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
    output_fmt: *mut wire_cst_list_prim_u_8_strict,
    remove_regex: *mut wire_cst_list_prim_u_8_strict,
    remove_list: *mut wire_cst_list_String,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_sequence_services {
    dir: *mut wire_cst_list_prim_u_8_strict,
    input_files: *mut wire_cst_list_String,
    input_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct wire_cst_split_alignment_services {
    dir: *mut wire_cst_list_prim_u_8_strict,
    input_file: *mut wire_cst_list_prim_u_8_strict,
    input_fmt: *mut wire_cst_list_prim_u_8_strict,
    datatype: *mut wire_cst_list_prim_u_8_strict,
    input_partition: *mut wire_cst_list_prim_u_8_strict,
    input_partition_fmt: *mut wire_cst_list_prim_u_8_strict,
    output_dir: *mut wire_cst_list_prim_u_8_strict,
    prefix: *mut wire_cst_list_prim_u_8_strict,
    output_fmt: *mut wire_cst_list_prim_u_8_strict,
    is_uncheck: bool,
}
