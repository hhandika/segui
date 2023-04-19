use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_show_dna_uppercase(port_: i64) {
    wire_show_dna_uppercase_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_new__static_method__SegulApi(port_: i64) {
    wire_new__static_method__SegulApi_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_concat_alignment__method__SegulApi(
    port_: i64,
    that: *mut wire_SegulApi,
    output_fmt: *mut wire_uint_8_list,
    partition_fmt: *mut wire_uint_8_list,
) {
    wire_concat_alignment__method__SegulApi_impl(port_, that, output_fmt, partition_fmt)
}

#[no_mangle]
pub extern "C" fn wire_convert_sequence__method__SegulApi(
    port_: i64,
    that: *mut wire_SegulApi,
    output_fmt: *mut wire_uint_8_list,
    sort: bool,
) {
    wire_convert_sequence__method__SegulApi_impl(port_, that, output_fmt, sort)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_segul_api_0() -> *mut wire_SegulApi {
    support::new_leak_box_ptr(wire_SegulApi::new_with_null_ptr())
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

impl Wire2Api<SegulApi> for *mut wire_SegulApi {
    fn wire2api(self) -> SegulApi {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<SegulApi>::wire2api(*wrap).into()
    }
}
impl Wire2Api<SegulApi> for wire_SegulApi {
    fn wire2api(self) -> SegulApi {
        SegulApi {
            dir_path: self.dir_path.wire2api(),
            file_fmt: self.file_fmt.wire2api(),
            datatype: self.datatype.wire2api(),
            output: self.output.wire2api(),
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
pub struct wire_SegulApi {
    dir_path: *mut wire_uint_8_list,
    file_fmt: *mut wire_uint_8_list,
    datatype: *mut wire_uint_8_list,
    output: *mut wire_uint_8_list,
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

impl NewWithNullPtr for wire_SegulApi {
    fn new_with_null_ptr() -> Self {
        Self {
            dir_path: core::ptr::null_mut(),
            file_fmt: core::ptr::null_mut(),
            datatype: core::ptr::null_mut(),
            output: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_SegulApi {
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
