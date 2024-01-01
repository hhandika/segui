// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.9.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables

import 'api/common.dart';
import 'api/contig.dart';
import 'api/fastq.dart';
import 'api/sequence.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart';

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
  String cst_encode_String(String raw) {
    return raw;
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_contig_services(ContigServices raw) {
    return cst_encode_contig_services(raw);
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_fastq_services(FastqServices raw) {
    return cst_encode_fastq_services(raw);
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_partition_services(
      PartitionServices raw) {
    return cst_encode_partition_services(raw);
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_sequence_services(SequenceServices raw) {
    return cst_encode_sequence_services(raw);
  }

  @protected
  List<dynamic> cst_encode_contig_services(ContigServices raw) {
    return [
      cst_encode_opt_String(raw.dirPath),
      cst_encode_list_String(raw.files),
      cst_encode_String(raw.fileFmt),
      cst_encode_String(raw.outputDir)
    ];
  }

  @protected
  List<dynamic> cst_encode_fastq_services(FastqServices raw) {
    return [
      cst_encode_opt_String(raw.dirPath),
      cst_encode_list_String(raw.files),
      cst_encode_String(raw.fileFmt),
      cst_encode_String(raw.outputDir)
    ];
  }

  @protected
  List<dynamic> cst_encode_list_String(List<String> raw) {
    return raw.map(cst_encode_String).toList();
  }

  @protected
  Uint8List cst_encode_list_prim_u_8(Uint8List raw) {
    return raw;
  }

  @protected
  String? cst_encode_opt_String(String? raw) {
    return raw == null ? null : cst_encode_String(raw);
  }

  @protected
  List<dynamic> cst_encode_partition_services(PartitionServices raw) {
    return [
      cst_encode_list_String(raw.fileInputs),
      cst_encode_String(raw.inputPartFmt),
      cst_encode_String(raw.output),
      cst_encode_String(raw.outputPartFmt),
      cst_encode_String(raw.datatype),
      cst_encode_bool(raw.isUncheck)
    ];
  }

  @protected
  List<dynamic> cst_encode_sequence_services(SequenceServices raw) {
    return [
      cst_encode_opt_String(raw.dirPath),
      cst_encode_list_String(raw.files),
      cst_encode_String(raw.fileFmt),
      cst_encode_String(raw.datatype),
      cst_encode_String(raw.outputDir)
    ];
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

class RustLibWire extends BaseWire {
  RustLibWire.fromExternalLibrary(ExternalLibrary lib);

  void dart_fn_deliver_output(int call_id, PlatformGeneralizedUint8ListPtr ptr_,
          int rust_vec_len_, int data_len_) =>
      wasmModule.dart_fn_deliver_output(
          call_id, ptr_, rust_vec_len_, data_len_);

  dynamic /* flutter_rust_bridge::for_generated::WireSyncRust2DartDco */
      wire_init_logger(String path) => wasmModule.wire_init_logger(path);

  void wire_ContigServices_new(NativePortType port_) =>
      wasmModule.wire_ContigServices_new(port_);

  void wire_ContigServices_summarize(
          NativePortType port_, List<dynamic> that) =>
      wasmModule.wire_ContigServices_summarize(port_, that);

  void wire_FastqServices_new(NativePortType port_) =>
      wasmModule.wire_FastqServices_new(port_);

  void wire_FastqServices_summarize(
          NativePortType port_, List<dynamic> that, String mode) =>
      wasmModule.wire_FastqServices_summarize(port_, that, mode);

  void wire_PartitionServices_convert_partition(
          NativePortType port_, List<dynamic> that) =>
      wasmModule.wire_PartitionServices_convert_partition(port_, that);

  void wire_PartitionServices_new(NativePortType port_) =>
      wasmModule.wire_PartitionServices_new(port_);

  void wire_SequenceServices_concat_alignment(
          NativePortType port_,
          List<dynamic> that,
          String out_fname,
          String out_fmt_str,
          String partition_fmt) =>
      wasmModule.wire_SequenceServices_concat_alignment(
          port_, that, out_fname, out_fmt_str, partition_fmt);

  void wire_SequenceServices_convert_sequence(NativePortType port_,
          List<dynamic> that, String output_fmt, bool sort) =>
      wasmModule.wire_SequenceServices_convert_sequence(
          port_, that, output_fmt, sort);

  void wire_SequenceServices_new(NativePortType port_) =>
      wasmModule.wire_SequenceServices_new(port_);

  void wire_SequenceServices_parse_sequence_id(
          NativePortType port_, List<dynamic> that, bool is_map) =>
      wasmModule.wire_SequenceServices_parse_sequence_id(port_, that, is_map);

  void wire_SequenceServices_summarize_alignment(NativePortType port_,
          List<dynamic> that, String output_prefix, int interval) =>
      wasmModule.wire_SequenceServices_summarize_alignment(
          port_, that, output_prefix, interval);

  void wire_SequenceServices_translate_sequence(
          NativePortType port_,
          List<dynamic> that,
          String table,
          int reading_frame,
          String output_fmt) =>
      wasmModule.wire_SequenceServices_translate_sequence(
          port_, that, table, reading_frame, output_fmt);

  void wire_show_dna_uppercase(NativePortType port_) =>
      wasmModule.wire_show_dna_uppercase(port_);
}

@JS('wasm_bindgen')
external RustLibWasmModule get wasmModule;

@JS()
@anonymous
class RustLibWasmModule implements WasmModule {
  @override
  external Object /* Promise */ call([String? moduleName]);

  @override
  external RustLibWasmModule bind(dynamic thisArg, String moduleName);

  external void dart_fn_deliver_output(int call_id,
      PlatformGeneralizedUint8ListPtr ptr_, int rust_vec_len_, int data_len_);

  external dynamic /* flutter_rust_bridge::for_generated::WireSyncRust2DartDco */
      wire_init_logger(String path);

  external void wire_ContigServices_new(NativePortType port_);

  external void wire_ContigServices_summarize(
      NativePortType port_, List<dynamic> that);

  external void wire_FastqServices_new(NativePortType port_);

  external void wire_FastqServices_summarize(
      NativePortType port_, List<dynamic> that, String mode);

  external void wire_PartitionServices_convert_partition(
      NativePortType port_, List<dynamic> that);

  external void wire_PartitionServices_new(NativePortType port_);

  external void wire_SequenceServices_concat_alignment(
      NativePortType port_,
      List<dynamic> that,
      String out_fname,
      String out_fmt_str,
      String partition_fmt);

  external void wire_SequenceServices_convert_sequence(
      NativePortType port_, List<dynamic> that, String output_fmt, bool sort);

  external void wire_SequenceServices_new(NativePortType port_);

  external void wire_SequenceServices_parse_sequence_id(
      NativePortType port_, List<dynamic> that, bool is_map);

  external void wire_SequenceServices_summarize_alignment(NativePortType port_,
      List<dynamic> that, String output_prefix, int interval);

  external void wire_SequenceServices_translate_sequence(NativePortType port_,
      List<dynamic> that, String table, int reading_frame, String output_fmt);

  external void wire_show_dna_uppercase(NativePortType port_);
}
