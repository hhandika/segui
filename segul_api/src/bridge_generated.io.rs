use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_show_dna_uppercase(port_: i64) {
    wire_show_dna_uppercase_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_init_logger(port_: i64, path: *mut wire_uint_8_list) {
    wire_init_logger_impl(port_, path)
}

#[no_mangle]
pub extern "C" fn wire_new__static_method__SequenceServices(port_: i64) {
    wire_new__static_method__SequenceServices_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_concat_alignment__method__SequenceServices(
    port_: i64,
    that: *mut wire_SequenceServices,
    out_fname: *mut wire_uint_8_list,
    out_fmt_str: *mut wire_uint_8_list,
    partition_fmt: *mut wire_uint_8_list,
) {
    wire_concat_alignment__method__SequenceServices_impl(
        port_,
        that,
        out_fname,
        out_fmt_str,
        partition_fmt,
    )
}

#[no_mangle]
pub extern "C" fn wire_convert_sequence__method__SequenceServices(
    port_: i64,
    that: *mut wire_SequenceServices,
    output_fmt: *mut wire_uint_8_list,
    sort: bool,
) {
    wire_convert_sequence__method__SequenceServices_impl(port_, that, output_fmt, sort)
}

#[no_mangle]
pub extern "C" fn wire_parse_sequence_id__method__SequenceServices(
    port_: i64,
    that: *mut wire_SequenceServices,
    is_map: bool,
) {
    wire_parse_sequence_id__method__SequenceServices_impl(port_, that, is_map)
}

#[no_mangle]
pub extern "C" fn wire_summarize_alignment__method__SequenceServices(
    port_: i64,
    that: *mut wire_SequenceServices,
    output_prefix: *mut wire_uint_8_list,
    interval: usize,
) {
    wire_summarize_alignment__method__SequenceServices_impl(port_, that, output_prefix, interval)
}

#[no_mangle]
pub extern "C" fn wire_translate_sequence__method__SequenceServices(
    port_: i64,
    that: *mut wire_SequenceServices,
    table: *mut wire_uint_8_list,
    reading_frame: usize,
    output_fmt: *mut wire_uint_8_list,
) {
    wire_translate_sequence__method__SequenceServices_impl(
        port_,
        that,
        table,
        reading_frame,
        output_fmt,
    )
}

#[no_mangle]
pub extern "C" fn wire_new__static_method__FastqServices(port_: i64) {
    wire_new__static_method__FastqServices_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_summarize__method__FastqServices(
    port_: i64,
    that: *mut wire_FastqServices,
    mode: *mut wire_uint_8_list,
    lowmem: bool,
) {
    wire_summarize__method__FastqServices_impl(port_, that, mode, lowmem)
}

#[no_mangle]
pub extern "C" fn wire_new__static_method__ContigServices(port_: i64) {
    wire_new__static_method__ContigServices_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_summarize__method__ContigServices(
    port_: i64,
    that: *mut wire_ContigServices,
) {
    wire_summarize__method__ContigServices_impl(port_, that)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_StringList_0(len: i32) -> *mut wire_StringList {
    let wrap = wire_StringList {
        ptr: support::new_leak_vec_ptr(<*mut wire_uint_8_list>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_contig_services_0() -> *mut wire_ContigServices {
    support::new_leak_box_ptr(wire_ContigServices::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_fastq_services_0() -> *mut wire_FastqServices {
    support::new_leak_box_ptr(wire_FastqServices::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_sequence_services_0() -> *mut wire_SequenceServices {
    support::new_leak_box_ptr(wire_SequenceServices::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<Vec<String>> for *mut wire_StringList {
    fn wire2api(self) -> Vec<String> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}

impl Wire2Api<ContigServices> for *mut wire_ContigServices {
    fn wire2api(self) -> ContigServices {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<ContigServices>::wire2api(*wrap).into()
    }
}
impl Wire2Api<FastqServices> for *mut wire_FastqServices {
    fn wire2api(self) -> FastqServices {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<FastqServices>::wire2api(*wrap).into()
    }
}
impl Wire2Api<SequenceServices> for *mut wire_SequenceServices {
    fn wire2api(self) -> SequenceServices {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<SequenceServices>::wire2api(*wrap).into()
    }
}
impl Wire2Api<ContigServices> for wire_ContigServices {
    fn wire2api(self) -> ContigServices {
        ContigServices {
            dir_path: self.dir_path.wire2api(),
            files: self.files.wire2api(),
            file_fmt: self.file_fmt.wire2api(),
            output_dir: self.output_dir.wire2api(),
        }
    }
}
impl Wire2Api<FastqServices> for wire_FastqServices {
    fn wire2api(self) -> FastqServices {
        FastqServices {
            dir_path: self.dir_path.wire2api(),
            files: self.files.wire2api(),
            file_fmt: self.file_fmt.wire2api(),
            output_dir: self.output_dir.wire2api(),
        }
    }
}

impl Wire2Api<SequenceServices> for wire_SequenceServices {
    fn wire2api(self) -> SequenceServices {
        SequenceServices {
            dir_path: self.dir_path.wire2api(),
            files: self.files.wire2api(),
            file_fmt: self.file_fmt.wire2api(),
            datatype: self.datatype.wire2api(),
            output_dir: self.output_dir.wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_StringList {
    ptr: *mut *mut wire_uint_8_list,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ContigServices {
    dir_path: *mut wire_uint_8_list,
    files: *mut wire_StringList,
    file_fmt: *mut wire_uint_8_list,
    output_dir: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_FastqServices {
    dir_path: *mut wire_uint_8_list,
    files: *mut wire_StringList,
    file_fmt: *mut wire_uint_8_list,
    output_dir: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SequenceServices {
    dir_path: *mut wire_uint_8_list,
    files: *mut wire_StringList,
    file_fmt: *mut wire_uint_8_list,
    datatype: *mut wire_uint_8_list,
    output_dir: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_ContigServices {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            files: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_ContigServices {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_FastqServices {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            files: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_FastqServices {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_SequenceServices {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            files: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output_dir: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_SequenceServices {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
