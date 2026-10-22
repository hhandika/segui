import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/types.dart';

/// Kind of data a tool reads or writes, used to match a run's output with
/// the tools that can take it as input.
enum ToolData {
  reads,
  contigs,
  maf,
  alignment,

  /// Unaligned sequences, such as after removing gaps.
  sequences,
  partition,

  /// Tables or text, such as summaries, that no tool takes as input.
  report,
}

/// What a tool reads and writes.
class ToolDataFlow {
  const ToolDataFlow({
    required this.accepts,
    required this.produces,
    required this.inputGroup,
    this.isSingleInput = false,
  });

  /// Data kinds the tool takes as its main input.
  final Set<ToolData> accepts;
  final ToolData produces;

  /// File type of the main input picker.
  final XTypeGroup inputGroup;

  /// Whether the main input picker takes only one file.
  final bool isSingleInput;

  /// Data kind of the tool's main input when it takes only one.
  ToolData get input => accepts.first;
}

/// Sequence tools edit samples inside alignments and keep the alignment.
const ToolDataFlow _sequenceFlow = ToolDataFlow(
  accepts: {ToolData.alignment, ToolData.sequences},
  produces: ToolData.alignment,
  inputGroup: sequenceTypeGroup,
);

const ToolDataFlow _alignmentFlow = ToolDataFlow(
  accepts: {ToolData.alignment},
  produces: ToolData.alignment,
  inputGroup: sequenceTypeGroup,
);

const ToolDataFlow _alignmentReportFlow = ToolDataFlow(
  accepts: {ToolData.alignment},
  produces: ToolData.report,
  inputGroup: sequenceTypeGroup,
);

/// What [tool] reads and writes.
ToolDataFlow dataFlowFor(HomeTool tool) {
  final Enum operation = tool.operation;
  if (operation is GenomicOperationType) {
    return switch (operation) {
      GenomicOperationType.readSummary => const ToolDataFlow(
          accepts: {ToolData.reads},
          produces: ToolData.report,
          inputGroup: genomicRawReadTypeGroup,
        ),
      GenomicOperationType.contigSummary => const ToolDataFlow(
          accepts: {ToolData.contigs},
          produces: ToolData.report,
          inputGroup: genomicContigTypeGroup,
        ),
      GenomicOperationType.mafConversion => const ToolDataFlow(
          accepts: {ToolData.maf},
          produces: ToolData.alignment,
          inputGroup: mafTypeGroup,
        ),
      GenomicOperationType.mafSummary => const ToolDataFlow(
          accepts: {ToolData.maf},
          produces: ToolData.report,
          inputGroup: mafTypeGroup,
        ),
    };
  }
  if (operation is AlignmentOperationType) {
    return switch (operation) {
      AlignmentOperationType.concatenation ||
      AlignmentOperationType.conversion ||
      AlignmentOperationType.filter ||
      AlignmentOperationType.trimming =>
        _alignmentFlow,
      AlignmentOperationType.summary ||
      AlignmentOperationType.distance =>
        _alignmentReportFlow,
      AlignmentOperationType.partition => const ToolDataFlow(
          accepts: {ToolData.partition},
          produces: ToolData.partition,
          inputGroup: partitionTypeGroup,
        ),
      AlignmentOperationType.split => const ToolDataFlow(
          accepts: {ToolData.alignment},
          produces: ToolData.alignment,
          inputGroup: sequenceTypeGroup,
          isSingleInput: true,
        ),
      AlignmentOperationType.unalignment => const ToolDataFlow(
          accepts: {ToolData.alignment},
          produces: ToolData.sequences,
          inputGroup: sequenceTypeGroup,
        ),
    };
  }
  return switch (operation as SequenceOperationType) {
    SequenceOperationType.idExtraction => const ToolDataFlow(
        accepts: {ToolData.alignment, ToolData.sequences},
        produces: ToolData.report,
        inputGroup: sequenceTypeGroup,
      ),
    SequenceOperationType.extraction ||
    SequenceOperationType.removal ||
    SequenceOperationType.renaming ||
    SequenceOperationType.translation ||
    SequenceOperationType.addition ||
    SequenceOperationType.filtering ||
    SequenceOperationType.transposition =>
      _sequenceFlow,
  };
}

/// Whether [file] is a partition written by SEGUL, named
/// `<name>_partition.nex` or `<name>_partition.txt`.
bool isPartitionFile(File file) {
  return p.basenameWithoutExtension(file.path).endsWith('_partition');
}

/// A setting used by a finished run.
class RunParameter {
  const RunParameter(this.label, this.value);

  final String label;
  final String value;
}

/// Tool and settings of the last successful run on the current tool page.
class ToolRun {
  const ToolRun({required this.tool, required this.parameters, this.report});

  final HomeTool tool;
  final List<RunParameter> parameters;

  /// Report written by the run that opens in its own viewer, such as the
  /// read report of a complete read summary.
  final File? report;
}

final lastRunProvider = NotifierProvider<LastRun, ToolRun?>(LastRun.new);

/// Keeps the last successful run until the tool or its input changes.
class LastRun extends Notifier<ToolRun?> {
  @override
  ToolRun? build() {
    ref.watch(currentToolProvider);
    ref.watch(fileInputProvider);
    return null;
  }

  /// Records a successful run of the current tool with its [parameters]
  /// and the [report] it wrote, if any. Empty values are left out.
  void record(List<RunParameter> parameters, {File? report}) {
    final HomeTool? tool = ref.read(currentToolProvider);
    if (tool == null) {
      return;
    }
    state = ToolRun(
      tool: tool,
      parameters: [
        for (final parameter in parameters)
          if (parameter.value.trim().isNotEmpty) parameter,
      ],
      report: report,
    );
  }
}

/// Files handed to a tool's picker of [group].
class ChainInput {
  const ChainInput({required this.group, required this.files});

  final XTypeGroup group;
  final List<File> files;
}

/// A tool to run next, with the files it receives.
class WorkbenchStep {
  const WorkbenchStep({
    required this.tool,
    required this.inputs,
    required this.isFromOutput,
  });

  final HomeTool tool;
  final List<ChainInput> inputs;

  /// Whether [inputs] come from the run's output rather than its input,
  /// as after a summary that writes only tables.
  final bool isFromOutput;

  /// Number of main input files passed to [tool].
  int get fileCount => inputs.isEmpty ? 0 : inputs.first.files.length;
}

/// Where a workflow stands after a run of one of its steps.
class WorkflowProgress {
  const WorkflowProgress({
    required this.workflow,
    required this.stepIndex,
    required this.next,
  });

  final HomeWorkflow workflow;

  /// Index of the step that just ran.
  final int stepIndex;

  /// The step after [stepIndex], or null when the workflow is complete.
  final WorkbenchStep? next;

  bool get isComplete => next == null;
}

/// Next steps after a run: workflow steps and other tools that take the
/// run's data.
class WorkbenchSuggestions {
  const WorkbenchSuggestions({required this.workflows, required this.tools});

  final List<WorkflowProgress> workflows;

  /// Compatible tools that are not already a workflow's next step.
  final List<WorkbenchStep> tools;

  /// Builds the next steps after a run of [tool] that read [inputFiles] and
  /// wrote [outputFiles].
  factory WorkbenchSuggestions.after({
    required HomeTool tool,
    required List<File> inputFiles,
    required List<File> outputFiles,
  }) {
    final _ChainSource source = _ChainSource(
      tool: tool,
      inputFiles: inputFiles,
      outputFiles: outputFiles,
    );
    final List<WorkflowProgress> workflows = [
      for (final workflow in homeWorkflows)
        if (workflow.steps.contains(tool))
          _progress(workflow, workflow.steps.indexOf(tool), source),
    ];
    final Set<HomeTool> nextSteps = {
      for (final progress in workflows)
        if (progress.next != null) progress.next!.tool,
    };
    final List<WorkbenchStep> tools = [
      for (final candidate in homeTools)
        if (candidate != tool &&
            !nextSteps.contains(candidate) &&
            dataFlowFor(candidate).accepts.contains(source.data))
          source.stepFor(candidate),
    ];
    return WorkbenchSuggestions(workflows: workflows, tools: tools);
  }

  static WorkflowProgress _progress(
    HomeWorkflow workflow,
    int index,
    _ChainSource source,
  ) {
    final bool isLast = index == workflow.steps.length - 1;
    return WorkflowProgress(
      workflow: workflow,
      stepIndex: index,
      next: isLast ? null : source.stepFor(workflow.steps[index + 1]),
    );
  }
}

/// Files a run passes on: its output, or its input when it writes only
/// reports.
class _ChainSource {
  _ChainSource({
    required HomeTool tool,
    required List<File> inputFiles,
    required List<File> outputFiles,
  }) {
    final ToolDataFlow flow = dataFlowFor(tool);
    isFromOutput = flow.produces != ToolData.report;
    data = isFromOutput ? flow.produces : flow.input;
    files = isFromOutput ? outputFiles : inputFiles;
  }

  late final bool isFromOutput;
  late final ToolData data;
  late final List<File> files;

  /// Step for [target] with the files it can take. The files are left out
  /// when they do not match the target or a single-file picker gets many.
  WorkbenchStep stepFor(HomeTool target) {
    final ToolDataFlow flow = dataFlowFor(target);
    final List<ChainInput> inputs = [];
    if (flow.accepts.contains(data)) {
      final List<File> main = _matching(flow.inputGroup);
      if (main.isNotEmpty && (!flow.isSingleInput || main.length == 1)) {
        inputs.add(ChainInput(group: flow.inputGroup, files: main));
        // Split reads the partition of a concatenated alignment.
        final List<File> partitions = _matching(partitionTypeGroup);
        if (flow.isSingleInput && partitions.length == 1) {
          inputs.add(ChainInput(group: partitionTypeGroup, files: partitions));
        }
      }
    }
    return WorkbenchStep(
      tool: target,
      inputs: inputs,
      isFromOutput: isFromOutput,
    );
  }

  List<File> _matching(XTypeGroup group) {
    final bool wantsPartition = group == partitionTypeGroup;
    return [
      for (final file in files)
        if (matchesTypeGroup(file, group) &&
            isPartitionFile(file) == wantsPartition)
          file,
    ];
  }
}

/// Next steps after the last successful run, or null before a run.
final workbenchSuggestionsProvider = Provider<WorkbenchSuggestions?>((ref) {
  final ToolRun? run = ref.watch(lastRunProvider);
  if (run == null) {
    return null;
  }
  final List<SegulInputFile> inputs = ref.watch(fileInputProvider).value ?? [];
  final SegulOutputFile? output = ref.watch(fileOutputProvider).value;
  return WorkbenchSuggestions.after(
    tool: run.tool,
    inputFiles: [for (final input in inputs) input.file],
    outputFiles: [
      for (final file in output?.files ?? const [])
        if (file.isNew) file.file,
    ],
  );
});

final workbenchNavigatorProvider =
    Provider<WorkbenchNavigator>((ref) => WorkbenchNavigator(ref));

/// Opens a next step with the files it receives.
class WorkbenchNavigator {
  const WorkbenchNavigator(this._ref);

  final Ref _ref;

  Future<void> open(WorkbenchStep step) async {
    // Opening a tool clears the input and output files.
    _ref.read(homeToolNavigatorProvider).open(step.tool);
    final FileInput input = _ref.read(fileInputProvider.notifier);
    for (final ChainInput chain in step.inputs) {
      await input.replaceType(
        [for (final file in chain.files) XFile(file.path)],
        chain.group,
      );
    }
  }
}
