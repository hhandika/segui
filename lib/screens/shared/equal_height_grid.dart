import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/styles/design_tokens.dart';

/// Lays out [children] in [columns] equal-width columns and gives every child
/// the height of the tallest one, so all cards in the grid match in size.
class EqualHeightGrid extends MultiChildRenderObjectWidget {
  const EqualHeightGrid({
    super.key,
    required this.columns,
    this.spacing = SeguiSpacing.lg,
    this.runSpacing = SeguiSpacing.lg,
    super.children,
  }) : assert(columns > 0);

  final int columns;
  final double spacing;
  final double runSpacing;

  @override
  RenderEqualHeightGrid createRenderObject(BuildContext context) {
    return RenderEqualHeightGrid(
      columns: columns,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderEqualHeightGrid renderObject,
  ) {
    renderObject
      ..columns = columns
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }
}

class EqualHeightGridParentData extends ContainerBoxParentData<RenderBox> {}

class RenderEqualHeightGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, EqualHeightGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, EqualHeightGridParentData> {
  RenderEqualHeightGrid({
    required int columns,
    required double spacing,
    required double runSpacing,
  })  : _columns = columns,
        _spacing = spacing,
        _runSpacing = runSpacing;

  int get columns => _columns;
  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! EqualHeightGridParentData) {
      child.parentData = EqualHeightGridParentData();
    }
  }

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _layout(constraints, dry: true);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final double width = constraints.maxWidth;
    final double itemWidth = math.max(
      0,
      (width - spacing * (columns - 1)) / columns,
    );
    final BoxConstraints itemConstraints = BoxConstraints.tightFor(
      width: itemWidth,
    );

    double itemHeight = 0;
    int count = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      itemHeight =
          math.max(itemHeight, child.getDryLayout(itemConstraints).height);
      count++;
      child = childAfter(child);
    }
    if (count == 0) {
      return constraints.constrain(Size(width, 0));
    }

    final int rows = (count / columns).ceil();
    final double height = rows * itemHeight + (rows - 1) * runSpacing;
    if (!dry) {
      final BoxConstraints tight = BoxConstraints.tight(
        Size(itemWidth, itemHeight),
      );
      int index = 0;
      child = firstChild;
      while (child != null) {
        child.layout(tight);
        final EqualHeightGridParentData data =
            child.parentData! as EqualHeightGridParentData;
        data.offset = Offset(
          (index % columns) * (itemWidth + spacing),
          (index ~/ columns) * (itemHeight + runSpacing),
        );
        index++;
        child = childAfter(child);
      }
    }
    return constraints.constrain(Size(width, height));
  }
}
