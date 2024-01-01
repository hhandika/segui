// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.9.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables

import 'api/common.dart';
import 'api/contig.dart';
import 'api/fastq.dart';
import 'api/sequence.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  ContigServices dco_decode_box_autoadd_contig_services(dynamic raw);

  @protected
  FastqServices dco_decode_box_autoadd_fastq_services(dynamic raw);

  @protected
  PartitionServices dco_decode_box_autoadd_partition_services(dynamic raw);

  @protected
  SequenceServices dco_decode_box_autoadd_sequence_services(dynamic raw);

  @protected
  ContigServices dco_decode_contig_services(dynamic raw);

  @protected
  FastqServices dco_decode_fastq_services(dynamic raw);

  @protected
  List<String> dco_decode_list_String(dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  PartitionServices dco_decode_partition_services(dynamic raw);

  @protected
  SequenceServices dco_decode_sequence_services(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  int dco_decode_usize(dynamic raw);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  ContigServices sse_decode_box_autoadd_contig_services(
      SseDeserializer deserializer);

  @protected
  FastqServices sse_decode_box_autoadd_fastq_services(
      SseDeserializer deserializer);

  @protected
  PartitionServices sse_decode_box_autoadd_partition_services(
      SseDeserializer deserializer);

  @protected
  SequenceServices sse_decode_box_autoadd_sequence_services(
      SseDeserializer deserializer);

  @protected
  ContigServices sse_decode_contig_services(SseDeserializer deserializer);

  @protected
  FastqServices sse_decode_fastq_services(SseDeserializer deserializer);

  @protected
  List<String> sse_decode_list_String(SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  PartitionServices sse_decode_partition_services(SseDeserializer deserializer);

  @protected
  SequenceServices sse_decode_sequence_services(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  int sse_decode_usize(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  ffi.Pointer<wire_cst_list_prim_u_8> cst_encode_String(String raw) {
    return cst_encode_list_prim_u_8(utf8.encoder.convert(raw));
  }

  @protected
  ffi.Pointer<wire_cst_contig_services> cst_encode_box_autoadd_contig_services(
      ContigServices raw) {
    final ptr = wire.cst_new_box_autoadd_contig_services();
    cst_api_fill_to_wire_contig_services(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_cst_fastq_services> cst_encode_box_autoadd_fastq_services(
      FastqServices raw) {
    final ptr = wire.cst_new_box_autoadd_fastq_services();
    cst_api_fill_to_wire_fastq_services(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_cst_partition_services>
      cst_encode_box_autoadd_partition_services(PartitionServices raw) {
    final ptr = wire.cst_new_box_autoadd_partition_services();
    cst_api_fill_to_wire_partition_services(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_cst_sequence_services>
      cst_encode_box_autoadd_sequence_services(SequenceServices raw) {
    final ptr = wire.cst_new_box_autoadd_sequence_services();
    cst_api_fill_to_wire_sequence_services(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_cst_list_String> cst_encode_list_String(List<String> raw) {
    final ans = wire.cst_new_list_String(raw.length);
    for (var i = 0; i < raw.length; ++i) {
      ans.ref.ptr[i] = cst_encode_String(raw[i]);
    }
    return ans;
  }

  @protected
  ffi.Pointer<wire_cst_list_prim_u_8> cst_encode_list_prim_u_8(Uint8List raw) {
    final ans = wire.cst_new_list_prim_u_8(raw.length);
    ans.ref.ptr.asTypedList(raw.length).setAll(0, raw);
    return ans;
  }

  @protected
  ffi.Pointer<wire_cst_list_prim_u_8> cst_encode_opt_String(String? raw) {
    return raw == null ? ffi.nullptr : cst_encode_String(raw);
  }

  @protected
  void cst_api_fill_to_wire_box_autoadd_contig_services(
      ContigServices apiObj, ffi.Pointer<wire_cst_contig_services> wireObj) {
    cst_api_fill_to_wire_contig_services(apiObj, wireObj.ref);
  }

  @protected
  void cst_api_fill_to_wire_box_autoadd_fastq_services(
      FastqServices apiObj, ffi.Pointer<wire_cst_fastq_services> wireObj) {
    cst_api_fill_to_wire_fastq_services(apiObj, wireObj.ref);
  }

  @protected
  void cst_api_fill_to_wire_box_autoadd_partition_services(
      PartitionServices apiObj,
      ffi.Pointer<wire_cst_partition_services> wireObj) {
    cst_api_fill_to_wire_partition_services(apiObj, wireObj.ref);
  }

  @protected
  void cst_api_fill_to_wire_box_autoadd_sequence_services(
      SequenceServices apiObj,
      ffi.Pointer<wire_cst_sequence_services> wireObj) {
    cst_api_fill_to_wire_sequence_services(apiObj, wireObj.ref);
  }

  @protected
  void cst_api_fill_to_wire_contig_services(
      ContigServices apiObj, wire_cst_contig_services wireObj) {
    wireObj.dir_path = cst_encode_opt_String(apiObj.dirPath);
    wireObj.files = cst_encode_list_String(apiObj.files);
    wireObj.file_fmt = cst_encode_String(apiObj.fileFmt);
    wireObj.output_dir = cst_encode_String(apiObj.outputDir);
  }

  @protected
  void cst_api_fill_to_wire_fastq_services(
      FastqServices apiObj, wire_cst_fastq_services wireObj) {
    wireObj.dir_path = cst_encode_opt_String(apiObj.dirPath);
    wireObj.files = cst_encode_list_String(apiObj.files);
    wireObj.file_fmt = cst_encode_String(apiObj.fileFmt);
    wireObj.output_dir = cst_encode_String(apiObj.outputDir);
  }

  @protected
  void cst_api_fill_to_wire_partition_services(
      PartitionServices apiObj, wire_cst_partition_services wireObj) {
    wireObj.file_inputs = cst_encode_list_String(apiObj.fileInputs);
    wireObj.input_part_fmt = cst_encode_String(apiObj.inputPartFmt);
    wireObj.output = cst_encode_String(apiObj.output);
    wireObj.output_part_fmt = cst_encode_String(apiObj.outputPartFmt);
    wireObj.datatype = cst_encode_String(apiObj.datatype);
    wireObj.is_uncheck = cst_encode_bool(apiObj.isUncheck);
  }

  @protected
  void cst_api_fill_to_wire_sequence_services(
      SequenceServices apiObj, wire_cst_sequence_services wireObj) {
    wireObj.dir_path = cst_encode_opt_String(apiObj.dirPath);
    wireObj.files = cst_encode_list_String(apiObj.files);
    wireObj.file_fmt = cst_encode_String(apiObj.fileFmt);
    wireObj.datatype = cst_encode_String(apiObj.datatype);
    wireObj.output_dir = cst_encode_String(apiObj.outputDir);
  }

  @protected
  bool cst_encode_bool(bool raw);

  @protected
  int cst_encode_u_8(int raw);

  @protected
  void cst_encode_unit(void raw);

  @protected
  int cst_encode_usize(int raw);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_contig_services(
      ContigServices self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_fastq_services(
      FastqServices self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_partition_services(
      PartitionServices self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_sequence_services(
      SequenceServices self, SseSerializer serializer);

  @protected
  void sse_encode_contig_services(
      ContigServices self, SseSerializer serializer);

  @protected
  void sse_encode_fastq_services(FastqServices self, SseSerializer serializer);

  @protected
  void sse_encode_list_String(List<String> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8(Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void sse_encode_partition_services(
      PartitionServices self, SseSerializer serializer);

  @protected
  void sse_encode_sequence_services(
      SequenceServices self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);

  @protected
  void sse_encode_usize(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);
}

// Section: wire_class

// ignore_for_file: camel_case_types, non_constant_identifier_names, avoid_positional_boolean_parameters, annotate_overrides, constant_identifier_names
// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint

/// generated by flutter_rust_bridge
class RustLibWire implements BaseWire {
  factory RustLibWire.fromExternalLibrary(ExternalLibrary lib) =>
      RustLibWire(lib.ffiDynamicLibrary);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  RustLibWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  RustLibWire.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void dart_fn_deliver_output(
    int call_id,
    ffi.Pointer<ffi.Uint8> ptr_,
    int rust_vec_len_,
    int data_len_,
  ) {
    return _dart_fn_deliver_output(
      call_id,
      ptr_,
      rust_vec_len_,
      data_len_,
    );
  }

  late final _dart_fn_deliver_outputPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int32, ffi.Pointer<ffi.Uint8>, ffi.Int32,
              ffi.Int32)>>('dart_fn_deliver_output');
  late final _dart_fn_deliver_output = _dart_fn_deliver_outputPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Uint8>, int, int)>();

  WireSyncRust2DartDco wire_init_logger(
    ffi.Pointer<wire_cst_list_prim_u_8> path,
  ) {
    return _wire_init_logger(
      path,
    );
  }

  late final _wire_init_loggerPtr = _lookup<
      ffi.NativeFunction<
          WireSyncRust2DartDco Function(
              ffi.Pointer<wire_cst_list_prim_u_8>)>>('wire_init_logger');
  late final _wire_init_logger = _wire_init_loggerPtr.asFunction<
      WireSyncRust2DartDco Function(ffi.Pointer<wire_cst_list_prim_u_8>)>();

  void wire_ContigServices_new(
    int port_,
  ) {
    return _wire_ContigServices_new(
      port_,
    );
  }

  late final _wire_ContigServices_newPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_ContigServices_new');
  late final _wire_ContigServices_new =
      _wire_ContigServices_newPtr.asFunction<void Function(int)>();

  void wire_ContigServices_summarize(
    int port_,
    ffi.Pointer<wire_cst_contig_services> that,
  ) {
    return _wire_ContigServices_summarize(
      port_,
      that,
    );
  }

  late final _wire_ContigServices_summarizePtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Int64, ffi.Pointer<wire_cst_contig_services>)>>(
      'wire_ContigServices_summarize');
  late final _wire_ContigServices_summarize = _wire_ContigServices_summarizePtr
      .asFunction<void Function(int, ffi.Pointer<wire_cst_contig_services>)>();

  void wire_FastqServices_new(
    int port_,
  ) {
    return _wire_FastqServices_new(
      port_,
    );
  }

  late final _wire_FastqServices_newPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_FastqServices_new');
  late final _wire_FastqServices_new =
      _wire_FastqServices_newPtr.asFunction<void Function(int)>();

  void wire_FastqServices_summarize(
    int port_,
    ffi.Pointer<wire_cst_fastq_services> that,
    ffi.Pointer<wire_cst_list_prim_u_8> mode,
  ) {
    return _wire_FastqServices_summarize(
      port_,
      that,
      mode,
    );
  }

  late final _wire_FastqServices_summarizePtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Int64, ffi.Pointer<wire_cst_fastq_services>,
                  ffi.Pointer<wire_cst_list_prim_u_8>)>>(
      'wire_FastqServices_summarize');
  late final _wire_FastqServices_summarize =
      _wire_FastqServices_summarizePtr.asFunction<
          void Function(int, ffi.Pointer<wire_cst_fastq_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>)>();

  void wire_PartitionServices_convert_partition(
    int port_,
    ffi.Pointer<wire_cst_partition_services> that,
  ) {
    return _wire_PartitionServices_convert_partition(
      port_,
      that,
    );
  }

  late final _wire_PartitionServices_convert_partitionPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Int64, ffi.Pointer<wire_cst_partition_services>)>>(
      'wire_PartitionServices_convert_partition');
  late final _wire_PartitionServices_convert_partition =
      _wire_PartitionServices_convert_partitionPtr.asFunction<
          void Function(int, ffi.Pointer<wire_cst_partition_services>)>();

  void wire_PartitionServices_new(
    int port_,
  ) {
    return _wire_PartitionServices_new(
      port_,
    );
  }

  late final _wire_PartitionServices_newPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_PartitionServices_new');
  late final _wire_PartitionServices_new =
      _wire_PartitionServices_newPtr.asFunction<void Function(int)>();

  void wire_SequenceServices_concat_alignment(
    int port_,
    ffi.Pointer<wire_cst_sequence_services> that,
    ffi.Pointer<wire_cst_list_prim_u_8> out_fname,
    ffi.Pointer<wire_cst_list_prim_u_8> out_fmt_str,
    ffi.Pointer<wire_cst_list_prim_u_8> partition_fmt,
  ) {
    return _wire_SequenceServices_concat_alignment(
      port_,
      that,
      out_fname,
      out_fmt_str,
      partition_fmt,
    );
  }

  late final _wire_SequenceServices_concat_alignmentPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Int64,
                  ffi.Pointer<wire_cst_sequence_services>,
                  ffi.Pointer<wire_cst_list_prim_u_8>,
                  ffi.Pointer<wire_cst_list_prim_u_8>,
                  ffi.Pointer<wire_cst_list_prim_u_8>)>>(
      'wire_SequenceServices_concat_alignment');
  late final _wire_SequenceServices_concat_alignment =
      _wire_SequenceServices_concat_alignmentPtr.asFunction<
          void Function(
              int,
              ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>,
              ffi.Pointer<wire_cst_list_prim_u_8>,
              ffi.Pointer<wire_cst_list_prim_u_8>)>();

  void wire_SequenceServices_convert_sequence(
    int port_,
    ffi.Pointer<wire_cst_sequence_services> that,
    ffi.Pointer<wire_cst_list_prim_u_8> output_fmt,
    bool sort,
  ) {
    return _wire_SequenceServices_convert_sequence(
      port_,
      that,
      output_fmt,
      sort,
    );
  }

  late final _wire_SequenceServices_convert_sequencePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>,
              ffi.Bool)>>('wire_SequenceServices_convert_sequence');
  late final _wire_SequenceServices_convert_sequence =
      _wire_SequenceServices_convert_sequencePtr.asFunction<
          void Function(int, ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>, bool)>();

  void wire_SequenceServices_new(
    int port_,
  ) {
    return _wire_SequenceServices_new(
      port_,
    );
  }

  late final _wire_SequenceServices_newPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_SequenceServices_new');
  late final _wire_SequenceServices_new =
      _wire_SequenceServices_newPtr.asFunction<void Function(int)>();

  void wire_SequenceServices_parse_sequence_id(
    int port_,
    ffi.Pointer<wire_cst_sequence_services> that,
    bool is_map,
  ) {
    return _wire_SequenceServices_parse_sequence_id(
      port_,
      that,
      is_map,
    );
  }

  late final _wire_SequenceServices_parse_sequence_idPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_cst_sequence_services>,
              ffi.Bool)>>('wire_SequenceServices_parse_sequence_id');
  late final _wire_SequenceServices_parse_sequence_id =
      _wire_SequenceServices_parse_sequence_idPtr.asFunction<
          void Function(int, ffi.Pointer<wire_cst_sequence_services>, bool)>();

  void wire_SequenceServices_summarize_alignment(
    int port_,
    ffi.Pointer<wire_cst_sequence_services> that,
    ffi.Pointer<wire_cst_list_prim_u_8> output_prefix,
    int interval,
  ) {
    return _wire_SequenceServices_summarize_alignment(
      port_,
      that,
      output_prefix,
      interval,
    );
  }

  late final _wire_SequenceServices_summarize_alignmentPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>,
              ffi.UintPtr)>>('wire_SequenceServices_summarize_alignment');
  late final _wire_SequenceServices_summarize_alignment =
      _wire_SequenceServices_summarize_alignmentPtr.asFunction<
          void Function(int, ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>, int)>();

  void wire_SequenceServices_translate_sequence(
    int port_,
    ffi.Pointer<wire_cst_sequence_services> that,
    ffi.Pointer<wire_cst_list_prim_u_8> table,
    int reading_frame,
    ffi.Pointer<wire_cst_list_prim_u_8> output_fmt,
  ) {
    return _wire_SequenceServices_translate_sequence(
      port_,
      that,
      table,
      reading_frame,
      output_fmt,
    );
  }

  late final _wire_SequenceServices_translate_sequencePtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Int64,
                  ffi.Pointer<wire_cst_sequence_services>,
                  ffi.Pointer<wire_cst_list_prim_u_8>,
                  ffi.UintPtr,
                  ffi.Pointer<wire_cst_list_prim_u_8>)>>(
      'wire_SequenceServices_translate_sequence');
  late final _wire_SequenceServices_translate_sequence =
      _wire_SequenceServices_translate_sequencePtr.asFunction<
          void Function(
              int,
              ffi.Pointer<wire_cst_sequence_services>,
              ffi.Pointer<wire_cst_list_prim_u_8>,
              int,
              ffi.Pointer<wire_cst_list_prim_u_8>)>();

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

  ffi.Pointer<wire_cst_contig_services> cst_new_box_autoadd_contig_services() {
    return _cst_new_box_autoadd_contig_services();
  }

  late final _cst_new_box_autoadd_contig_servicesPtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<wire_cst_contig_services> Function()>>(
      'cst_new_box_autoadd_contig_services');
  late final _cst_new_box_autoadd_contig_services =
      _cst_new_box_autoadd_contig_servicesPtr
          .asFunction<ffi.Pointer<wire_cst_contig_services> Function()>();

  ffi.Pointer<wire_cst_fastq_services> cst_new_box_autoadd_fastq_services() {
    return _cst_new_box_autoadd_fastq_services();
  }

  late final _cst_new_box_autoadd_fastq_servicesPtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<wire_cst_fastq_services> Function()>>(
      'cst_new_box_autoadd_fastq_services');
  late final _cst_new_box_autoadd_fastq_services =
      _cst_new_box_autoadd_fastq_servicesPtr
          .asFunction<ffi.Pointer<wire_cst_fastq_services> Function()>();

  ffi.Pointer<wire_cst_partition_services>
      cst_new_box_autoadd_partition_services() {
    return _cst_new_box_autoadd_partition_services();
  }

  late final _cst_new_box_autoadd_partition_servicesPtr = _lookup<
          ffi
          .NativeFunction<ffi.Pointer<wire_cst_partition_services> Function()>>(
      'cst_new_box_autoadd_partition_services');
  late final _cst_new_box_autoadd_partition_services =
      _cst_new_box_autoadd_partition_servicesPtr
          .asFunction<ffi.Pointer<wire_cst_partition_services> Function()>();

  ffi.Pointer<wire_cst_sequence_services>
      cst_new_box_autoadd_sequence_services() {
    return _cst_new_box_autoadd_sequence_services();
  }

  late final _cst_new_box_autoadd_sequence_servicesPtr = _lookup<
          ffi
          .NativeFunction<ffi.Pointer<wire_cst_sequence_services> Function()>>(
      'cst_new_box_autoadd_sequence_services');
  late final _cst_new_box_autoadd_sequence_services =
      _cst_new_box_autoadd_sequence_servicesPtr
          .asFunction<ffi.Pointer<wire_cst_sequence_services> Function()>();

  ffi.Pointer<wire_cst_list_String> cst_new_list_String(
    int len,
  ) {
    return _cst_new_list_String(
      len,
    );
  }

  late final _cst_new_list_StringPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<wire_cst_list_String> Function(
              ffi.Int32)>>('cst_new_list_String');
  late final _cst_new_list_String = _cst_new_list_StringPtr
      .asFunction<ffi.Pointer<wire_cst_list_String> Function(int)>();

  ffi.Pointer<wire_cst_list_prim_u_8> cst_new_list_prim_u_8(
    int len,
  ) {
    return _cst_new_list_prim_u_8(
      len,
    );
  }

  late final _cst_new_list_prim_u_8Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<wire_cst_list_prim_u_8> Function(
              ffi.Int32)>>('cst_new_list_prim_u_8');
  late final _cst_new_list_prim_u_8 = _cst_new_list_prim_u_8Ptr
      .asFunction<ffi.Pointer<wire_cst_list_prim_u_8> Function(int)>();

  int dummy_method_to_enforce_bundling() {
    return _dummy_method_to_enforce_bundling();
  }

  late final _dummy_method_to_enforce_bundlingPtr =
      _lookup<ffi.NativeFunction<ffi.Int64 Function()>>(
          'dummy_method_to_enforce_bundling');
  late final _dummy_method_to_enforce_bundling =
      _dummy_method_to_enforce_bundlingPtr.asFunction<int Function()>();
}

final class wire_cst_list_prim_u_8 extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Int32()
  external int len;
}

final class wire_cst_list_String extends ffi.Struct {
  external ffi.Pointer<ffi.Pointer<wire_cst_list_prim_u_8>> ptr;

  @ffi.Int32()
  external int len;
}

final class wire_cst_contig_services extends ffi.Struct {
  external ffi.Pointer<wire_cst_list_prim_u_8> dir_path;

  external ffi.Pointer<wire_cst_list_String> files;

  external ffi.Pointer<wire_cst_list_prim_u_8> file_fmt;

  external ffi.Pointer<wire_cst_list_prim_u_8> output_dir;
}

final class wire_cst_fastq_services extends ffi.Struct {
  external ffi.Pointer<wire_cst_list_prim_u_8> dir_path;

  external ffi.Pointer<wire_cst_list_String> files;

  external ffi.Pointer<wire_cst_list_prim_u_8> file_fmt;

  external ffi.Pointer<wire_cst_list_prim_u_8> output_dir;
}

final class wire_cst_partition_services extends ffi.Struct {
  external ffi.Pointer<wire_cst_list_String> file_inputs;

  external ffi.Pointer<wire_cst_list_prim_u_8> input_part_fmt;

  external ffi.Pointer<wire_cst_list_prim_u_8> output;

  external ffi.Pointer<wire_cst_list_prim_u_8> output_part_fmt;

  external ffi.Pointer<wire_cst_list_prim_u_8> datatype;

  @ffi.Bool()
  external bool is_uncheck;
}

final class wire_cst_sequence_services extends ffi.Struct {
  external ffi.Pointer<wire_cst_list_prim_u_8> dir_path;

  external ffi.Pointer<wire_cst_list_String> files;

  external ffi.Pointer<wire_cst_list_prim_u_8> file_fmt;

  external ffi.Pointer<wire_cst_list_prim_u_8> datatype;

  external ffi.Pointer<wire_cst_list_prim_u_8> output_dir;
}
