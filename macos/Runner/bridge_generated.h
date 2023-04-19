#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_SegulApi {
  struct wire_uint_8_list *dir_path;
  struct wire_uint_8_list *file_fmt;
  struct wire_uint_8_list *datatype;
  struct wire_uint_8_list *output;
} wire_SegulApi;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_show_dna_uppercase(int64_t port_);

void wire_new__static_method__SegulApi(int64_t port_);

void wire_concat_alignment__method__SegulApi(int64_t port_,
                                             struct wire_SegulApi *that,
                                             struct wire_uint_8_list *output_fmt,
                                             struct wire_uint_8_list *partition_fmt);

void wire_convert_sequence__method__SegulApi(int64_t port_,
                                             struct wire_SegulApi *that,
                                             struct wire_uint_8_list *output_fmt,
                                             bool sort);

struct wire_SegulApi *new_box_autoadd_segul_api_0(void);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_show_dna_uppercase);
    dummy_var ^= ((int64_t) (void*) wire_new__static_method__SegulApi);
    dummy_var ^= ((int64_t) (void*) wire_concat_alignment__method__SegulApi);
    dummy_var ^= ((int64_t) (void*) wire_convert_sequence__method__SegulApi);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_segul_api_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}
