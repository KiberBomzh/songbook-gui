// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SimpleLine {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimpleLine()';
}


}

/// @nodoc
class $SimpleLineCopyWith<$Res>  {
$SimpleLineCopyWith(SimpleLine _, $Res Function(SimpleLine) __);
}


/// Adds pattern-matching-related methods to [SimpleLine].
extension SimpleLinePatterns on SimpleLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SimpleLine_Row value)?  row,TResult Function( SimpleLine_ChordsLine value)?  chordsLine,TResult Function( SimpleLine_PlainText value)?  plainText,TResult Function( SimpleLine_Tab value)?  tab,TResult Function( SimpleLine_EmptyLine value)?  emptyLine,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SimpleLine_Row() when row != null:
return row(_that);case SimpleLine_ChordsLine() when chordsLine != null:
return chordsLine(_that);case SimpleLine_PlainText() when plainText != null:
return plainText(_that);case SimpleLine_Tab() when tab != null:
return tab(_that);case SimpleLine_EmptyLine() when emptyLine != null:
return emptyLine(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SimpleLine_Row value)  row,required TResult Function( SimpleLine_ChordsLine value)  chordsLine,required TResult Function( SimpleLine_PlainText value)  plainText,required TResult Function( SimpleLine_Tab value)  tab,required TResult Function( SimpleLine_EmptyLine value)  emptyLine,}){
final _that = this;
switch (_that) {
case SimpleLine_Row():
return row(_that);case SimpleLine_ChordsLine():
return chordsLine(_that);case SimpleLine_PlainText():
return plainText(_that);case SimpleLine_Tab():
return tab(_that);case SimpleLine_EmptyLine():
return emptyLine(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SimpleLine_Row value)?  row,TResult? Function( SimpleLine_ChordsLine value)?  chordsLine,TResult? Function( SimpleLine_PlainText value)?  plainText,TResult? Function( SimpleLine_Tab value)?  tab,TResult? Function( SimpleLine_EmptyLine value)?  emptyLine,}){
final _that = this;
switch (_that) {
case SimpleLine_Row() when row != null:
return row(_that);case SimpleLine_ChordsLine() when chordsLine != null:
return chordsLine(_that);case SimpleLine_PlainText() when plainText != null:
return plainText(_that);case SimpleLine_Tab() when tab != null:
return tab(_that);case SimpleLine_EmptyLine() when emptyLine != null:
return emptyLine(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0,  String field1,  String field2)?  row,TResult Function( String field0)?  chordsLine,TResult Function( String field0)?  plainText,TResult Function( String field0)?  tab,TResult Function()?  emptyLine,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SimpleLine_Row() when row != null:
return row(_that.field0,_that.field1,_that.field2);case SimpleLine_ChordsLine() when chordsLine != null:
return chordsLine(_that.field0);case SimpleLine_PlainText() when plainText != null:
return plainText(_that.field0);case SimpleLine_Tab() when tab != null:
return tab(_that.field0);case SimpleLine_EmptyLine() when emptyLine != null:
return emptyLine();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0,  String field1,  String field2)  row,required TResult Function( String field0)  chordsLine,required TResult Function( String field0)  plainText,required TResult Function( String field0)  tab,required TResult Function()  emptyLine,}) {final _that = this;
switch (_that) {
case SimpleLine_Row():
return row(_that.field0,_that.field1,_that.field2);case SimpleLine_ChordsLine():
return chordsLine(_that.field0);case SimpleLine_PlainText():
return plainText(_that.field0);case SimpleLine_Tab():
return tab(_that.field0);case SimpleLine_EmptyLine():
return emptyLine();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0,  String field1,  String field2)?  row,TResult? Function( String field0)?  chordsLine,TResult? Function( String field0)?  plainText,TResult? Function( String field0)?  tab,TResult? Function()?  emptyLine,}) {final _that = this;
switch (_that) {
case SimpleLine_Row() when row != null:
return row(_that.field0,_that.field1,_that.field2);case SimpleLine_ChordsLine() when chordsLine != null:
return chordsLine(_that.field0);case SimpleLine_PlainText() when plainText != null:
return plainText(_that.field0);case SimpleLine_Tab() when tab != null:
return tab(_that.field0);case SimpleLine_EmptyLine() when emptyLine != null:
return emptyLine();case _:
  return null;

}
}

}

/// @nodoc


class SimpleLine_Row extends SimpleLine {
  const SimpleLine_Row(this.field0, this.field1, this.field2): super._();
  

 final  String field0;
 final  String field1;
 final  String field2;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimpleLine_RowCopyWith<SimpleLine_Row> get copyWith => _$SimpleLine_RowCopyWithImpl<SimpleLine_Row>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine_Row&&(identical(other.field0, field0) || other.field0 == field0)&&(identical(other.field1, field1) || other.field1 == field1)&&(identical(other.field2, field2) || other.field2 == field2));
}


@override
int get hashCode => Object.hash(runtimeType,field0,field1,field2);

@override
String toString() {
  return 'SimpleLine.row(field0: $field0, field1: $field1, field2: $field2)';
}


}

/// @nodoc
abstract mixin class $SimpleLine_RowCopyWith<$Res> implements $SimpleLineCopyWith<$Res> {
  factory $SimpleLine_RowCopyWith(SimpleLine_Row value, $Res Function(SimpleLine_Row) _then) = _$SimpleLine_RowCopyWithImpl;
@useResult
$Res call({
 String field0, String field1, String field2
});




}
/// @nodoc
class _$SimpleLine_RowCopyWithImpl<$Res>
    implements $SimpleLine_RowCopyWith<$Res> {
  _$SimpleLine_RowCopyWithImpl(this._self, this._then);

  final SimpleLine_Row _self;
  final $Res Function(SimpleLine_Row) _then;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,Object? field1 = null,Object? field2 = null,}) {
  return _then(SimpleLine_Row(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,null == field1 ? _self.field1 : field1 // ignore: cast_nullable_to_non_nullable
as String,null == field2 ? _self.field2 : field2 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SimpleLine_ChordsLine extends SimpleLine {
  const SimpleLine_ChordsLine(this.field0): super._();
  

 final  String field0;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimpleLine_ChordsLineCopyWith<SimpleLine_ChordsLine> get copyWith => _$SimpleLine_ChordsLineCopyWithImpl<SimpleLine_ChordsLine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine_ChordsLine&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'SimpleLine.chordsLine(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $SimpleLine_ChordsLineCopyWith<$Res> implements $SimpleLineCopyWith<$Res> {
  factory $SimpleLine_ChordsLineCopyWith(SimpleLine_ChordsLine value, $Res Function(SimpleLine_ChordsLine) _then) = _$SimpleLine_ChordsLineCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$SimpleLine_ChordsLineCopyWithImpl<$Res>
    implements $SimpleLine_ChordsLineCopyWith<$Res> {
  _$SimpleLine_ChordsLineCopyWithImpl(this._self, this._then);

  final SimpleLine_ChordsLine _self;
  final $Res Function(SimpleLine_ChordsLine) _then;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(SimpleLine_ChordsLine(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SimpleLine_PlainText extends SimpleLine {
  const SimpleLine_PlainText(this.field0): super._();
  

 final  String field0;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimpleLine_PlainTextCopyWith<SimpleLine_PlainText> get copyWith => _$SimpleLine_PlainTextCopyWithImpl<SimpleLine_PlainText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine_PlainText&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'SimpleLine.plainText(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $SimpleLine_PlainTextCopyWith<$Res> implements $SimpleLineCopyWith<$Res> {
  factory $SimpleLine_PlainTextCopyWith(SimpleLine_PlainText value, $Res Function(SimpleLine_PlainText) _then) = _$SimpleLine_PlainTextCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$SimpleLine_PlainTextCopyWithImpl<$Res>
    implements $SimpleLine_PlainTextCopyWith<$Res> {
  _$SimpleLine_PlainTextCopyWithImpl(this._self, this._then);

  final SimpleLine_PlainText _self;
  final $Res Function(SimpleLine_PlainText) _then;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(SimpleLine_PlainText(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SimpleLine_Tab extends SimpleLine {
  const SimpleLine_Tab(this.field0): super._();
  

 final  String field0;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimpleLine_TabCopyWith<SimpleLine_Tab> get copyWith => _$SimpleLine_TabCopyWithImpl<SimpleLine_Tab>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine_Tab&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'SimpleLine.tab(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $SimpleLine_TabCopyWith<$Res> implements $SimpleLineCopyWith<$Res> {
  factory $SimpleLine_TabCopyWith(SimpleLine_Tab value, $Res Function(SimpleLine_Tab) _then) = _$SimpleLine_TabCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$SimpleLine_TabCopyWithImpl<$Res>
    implements $SimpleLine_TabCopyWith<$Res> {
  _$SimpleLine_TabCopyWithImpl(this._self, this._then);

  final SimpleLine_Tab _self;
  final $Res Function(SimpleLine_Tab) _then;

/// Create a copy of SimpleLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(SimpleLine_Tab(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SimpleLine_EmptyLine extends SimpleLine {
  const SimpleLine_EmptyLine(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimpleLine_EmptyLine);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimpleLine.emptyLine()';
}


}




// dart format on
