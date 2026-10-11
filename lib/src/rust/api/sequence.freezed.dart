// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sequence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FilteringParams {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FilteringParams);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FilteringParams()';
  }
}

/// @nodoc
class $FilteringParamsCopyWith<$Res> {
  $FilteringParamsCopyWith(
      FilteringParams _, $Res Function(FilteringParams) __);
}

/// Adds pattern-matching-related methods to [FilteringParams].
extension FilteringParamsPatterns on FilteringParams {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FilteringParams_MinTax value)? minTax,
    TResult Function(FilteringParams_AlnLen value)? alnLen,
    TResult Function(FilteringParams_ParsInf value)? parsInf,
    TResult Function(FilteringParams_PercInf value)? percInf,
    TResult Function(FilteringParams_TaxonAll value)? taxonAll,
    TResult Function(FilteringParams_None value)? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax() when minTax != null:
        return minTax(_that);
      case FilteringParams_AlnLen() when alnLen != null:
        return alnLen(_that);
      case FilteringParams_ParsInf() when parsInf != null:
        return parsInf(_that);
      case FilteringParams_PercInf() when percInf != null:
        return percInf(_that);
      case FilteringParams_TaxonAll() when taxonAll != null:
        return taxonAll(_that);
      case FilteringParams_None() when none != null:
        return none(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FilteringParams_MinTax value) minTax,
    required TResult Function(FilteringParams_AlnLen value) alnLen,
    required TResult Function(FilteringParams_ParsInf value) parsInf,
    required TResult Function(FilteringParams_PercInf value) percInf,
    required TResult Function(FilteringParams_TaxonAll value) taxonAll,
    required TResult Function(FilteringParams_None value) none,
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax():
        return minTax(_that);
      case FilteringParams_AlnLen():
        return alnLen(_that);
      case FilteringParams_ParsInf():
        return parsInf(_that);
      case FilteringParams_PercInf():
        return percInf(_that);
      case FilteringParams_TaxonAll():
        return taxonAll(_that);
      case FilteringParams_None():
        return none(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FilteringParams_MinTax value)? minTax,
    TResult? Function(FilteringParams_AlnLen value)? alnLen,
    TResult? Function(FilteringParams_ParsInf value)? parsInf,
    TResult? Function(FilteringParams_PercInf value)? percInf,
    TResult? Function(FilteringParams_TaxonAll value)? taxonAll,
    TResult? Function(FilteringParams_None value)? none,
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax() when minTax != null:
        return minTax(_that);
      case FilteringParams_AlnLen() when alnLen != null:
        return alnLen(_that);
      case FilteringParams_ParsInf() when parsInf != null:
        return parsInf(_that);
      case FilteringParams_PercInf() when percInf != null:
        return percInf(_that);
      case FilteringParams_TaxonAll() when taxonAll != null:
        return taxonAll(_that);
      case FilteringParams_None() when none != null:
        return none(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double field0)? minTax,
    TResult Function(BigInt field0)? alnLen,
    TResult Function(BigInt field0)? parsInf,
    TResult Function(double field0)? percInf,
    TResult Function(List<String> field0)? taxonAll,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax() when minTax != null:
        return minTax(_that.field0);
      case FilteringParams_AlnLen() when alnLen != null:
        return alnLen(_that.field0);
      case FilteringParams_ParsInf() when parsInf != null:
        return parsInf(_that.field0);
      case FilteringParams_PercInf() when percInf != null:
        return percInf(_that.field0);
      case FilteringParams_TaxonAll() when taxonAll != null:
        return taxonAll(_that.field0);
      case FilteringParams_None() when none != null:
        return none();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double field0) minTax,
    required TResult Function(BigInt field0) alnLen,
    required TResult Function(BigInt field0) parsInf,
    required TResult Function(double field0) percInf,
    required TResult Function(List<String> field0) taxonAll,
    required TResult Function() none,
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax():
        return minTax(_that.field0);
      case FilteringParams_AlnLen():
        return alnLen(_that.field0);
      case FilteringParams_ParsInf():
        return parsInf(_that.field0);
      case FilteringParams_PercInf():
        return percInf(_that.field0);
      case FilteringParams_TaxonAll():
        return taxonAll(_that.field0);
      case FilteringParams_None():
        return none();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double field0)? minTax,
    TResult? Function(BigInt field0)? alnLen,
    TResult? Function(BigInt field0)? parsInf,
    TResult? Function(double field0)? percInf,
    TResult? Function(List<String> field0)? taxonAll,
    TResult? Function()? none,
  }) {
    final _that = this;
    switch (_that) {
      case FilteringParams_MinTax() when minTax != null:
        return minTax(_that.field0);
      case FilteringParams_AlnLen() when alnLen != null:
        return alnLen(_that.field0);
      case FilteringParams_ParsInf() when parsInf != null:
        return parsInf(_that.field0);
      case FilteringParams_PercInf() when percInf != null:
        return percInf(_that.field0);
      case FilteringParams_TaxonAll() when taxonAll != null:
        return taxonAll(_that.field0);
      case FilteringParams_None() when none != null:
        return none();
      case _:
        return null;
    }
  }
}

/// @nodoc

class FilteringParams_MinTax extends FilteringParams {
  const FilteringParams_MinTax(this.field0) : super._();

  final double field0;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteringParams_MinTaxCopyWith<FilteringParams_MinTax> get copyWith =>
      _$FilteringParams_MinTaxCopyWithImpl<FilteringParams_MinTax>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteringParams_MinTax &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'FilteringParams.minTax(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $FilteringParams_MinTaxCopyWith<$Res>
    implements $FilteringParamsCopyWith<$Res> {
  factory $FilteringParams_MinTaxCopyWith(FilteringParams_MinTax value,
          $Res Function(FilteringParams_MinTax) _then) =
      _$FilteringParams_MinTaxCopyWithImpl;
  @useResult
  $Res call({double field0});
}

/// @nodoc
class _$FilteringParams_MinTaxCopyWithImpl<$Res>
    implements $FilteringParams_MinTaxCopyWith<$Res> {
  _$FilteringParams_MinTaxCopyWithImpl(this._self, this._then);

  final FilteringParams_MinTax _self;
  final $Res Function(FilteringParams_MinTax) _then;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(FilteringParams_MinTax(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class FilteringParams_AlnLen extends FilteringParams {
  const FilteringParams_AlnLen(this.field0) : super._();

  final BigInt field0;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteringParams_AlnLenCopyWith<FilteringParams_AlnLen> get copyWith =>
      _$FilteringParams_AlnLenCopyWithImpl<FilteringParams_AlnLen>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteringParams_AlnLen &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'FilteringParams.alnLen(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $FilteringParams_AlnLenCopyWith<$Res>
    implements $FilteringParamsCopyWith<$Res> {
  factory $FilteringParams_AlnLenCopyWith(FilteringParams_AlnLen value,
          $Res Function(FilteringParams_AlnLen) _then) =
      _$FilteringParams_AlnLenCopyWithImpl;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class _$FilteringParams_AlnLenCopyWithImpl<$Res>
    implements $FilteringParams_AlnLenCopyWith<$Res> {
  _$FilteringParams_AlnLenCopyWithImpl(this._self, this._then);

  final FilteringParams_AlnLen _self;
  final $Res Function(FilteringParams_AlnLen) _then;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(FilteringParams_AlnLen(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class FilteringParams_ParsInf extends FilteringParams {
  const FilteringParams_ParsInf(this.field0) : super._();

  final BigInt field0;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteringParams_ParsInfCopyWith<FilteringParams_ParsInf> get copyWith =>
      _$FilteringParams_ParsInfCopyWithImpl<FilteringParams_ParsInf>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteringParams_ParsInf &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'FilteringParams.parsInf(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $FilteringParams_ParsInfCopyWith<$Res>
    implements $FilteringParamsCopyWith<$Res> {
  factory $FilteringParams_ParsInfCopyWith(FilteringParams_ParsInf value,
          $Res Function(FilteringParams_ParsInf) _then) =
      _$FilteringParams_ParsInfCopyWithImpl;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class _$FilteringParams_ParsInfCopyWithImpl<$Res>
    implements $FilteringParams_ParsInfCopyWith<$Res> {
  _$FilteringParams_ParsInfCopyWithImpl(this._self, this._then);

  final FilteringParams_ParsInf _self;
  final $Res Function(FilteringParams_ParsInf) _then;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(FilteringParams_ParsInf(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class FilteringParams_PercInf extends FilteringParams {
  const FilteringParams_PercInf(this.field0) : super._();

  final double field0;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteringParams_PercInfCopyWith<FilteringParams_PercInf> get copyWith =>
      _$FilteringParams_PercInfCopyWithImpl<FilteringParams_PercInf>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteringParams_PercInf &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'FilteringParams.percInf(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $FilteringParams_PercInfCopyWith<$Res>
    implements $FilteringParamsCopyWith<$Res> {
  factory $FilteringParams_PercInfCopyWith(FilteringParams_PercInf value,
          $Res Function(FilteringParams_PercInf) _then) =
      _$FilteringParams_PercInfCopyWithImpl;
  @useResult
  $Res call({double field0});
}

/// @nodoc
class _$FilteringParams_PercInfCopyWithImpl<$Res>
    implements $FilteringParams_PercInfCopyWith<$Res> {
  _$FilteringParams_PercInfCopyWithImpl(this._self, this._then);

  final FilteringParams_PercInf _self;
  final $Res Function(FilteringParams_PercInf) _then;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(FilteringParams_PercInf(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class FilteringParams_TaxonAll extends FilteringParams {
  const FilteringParams_TaxonAll(List<String> field0)
      : _field0 = field0,
        super._();

  final List<String> _field0;
  List<String> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteringParams_TaxonAllCopyWith<FilteringParams_TaxonAll> get copyWith =>
      _$FilteringParams_TaxonAllCopyWithImpl<FilteringParams_TaxonAll>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteringParams_TaxonAll &&
            const DeepCollectionEquality().equals(other.field0, _field0));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_field0));
  }

  @override
  String toString() {
    return 'FilteringParams.taxonAll(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $FilteringParams_TaxonAllCopyWith<$Res>
    implements $FilteringParamsCopyWith<$Res> {
  factory $FilteringParams_TaxonAllCopyWith(FilteringParams_TaxonAll value,
          $Res Function(FilteringParams_TaxonAll) _then) =
      _$FilteringParams_TaxonAllCopyWithImpl;
  @useResult
  $Res call({List<String> field0});
}

/// @nodoc
class _$FilteringParams_TaxonAllCopyWithImpl<$Res>
    implements $FilteringParams_TaxonAllCopyWith<$Res> {
  _$FilteringParams_TaxonAllCopyWithImpl(this._self, this._then);

  final FilteringParams_TaxonAll _self;
  final $Res Function(FilteringParams_TaxonAll) _then;

  /// Create a copy of FilteringParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(FilteringParams_TaxonAll(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class FilteringParams_None extends FilteringParams {
  const FilteringParams_None() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FilteringParams_None);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FilteringParams.none()';
  }
}

/// @nodoc
mixin _$SequenceExtractionParams {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SequenceExtractionParams);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SequenceExtractionParams()';
  }
}

/// @nodoc
class $SequenceExtractionParamsCopyWith<$Res> {
  $SequenceExtractionParamsCopyWith(
      SequenceExtractionParams _, $Res Function(SequenceExtractionParams) __);
}

/// Adds pattern-matching-related methods to [SequenceExtractionParams].
extension SequenceExtractionParamsPatterns on SequenceExtractionParams {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SequenceExtractionParams_Id value)? id,
    TResult Function(SequenceExtractionParams_File value)? file,
    TResult Function(SequenceExtractionParams_Regex value)? regex,
    TResult Function(SequenceExtractionParams_None value)? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id() when id != null:
        return id(_that);
      case SequenceExtractionParams_File() when file != null:
        return file(_that);
      case SequenceExtractionParams_Regex() when regex != null:
        return regex(_that);
      case SequenceExtractionParams_None() when none != null:
        return none(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SequenceExtractionParams_Id value) id,
    required TResult Function(SequenceExtractionParams_File value) file,
    required TResult Function(SequenceExtractionParams_Regex value) regex,
    required TResult Function(SequenceExtractionParams_None value) none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id():
        return id(_that);
      case SequenceExtractionParams_File():
        return file(_that);
      case SequenceExtractionParams_Regex():
        return regex(_that);
      case SequenceExtractionParams_None():
        return none(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SequenceExtractionParams_Id value)? id,
    TResult? Function(SequenceExtractionParams_File value)? file,
    TResult? Function(SequenceExtractionParams_Regex value)? regex,
    TResult? Function(SequenceExtractionParams_None value)? none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id() when id != null:
        return id(_that);
      case SequenceExtractionParams_File() when file != null:
        return file(_that);
      case SequenceExtractionParams_Regex() when regex != null:
        return regex(_that);
      case SequenceExtractionParams_None() when none != null:
        return none(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<String> field0)? id,
    TResult Function(String field0)? file,
    TResult Function(String field0)? regex,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id() when id != null:
        return id(_that.field0);
      case SequenceExtractionParams_File() when file != null:
        return file(_that.field0);
      case SequenceExtractionParams_Regex() when regex != null:
        return regex(_that.field0);
      case SequenceExtractionParams_None() when none != null:
        return none();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<String> field0) id,
    required TResult Function(String field0) file,
    required TResult Function(String field0) regex,
    required TResult Function() none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id():
        return id(_that.field0);
      case SequenceExtractionParams_File():
        return file(_that.field0);
      case SequenceExtractionParams_Regex():
        return regex(_that.field0);
      case SequenceExtractionParams_None():
        return none();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<String> field0)? id,
    TResult? Function(String field0)? file,
    TResult? Function(String field0)? regex,
    TResult? Function()? none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceExtractionParams_Id() when id != null:
        return id(_that.field0);
      case SequenceExtractionParams_File() when file != null:
        return file(_that.field0);
      case SequenceExtractionParams_Regex() when regex != null:
        return regex(_that.field0);
      case SequenceExtractionParams_None() when none != null:
        return none();
      case _:
        return null;
    }
  }
}

/// @nodoc

class SequenceExtractionParams_Id extends SequenceExtractionParams {
  const SequenceExtractionParams_Id(List<String> field0)
      : _field0 = field0,
        super._();

  final List<String> _field0;
  List<String> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceExtractionParams_IdCopyWith<SequenceExtractionParams_Id>
      get copyWith => _$SequenceExtractionParams_IdCopyWithImpl<
          SequenceExtractionParams_Id>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceExtractionParams_Id &&
            const DeepCollectionEquality().equals(other.field0, _field0));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_field0));
  }

  @override
  String toString() {
    return 'SequenceExtractionParams.id(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SequenceExtractionParams_IdCopyWith<$Res>
    implements $SequenceExtractionParamsCopyWith<$Res> {
  factory $SequenceExtractionParams_IdCopyWith(
          SequenceExtractionParams_Id value,
          $Res Function(SequenceExtractionParams_Id) _then) =
      _$SequenceExtractionParams_IdCopyWithImpl;
  @useResult
  $Res call({List<String> field0});
}

/// @nodoc
class _$SequenceExtractionParams_IdCopyWithImpl<$Res>
    implements $SequenceExtractionParams_IdCopyWith<$Res> {
  _$SequenceExtractionParams_IdCopyWithImpl(this._self, this._then);

  final SequenceExtractionParams_Id _self;
  final $Res Function(SequenceExtractionParams_Id) _then;

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SequenceExtractionParams_Id(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class SequenceExtractionParams_File extends SequenceExtractionParams {
  const SequenceExtractionParams_File(this.field0) : super._();

  final String field0;

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceExtractionParams_FileCopyWith<SequenceExtractionParams_File>
      get copyWith => _$SequenceExtractionParams_FileCopyWithImpl<
          SequenceExtractionParams_File>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceExtractionParams_File &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'SequenceExtractionParams.file(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SequenceExtractionParams_FileCopyWith<$Res>
    implements $SequenceExtractionParamsCopyWith<$Res> {
  factory $SequenceExtractionParams_FileCopyWith(
          SequenceExtractionParams_File value,
          $Res Function(SequenceExtractionParams_File) _then) =
      _$SequenceExtractionParams_FileCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$SequenceExtractionParams_FileCopyWithImpl<$Res>
    implements $SequenceExtractionParams_FileCopyWith<$Res> {
  _$SequenceExtractionParams_FileCopyWithImpl(this._self, this._then);

  final SequenceExtractionParams_File _self;
  final $Res Function(SequenceExtractionParams_File) _then;

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SequenceExtractionParams_File(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SequenceExtractionParams_Regex extends SequenceExtractionParams {
  const SequenceExtractionParams_Regex(this.field0) : super._();

  final String field0;

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceExtractionParams_RegexCopyWith<SequenceExtractionParams_Regex>
      get copyWith => _$SequenceExtractionParams_RegexCopyWithImpl<
          SequenceExtractionParams_Regex>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceExtractionParams_Regex &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'SequenceExtractionParams.regex(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SequenceExtractionParams_RegexCopyWith<$Res>
    implements $SequenceExtractionParamsCopyWith<$Res> {
  factory $SequenceExtractionParams_RegexCopyWith(
          SequenceExtractionParams_Regex value,
          $Res Function(SequenceExtractionParams_Regex) _then) =
      _$SequenceExtractionParams_RegexCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$SequenceExtractionParams_RegexCopyWithImpl<$Res>
    implements $SequenceExtractionParams_RegexCopyWith<$Res> {
  _$SequenceExtractionParams_RegexCopyWithImpl(this._self, this._then);

  final SequenceExtractionParams_Regex _self;
  final $Res Function(SequenceExtractionParams_Regex) _then;

  /// Create a copy of SequenceExtractionParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SequenceExtractionParams_Regex(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SequenceExtractionParams_None extends SequenceExtractionParams {
  const SequenceExtractionParams_None() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceExtractionParams_None);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SequenceExtractionParams.none()';
  }
}

/// @nodoc
mixin _$SequenceRenamingParams {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SequenceRenamingParams);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SequenceRenamingParams()';
  }
}

/// @nodoc
class $SequenceRenamingParamsCopyWith<$Res> {
  $SequenceRenamingParamsCopyWith(
      SequenceRenamingParams _, $Res Function(SequenceRenamingParams) __);
}

/// Adds pattern-matching-related methods to [SequenceRenamingParams].
extension SequenceRenamingParamsPatterns on SequenceRenamingParams {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SequenceRenamingParams_RenameId value)? renameId,
    TResult Function(SequenceRenamingParams_RemoveStr value)? removeStr,
    TResult Function(SequenceRenamingParams_RemoveRegex value)? removeRegex,
    TResult Function(SequenceRenamingParams_ReplaceStr value)? replaceStr,
    TResult Function(SequenceRenamingParams_ReplaceRegex value)? replaceRegex,
    TResult Function(SequenceRenamingParams_None value)? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId() when renameId != null:
        return renameId(_that);
      case SequenceRenamingParams_RemoveStr() when removeStr != null:
        return removeStr(_that);
      case SequenceRenamingParams_RemoveRegex() when removeRegex != null:
        return removeRegex(_that);
      case SequenceRenamingParams_ReplaceStr() when replaceStr != null:
        return replaceStr(_that);
      case SequenceRenamingParams_ReplaceRegex() when replaceRegex != null:
        return replaceRegex(_that);
      case SequenceRenamingParams_None() when none != null:
        return none(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SequenceRenamingParams_RenameId value) renameId,
    required TResult Function(SequenceRenamingParams_RemoveStr value) removeStr,
    required TResult Function(SequenceRenamingParams_RemoveRegex value)
        removeRegex,
    required TResult Function(SequenceRenamingParams_ReplaceStr value)
        replaceStr,
    required TResult Function(SequenceRenamingParams_ReplaceRegex value)
        replaceRegex,
    required TResult Function(SequenceRenamingParams_None value) none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId():
        return renameId(_that);
      case SequenceRenamingParams_RemoveStr():
        return removeStr(_that);
      case SequenceRenamingParams_RemoveRegex():
        return removeRegex(_that);
      case SequenceRenamingParams_ReplaceStr():
        return replaceStr(_that);
      case SequenceRenamingParams_ReplaceRegex():
        return replaceRegex(_that);
      case SequenceRenamingParams_None():
        return none(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SequenceRenamingParams_RenameId value)? renameId,
    TResult? Function(SequenceRenamingParams_RemoveStr value)? removeStr,
    TResult? Function(SequenceRenamingParams_RemoveRegex value)? removeRegex,
    TResult? Function(SequenceRenamingParams_ReplaceStr value)? replaceStr,
    TResult? Function(SequenceRenamingParams_ReplaceRegex value)? replaceRegex,
    TResult? Function(SequenceRenamingParams_None value)? none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId() when renameId != null:
        return renameId(_that);
      case SequenceRenamingParams_RemoveStr() when removeStr != null:
        return removeStr(_that);
      case SequenceRenamingParams_RemoveRegex() when removeRegex != null:
        return removeRegex(_that);
      case SequenceRenamingParams_ReplaceStr() when replaceStr != null:
        return replaceStr(_that);
      case SequenceRenamingParams_ReplaceRegex() when replaceRegex != null:
        return replaceRegex(_that);
      case SequenceRenamingParams_None() when none != null:
        return none(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? renameId,
    TResult Function(String field0)? removeStr,
    TResult Function(String field0, bool field1)? removeRegex,
    TResult Function(String field0, String field1)? replaceStr,
    TResult Function(String field0, String field1, bool field2)? replaceRegex,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId() when renameId != null:
        return renameId(_that.field0);
      case SequenceRenamingParams_RemoveStr() when removeStr != null:
        return removeStr(_that.field0);
      case SequenceRenamingParams_RemoveRegex() when removeRegex != null:
        return removeRegex(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceStr() when replaceStr != null:
        return replaceStr(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceRegex() when replaceRegex != null:
        return replaceRegex(_that.field0, _that.field1, _that.field2);
      case SequenceRenamingParams_None() when none != null:
        return none();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) renameId,
    required TResult Function(String field0) removeStr,
    required TResult Function(String field0, bool field1) removeRegex,
    required TResult Function(String field0, String field1) replaceStr,
    required TResult Function(String field0, String field1, bool field2)
        replaceRegex,
    required TResult Function() none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId():
        return renameId(_that.field0);
      case SequenceRenamingParams_RemoveStr():
        return removeStr(_that.field0);
      case SequenceRenamingParams_RemoveRegex():
        return removeRegex(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceStr():
        return replaceStr(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceRegex():
        return replaceRegex(_that.field0, _that.field1, _that.field2);
      case SequenceRenamingParams_None():
        return none();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? renameId,
    TResult? Function(String field0)? removeStr,
    TResult? Function(String field0, bool field1)? removeRegex,
    TResult? Function(String field0, String field1)? replaceStr,
    TResult? Function(String field0, String field1, bool field2)? replaceRegex,
    TResult? Function()? none,
  }) {
    final _that = this;
    switch (_that) {
      case SequenceRenamingParams_RenameId() when renameId != null:
        return renameId(_that.field0);
      case SequenceRenamingParams_RemoveStr() when removeStr != null:
        return removeStr(_that.field0);
      case SequenceRenamingParams_RemoveRegex() when removeRegex != null:
        return removeRegex(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceStr() when replaceStr != null:
        return replaceStr(_that.field0, _that.field1);
      case SequenceRenamingParams_ReplaceRegex() when replaceRegex != null:
        return replaceRegex(_that.field0, _that.field1, _that.field2);
      case SequenceRenamingParams_None() when none != null:
        return none();
      case _:
        return null;
    }
  }
}

/// @nodoc

class SequenceRenamingParams_RenameId extends SequenceRenamingParams {
  const SequenceRenamingParams_RenameId(this.field0) : super._();

  final String field0;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceRenamingParams_RenameIdCopyWith<SequenceRenamingParams_RenameId>
      get copyWith => _$SequenceRenamingParams_RenameIdCopyWithImpl<
          SequenceRenamingParams_RenameId>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_RenameId &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'SequenceRenamingParams.renameId(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SequenceRenamingParams_RenameIdCopyWith<$Res>
    implements $SequenceRenamingParamsCopyWith<$Res> {
  factory $SequenceRenamingParams_RenameIdCopyWith(
          SequenceRenamingParams_RenameId value,
          $Res Function(SequenceRenamingParams_RenameId) _then) =
      _$SequenceRenamingParams_RenameIdCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$SequenceRenamingParams_RenameIdCopyWithImpl<$Res>
    implements $SequenceRenamingParams_RenameIdCopyWith<$Res> {
  _$SequenceRenamingParams_RenameIdCopyWithImpl(this._self, this._then);

  final SequenceRenamingParams_RenameId _self;
  final $Res Function(SequenceRenamingParams_RenameId) _then;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SequenceRenamingParams_RenameId(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SequenceRenamingParams_RemoveStr extends SequenceRenamingParams {
  const SequenceRenamingParams_RemoveStr(this.field0) : super._();

  final String field0;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceRenamingParams_RemoveStrCopyWith<SequenceRenamingParams_RemoveStr>
      get copyWith => _$SequenceRenamingParams_RemoveStrCopyWithImpl<
          SequenceRenamingParams_RemoveStr>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_RemoveStr &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0);
  }

  @override
  String toString() {
    return 'SequenceRenamingParams.removeStr(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SequenceRenamingParams_RemoveStrCopyWith<$Res>
    implements $SequenceRenamingParamsCopyWith<$Res> {
  factory $SequenceRenamingParams_RemoveStrCopyWith(
          SequenceRenamingParams_RemoveStr value,
          $Res Function(SequenceRenamingParams_RemoveStr) _then) =
      _$SequenceRenamingParams_RemoveStrCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$SequenceRenamingParams_RemoveStrCopyWithImpl<$Res>
    implements $SequenceRenamingParams_RemoveStrCopyWith<$Res> {
  _$SequenceRenamingParams_RemoveStrCopyWithImpl(this._self, this._then);

  final SequenceRenamingParams_RemoveStr _self;
  final $Res Function(SequenceRenamingParams_RemoveStr) _then;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SequenceRenamingParams_RemoveStr(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SequenceRenamingParams_RemoveRegex extends SequenceRenamingParams {
  const SequenceRenamingParams_RemoveRegex(this.field0, this.field1)
      : super._();

  final String field0;
  final bool field1;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceRenamingParams_RemoveRegexCopyWith<
          SequenceRenamingParams_RemoveRegex>
      get copyWith => _$SequenceRenamingParams_RemoveRegexCopyWithImpl<
          SequenceRenamingParams_RemoveRegex>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_RemoveRegex &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0, field1);
  }

  @override
  String toString() {
    return 'SequenceRenamingParams.removeRegex(field0: $field0, field1: $field1)';
  }
}

/// @nodoc
abstract mixin class $SequenceRenamingParams_RemoveRegexCopyWith<$Res>
    implements $SequenceRenamingParamsCopyWith<$Res> {
  factory $SequenceRenamingParams_RemoveRegexCopyWith(
          SequenceRenamingParams_RemoveRegex value,
          $Res Function(SequenceRenamingParams_RemoveRegex) _then) =
      _$SequenceRenamingParams_RemoveRegexCopyWithImpl;
  @useResult
  $Res call({String field0, bool field1});
}

/// @nodoc
class _$SequenceRenamingParams_RemoveRegexCopyWithImpl<$Res>
    implements $SequenceRenamingParams_RemoveRegexCopyWith<$Res> {
  _$SequenceRenamingParams_RemoveRegexCopyWithImpl(this._self, this._then);

  final SequenceRenamingParams_RemoveRegex _self;
  final $Res Function(SequenceRenamingParams_RemoveRegex) _then;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
  }) {
    return _then(SequenceRenamingParams_RemoveRegex(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field1
          ? _self.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class SequenceRenamingParams_ReplaceStr extends SequenceRenamingParams {
  const SequenceRenamingParams_ReplaceStr(this.field0, this.field1) : super._();

  final String field0;
  final String field1;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceRenamingParams_ReplaceStrCopyWith<SequenceRenamingParams_ReplaceStr>
      get copyWith => _$SequenceRenamingParams_ReplaceStrCopyWithImpl<
          SequenceRenamingParams_ReplaceStr>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_ReplaceStr &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0, field1);
  }

  @override
  String toString() {
    return 'SequenceRenamingParams.replaceStr(field0: $field0, field1: $field1)';
  }
}

/// @nodoc
abstract mixin class $SequenceRenamingParams_ReplaceStrCopyWith<$Res>
    implements $SequenceRenamingParamsCopyWith<$Res> {
  factory $SequenceRenamingParams_ReplaceStrCopyWith(
          SequenceRenamingParams_ReplaceStr value,
          $Res Function(SequenceRenamingParams_ReplaceStr) _then) =
      _$SequenceRenamingParams_ReplaceStrCopyWithImpl;
  @useResult
  $Res call({String field0, String field1});
}

/// @nodoc
class _$SequenceRenamingParams_ReplaceStrCopyWithImpl<$Res>
    implements $SequenceRenamingParams_ReplaceStrCopyWith<$Res> {
  _$SequenceRenamingParams_ReplaceStrCopyWithImpl(this._self, this._then);

  final SequenceRenamingParams_ReplaceStr _self;
  final $Res Function(SequenceRenamingParams_ReplaceStr) _then;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
  }) {
    return _then(SequenceRenamingParams_ReplaceStr(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field1
          ? _self.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SequenceRenamingParams_ReplaceRegex extends SequenceRenamingParams {
  const SequenceRenamingParams_ReplaceRegex(
      this.field0, this.field1, this.field2)
      : super._();

  final String field0;
  final String field1;
  final bool field2;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SequenceRenamingParams_ReplaceRegexCopyWith<
          SequenceRenamingParams_ReplaceRegex>
      get copyWith => _$SequenceRenamingParams_ReplaceRegexCopyWithImpl<
          SequenceRenamingParams_ReplaceRegex>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_ReplaceRegex &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1) &&
            (identical(other.field2, field2) || other.field2 == field2));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, field0, field1, field2);
  }

  @override
  String toString() {
    return 'SequenceRenamingParams.replaceRegex(field0: $field0, field1: $field1, field2: $field2)';
  }
}

/// @nodoc
abstract mixin class $SequenceRenamingParams_ReplaceRegexCopyWith<$Res>
    implements $SequenceRenamingParamsCopyWith<$Res> {
  factory $SequenceRenamingParams_ReplaceRegexCopyWith(
          SequenceRenamingParams_ReplaceRegex value,
          $Res Function(SequenceRenamingParams_ReplaceRegex) _then) =
      _$SequenceRenamingParams_ReplaceRegexCopyWithImpl;
  @useResult
  $Res call({String field0, String field1, bool field2});
}

/// @nodoc
class _$SequenceRenamingParams_ReplaceRegexCopyWithImpl<$Res>
    implements $SequenceRenamingParams_ReplaceRegexCopyWith<$Res> {
  _$SequenceRenamingParams_ReplaceRegexCopyWithImpl(this._self, this._then);

  final SequenceRenamingParams_ReplaceRegex _self;
  final $Res Function(SequenceRenamingParams_ReplaceRegex) _then;

  /// Create a copy of SequenceRenamingParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
    Object? field2 = null,
  }) {
    return _then(SequenceRenamingParams_ReplaceRegex(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field1
          ? _self.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as String,
      null == field2
          ? _self.field2
          : field2 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class SequenceRenamingParams_None extends SequenceRenamingParams {
  const SequenceRenamingParams_None() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SequenceRenamingParams_None);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SequenceRenamingParams.none()';
  }
}

// dart format on
