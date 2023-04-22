// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.74.0.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';

import 'dart:ffi' as ffi;

abstract class SegulApi {
  Future<String> showDnaUppercase({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kShowDnaUppercaseConstMeta;

  Future<SegulServices> newStaticMethodSegulServices({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kNewStaticMethodSegulServicesConstMeta;

  Future<void> concatAlignmentMethodSegulServices(
      {required SegulServices that,
      required String outFname,
      required String outFmtStr,
      required String partitionFmt,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta
      get kConcatAlignmentMethodSegulServicesConstMeta;

  Future<void> convertSequenceMethodSegulServices(
      {required SegulServices that,
      required String outputFmt,
      required bool sort,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta
      get kConvertSequenceMethodSegulServicesConstMeta;

  Future<void> summarizeAlignmentMethodSegulServices(
      {required SegulServices that,
      required String outputPrefix,
      required int interval,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta
      get kSummarizeAlignmentMethodSegulServicesConstMeta;

  Future<void> translateSequenceMethodSegulServices(
      {required SegulServices that,
      required int table,
      required int readingFrame,
      required String outputFmt,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta
      get kTranslateSequenceMethodSegulServicesConstMeta;
}

class SegulServices {
  final SegulApi bridge;
  final String? dirPath;
  final List<String> files;
  final String fileFmt;
  final String datatype;
  final String outputDir;

  const SegulServices({
    required this.bridge,
    this.dirPath,
    required this.files,
    required this.fileFmt,
    required this.datatype,
    required this.outputDir,
  });

  static Future<SegulServices> newSegulServices(
          {required SegulApi bridge, dynamic hint}) =>
      bridge.newStaticMethodSegulServices(hint: hint);

  Future<void> concatAlignment(
          {required String outFname,
          required String outFmtStr,
          required String partitionFmt,
          dynamic hint}) =>
      bridge.concatAlignmentMethodSegulServices(
        that: this,
        outFname: outFname,
        outFmtStr: outFmtStr,
        partitionFmt: partitionFmt,
      );

  Future<void> convertSequence(
          {required String outputFmt, required bool sort, dynamic hint}) =>
      bridge.convertSequenceMethodSegulServices(
        that: this,
        outputFmt: outputFmt,
        sort: sort,
      );

  Future<void> summarizeAlignment(
          {required String outputPrefix,
          required int interval,
          dynamic hint}) =>
      bridge.summarizeAlignmentMethodSegulServices(
        that: this,
        outputPrefix: outputPrefix,
        interval: interval,
      );

  Future<void> translateSequence(
          {required int table,
          required int readingFrame,
          required String outputFmt,
          dynamic hint}) =>
      bridge.translateSequenceMethodSegulServices(
        that: this,
        table: table,
        readingFrame: readingFrame,
        outputFmt: outputFmt,
      );
}

class SegulApiImpl implements SegulApi {
  final SegulApiPlatform _platform;
  factory SegulApiImpl(ExternalLibrary dylib) =>
      SegulApiImpl.raw(SegulApiPlatform(dylib));

  /// Only valid on web/WASM platforms.
  factory SegulApiImpl.wasm(FutureOr<WasmModule> module) =>
      SegulApiImpl(module as ExternalLibrary);
  SegulApiImpl.raw(this._platform);
  Future<String> showDnaUppercase({dynamic hint}) {
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_show_dna_uppercase(port_),
      parseSuccessData: _wire2api_String,
      constMeta: kShowDnaUppercaseConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kShowDnaUppercaseConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "show_dna_uppercase",
        argNames: [],
      );

  Future<SegulServices> newStaticMethodSegulServices({dynamic hint}) {
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) =>
          _platform.inner.wire_new__static_method__SegulServices(port_),
      parseSuccessData: (d) => _wire2api_segul_services(d),
      constMeta: kNewStaticMethodSegulServicesConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kNewStaticMethodSegulServicesConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "new__static_method__SegulServices",
        argNames: [],
      );

  Future<void> concatAlignmentMethodSegulServices(
      {required SegulServices that,
      required String outFname,
      required String outFmtStr,
      required String partitionFmt,
      dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_segul_services(that);
    var arg1 = _platform.api2wire_String(outFname);
    var arg2 = _platform.api2wire_String(outFmtStr);
    var arg3 = _platform.api2wire_String(partitionFmt);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner
          .wire_concat_alignment__method__SegulServices(
              port_, arg0, arg1, arg2, arg3),
      parseSuccessData: _wire2api_unit,
      constMeta: kConcatAlignmentMethodSegulServicesConstMeta,
      argValues: [that, outFname, outFmtStr, partitionFmt],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta
      get kConcatAlignmentMethodSegulServicesConstMeta =>
          const FlutterRustBridgeTaskConstMeta(
            debugName: "concat_alignment__method__SegulServices",
            argNames: ["that", "outFname", "outFmtStr", "partitionFmt"],
          );

  Future<void> convertSequenceMethodSegulServices(
      {required SegulServices that,
      required String outputFmt,
      required bool sort,
      dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_segul_services(that);
    var arg1 = _platform.api2wire_String(outputFmt);
    var arg2 = sort;
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner
          .wire_convert_sequence__method__SegulServices(
              port_, arg0, arg1, arg2),
      parseSuccessData: _wire2api_unit,
      constMeta: kConvertSequenceMethodSegulServicesConstMeta,
      argValues: [that, outputFmt, sort],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta
      get kConvertSequenceMethodSegulServicesConstMeta =>
          const FlutterRustBridgeTaskConstMeta(
            debugName: "convert_sequence__method__SegulServices",
            argNames: ["that", "outputFmt", "sort"],
          );

  Future<void> summarizeAlignmentMethodSegulServices(
      {required SegulServices that,
      required String outputPrefix,
      required int interval,
      dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_segul_services(that);
    var arg1 = _platform.api2wire_String(outputPrefix);
    var arg2 = api2wire_usize(interval);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner
          .wire_summarize_alignment__method__SegulServices(
              port_, arg0, arg1, arg2),
      parseSuccessData: _wire2api_unit,
      constMeta: kSummarizeAlignmentMethodSegulServicesConstMeta,
      argValues: [that, outputPrefix, interval],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta
      get kSummarizeAlignmentMethodSegulServicesConstMeta =>
          const FlutterRustBridgeTaskConstMeta(
            debugName: "summarize_alignment__method__SegulServices",
            argNames: ["that", "outputPrefix", "interval"],
          );

  Future<void> translateSequenceMethodSegulServices(
      {required SegulServices that,
      required int table,
      required int readingFrame,
      required String outputFmt,
      dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_segul_services(that);
    var arg1 = api2wire_usize(table);
    var arg2 = api2wire_usize(readingFrame);
    var arg3 = _platform.api2wire_String(outputFmt);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner
          .wire_translate_sequence__method__SegulServices(
              port_, arg0, arg1, arg2, arg3),
      parseSuccessData: _wire2api_unit,
      constMeta: kTranslateSequenceMethodSegulServicesConstMeta,
      argValues: [that, table, readingFrame, outputFmt],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta
      get kTranslateSequenceMethodSegulServicesConstMeta =>
          const FlutterRustBridgeTaskConstMeta(
            debugName: "translate_sequence__method__SegulServices",
            argNames: ["that", "table", "readingFrame", "outputFmt"],
          );

  void dispose() {
    _platform.dispose();
  }
// Section: wire2api

  String _wire2api_String(dynamic raw) {
    return raw as String;
  }

  List<String> _wire2api_StringList(dynamic raw) {
    return (raw as List<dynamic>).cast<String>();
  }

  String? _wire2api_opt_String(dynamic raw) {
    return raw == null ? null : _wire2api_String(raw);
  }

  SegulServices _wire2api_segul_services(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 5)
      throw Exception('unexpected arr length: expect 5 but see ${arr.length}');
    return SegulServices(
      bridge: this,
      dirPath: _wire2api_opt_String(arr[0]),
      files: _wire2api_StringList(arr[1]),
      fileFmt: _wire2api_String(arr[2]),
      datatype: _wire2api_String(arr[3]),
      outputDir: _wire2api_String(arr[4]),
    );
  }

  int _wire2api_u8(dynamic raw) {
    return raw as int;
  }

  Uint8List _wire2api_uint_8_list(dynamic raw) {
    return raw as Uint8List;
  }

  void _wire2api_unit(dynamic raw) {
    return;
  }
}

// Section: api2wire

@protected
bool api2wire_bool(bool raw) {
  return raw;
}

@protected
int api2wire_u8(int raw) {
  return raw;
}

@protected
int api2wire_usize(int raw) {
  return raw;
}
// Section: finalizer

class SegulApiPlatform extends FlutterRustBridgeBase<SegulApiWire> {
  SegulApiPlatform(ffi.DynamicLibrary dylib) : super(SegulApiWire(dylib));

// Section: api2wire

  @protected
  ffi.Pointer<wire_uint_8_list> api2wire_String(String raw) {
    return api2wire_uint_8_list(utf8.encoder.convert(raw));
  }

  @protected
  ffi.Pointer<wire_StringList> api2wire_StringList(List<String> raw) {
    final ans = inner.new_StringList_0(raw.length);
    for (var i = 0; i < raw.length; i++) {
      ans.ref.ptr[i] = api2wire_String(raw[i]);
    }
    return ans;
  }

  @protected
  ffi.Pointer<wire_SegulServices> api2wire_box_autoadd_segul_services(
      SegulServices raw) {
    final ptr = inner.new_box_autoadd_segul_services_0();
    _api_fill_to_wire_segul_services(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_uint_8_list> api2wire_opt_String(String? raw) {
    return raw == null ? ffi.nullptr : api2wire_String(raw);
  }

  @protected
  ffi.Pointer<wire_uint_8_list> api2wire_uint_8_list(Uint8List raw) {
    final ans = inner.new_uint_8_list_0(raw.length);
    ans.ref.ptr.asTypedList(raw.length).setAll(0, raw);
    return ans;
  }

// Section: finalizer

// Section: api_fill_to_wire

  void _api_fill_to_wire_box_autoadd_segul_services(
      SegulServices apiObj, ffi.Pointer<wire_SegulServices> wireObj) {
    _api_fill_to_wire_segul_services(apiObj, wireObj.ref);
  }

  void _api_fill_to_wire_segul_services(
      SegulServices apiObj, wire_SegulServices wireObj) {
    wireObj.dir_path = api2wire_opt_String(apiObj.dirPath);
    wireObj.files = api2wire_StringList(apiObj.files);
    wireObj.file_fmt = api2wire_String(apiObj.fileFmt);
    wireObj.datatype = api2wire_String(apiObj.datatype);
    wireObj.output_dir = api2wire_String(apiObj.outputDir);
  }
}

// ignore_for_file: camel_case_types, non_constant_identifier_names, avoid_positional_boolean_parameters, annotate_overrides, constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint

/// generated by flutter_rust_bridge
class SegulApiWire implements FlutterRustBridgeWireBase {
  @internal
  late final dartApi = DartApiDl(init_frb_dart_api_dl);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  SegulApiWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  SegulApiWire.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void store_dart_post_cobject(
    DartPostCObjectFnType ptr,
  ) {
    return _store_dart_post_cobject(
      ptr,
    );
  }

  late final _store_dart_post_cobjectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(DartPostCObjectFnType)>>(
          'store_dart_post_cobject');
  late final _store_dart_post_cobject = _store_dart_post_cobjectPtr
      .asFunction<void Function(DartPostCObjectFnType)>();

  Object get_dart_object(
    int ptr,
  ) {
    return _get_dart_object(
      ptr,
    );
  }

  late final _get_dart_objectPtr =
      _lookup<ffi.NativeFunction<ffi.Handle Function(ffi.UintPtr)>>(
          'get_dart_object');
  late final _get_dart_object =
      _get_dart_objectPtr.asFunction<Object Function(int)>();

  void drop_dart_object(
    int ptr,
  ) {
    return _drop_dart_object(
      ptr,
    );
  }

  late final _drop_dart_objectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.UintPtr)>>(
          'drop_dart_object');
  late final _drop_dart_object =
      _drop_dart_objectPtr.asFunction<void Function(int)>();

  int new_dart_opaque(
    Object handle,
  ) {
    return _new_dart_opaque(
      handle,
    );
  }

  late final _new_dart_opaquePtr =
      _lookup<ffi.NativeFunction<ffi.UintPtr Function(ffi.Handle)>>(
          'new_dart_opaque');
  late final _new_dart_opaque =
      _new_dart_opaquePtr.asFunction<int Function(Object)>();

  int init_frb_dart_api_dl(
    ffi.Pointer<ffi.Void> obj,
  ) {
    return _init_frb_dart_api_dl(
      obj,
    );
  }

  late final _init_frb_dart_api_dlPtr =
      _lookup<ffi.NativeFunction<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>>(
          'init_frb_dart_api_dl');
  late final _init_frb_dart_api_dl = _init_frb_dart_api_dlPtr
      .asFunction<int Function(ffi.Pointer<ffi.Void>)>();

  void wire_show_dna_uppercase(
    int port_,
  ) {
    return _wire_show_dna_uppercase(
      port_,
    );
  }

  late final _wire_show_dna_uppercasePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_show_dna_uppercase');
  late final _wire_show_dna_uppercase =
      _wire_show_dna_uppercasePtr.asFunction<void Function(int)>();

  void wire_new__static_method__SegulServices(
    int port_,
  ) {
    return _wire_new__static_method__SegulServices(
      port_,
    );
  }

  late final _wire_new__static_method__SegulServicesPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_new__static_method__SegulServices');
  late final _wire_new__static_method__SegulServices =
      _wire_new__static_method__SegulServicesPtr
          .asFunction<void Function(int)>();

  void wire_concat_alignment__method__SegulServices(
    int port_,
    ffi.Pointer<wire_SegulServices> that,
    ffi.Pointer<wire_uint_8_list> out_fname,
    ffi.Pointer<wire_uint_8_list> out_fmt_str,
    ffi.Pointer<wire_uint_8_list> partition_fmt,
  ) {
    return _wire_concat_alignment__method__SegulServices(
      port_,
      that,
      out_fname,
      out_fmt_str,
      partition_fmt,
    );
  }

  late final _wire_concat_alignment__method__SegulServicesPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Int64,
                  ffi.Pointer<wire_SegulServices>,
                  ffi.Pointer<wire_uint_8_list>,
                  ffi.Pointer<wire_uint_8_list>,
                  ffi.Pointer<wire_uint_8_list>)>>(
      'wire_concat_alignment__method__SegulServices');
  late final _wire_concat_alignment__method__SegulServices =
      _wire_concat_alignment__method__SegulServicesPtr.asFunction<
          void Function(
              int,
              ffi.Pointer<wire_SegulServices>,
              ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_uint_8_list>)>();

  void wire_convert_sequence__method__SegulServices(
    int port_,
    ffi.Pointer<wire_SegulServices> that,
    ffi.Pointer<wire_uint_8_list> output_fmt,
    bool sort,
  ) {
    return _wire_convert_sequence__method__SegulServices(
      port_,
      that,
      output_fmt,
      sort,
    );
  }

  late final _wire_convert_sequence__method__SegulServicesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_SegulServices>,
              ffi.Pointer<wire_uint_8_list>,
              ffi.Bool)>>('wire_convert_sequence__method__SegulServices');
  late final _wire_convert_sequence__method__SegulServices =
      _wire_convert_sequence__method__SegulServicesPtr.asFunction<
          void Function(int, ffi.Pointer<wire_SegulServices>,
              ffi.Pointer<wire_uint_8_list>, bool)>();

  void wire_summarize_alignment__method__SegulServices(
    int port_,
    ffi.Pointer<wire_SegulServices> that,
    ffi.Pointer<wire_uint_8_list> output_prefix,
    int interval,
  ) {
    return _wire_summarize_alignment__method__SegulServices(
      port_,
      that,
      output_prefix,
      interval,
    );
  }

  late final _wire_summarize_alignment__method__SegulServicesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_SegulServices>,
              ffi.Pointer<wire_uint_8_list>,
              ffi.UintPtr)>>('wire_summarize_alignment__method__SegulServices');
  late final _wire_summarize_alignment__method__SegulServices =
      _wire_summarize_alignment__method__SegulServicesPtr.asFunction<
          void Function(int, ffi.Pointer<wire_SegulServices>,
              ffi.Pointer<wire_uint_8_list>, int)>();

  void wire_translate_sequence__method__SegulServices(
    int port_,
    ffi.Pointer<wire_SegulServices> that,
    int table,
    int reading_frame,
    ffi.Pointer<wire_uint_8_list> output_fmt,
  ) {
    return _wire_translate_sequence__method__SegulServices(
      port_,
      that,
      table,
      reading_frame,
      output_fmt,
    );
  }

  late final _wire_translate_sequence__method__SegulServicesPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Int64, ffi.Pointer<wire_SegulServices>,
                  ffi.UintPtr, ffi.UintPtr, ffi.Pointer<wire_uint_8_list>)>>(
      'wire_translate_sequence__method__SegulServices');
  late final _wire_translate_sequence__method__SegulServices =
      _wire_translate_sequence__method__SegulServicesPtr.asFunction<
          void Function(int, ffi.Pointer<wire_SegulServices>, int, int,
              ffi.Pointer<wire_uint_8_list>)>();

  ffi.Pointer<wire_StringList> new_StringList_0(
    int len,
  ) {
    return _new_StringList_0(
      len,
    );
  }

  late final _new_StringList_0Ptr = _lookup<
          ffi.NativeFunction<ffi.Pointer<wire_StringList> Function(ffi.Int32)>>(
      'new_StringList_0');
  late final _new_StringList_0 = _new_StringList_0Ptr
      .asFunction<ffi.Pointer<wire_StringList> Function(int)>();

  ffi.Pointer<wire_SegulServices> new_box_autoadd_segul_services_0() {
    return _new_box_autoadd_segul_services_0();
  }

  late final _new_box_autoadd_segul_services_0Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_SegulServices> Function()>>(
          'new_box_autoadd_segul_services_0');
  late final _new_box_autoadd_segul_services_0 =
      _new_box_autoadd_segul_services_0Ptr
          .asFunction<ffi.Pointer<wire_SegulServices> Function()>();

  ffi.Pointer<wire_uint_8_list> new_uint_8_list_0(
    int len,
  ) {
    return _new_uint_8_list_0(
      len,
    );
  }

  late final _new_uint_8_list_0Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<wire_uint_8_list> Function(
              ffi.Int32)>>('new_uint_8_list_0');
  late final _new_uint_8_list_0 = _new_uint_8_list_0Ptr
      .asFunction<ffi.Pointer<wire_uint_8_list> Function(int)>();

  void free_WireSyncReturn(
    WireSyncReturn ptr,
  ) {
    return _free_WireSyncReturn(
      ptr,
    );
  }

  late final _free_WireSyncReturnPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(WireSyncReturn)>>(
          'free_WireSyncReturn');
  late final _free_WireSyncReturn =
      _free_WireSyncReturnPtr.asFunction<void Function(WireSyncReturn)>();
}

class _Dart_Handle extends ffi.Opaque {}

class wire_uint_8_list extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Int32()
  external int len;
}

class wire_StringList extends ffi.Struct {
  external ffi.Pointer<ffi.Pointer<wire_uint_8_list>> ptr;

  @ffi.Int32()
  external int len;
}

class wire_SegulServices extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> dir_path;

  external ffi.Pointer<wire_StringList> files;

  external ffi.Pointer<wire_uint_8_list> file_fmt;

  external ffi.Pointer<wire_uint_8_list> datatype;

  external ffi.Pointer<wire_uint_8_list> output_dir;
}

typedef DartPostCObjectFnType = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Bool Function(DartPort port_id, ffi.Pointer<ffi.Void> message)>>;
typedef DartPort = ffi.Int64;
