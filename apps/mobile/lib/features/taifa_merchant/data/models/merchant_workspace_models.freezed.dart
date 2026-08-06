// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_workspace_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MerchantCounts {

 int get branches; int get employees; int get devices;
/// Create a copy of MerchantCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantCountsCopyWith<MerchantCounts> get copyWith => _$MerchantCountsCopyWithImpl<MerchantCounts>(this as MerchantCounts, _$identity);

  /// Serializes this MerchantCounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantCounts&&(identical(other.branches, branches) || other.branches == branches)&&(identical(other.employees, employees) || other.employees == employees)&&(identical(other.devices, devices) || other.devices == devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branches,employees,devices);

@override
String toString() {
  return 'MerchantCounts(branches: $branches, employees: $employees, devices: $devices)';
}


}

/// @nodoc
abstract mixin class $MerchantCountsCopyWith<$Res>  {
  factory $MerchantCountsCopyWith(MerchantCounts value, $Res Function(MerchantCounts) _then) = _$MerchantCountsCopyWithImpl;
@useResult
$Res call({
 int branches, int employees, int devices
});




}
/// @nodoc
class _$MerchantCountsCopyWithImpl<$Res>
    implements $MerchantCountsCopyWith<$Res> {
  _$MerchantCountsCopyWithImpl(this._self, this._then);

  final MerchantCounts _self;
  final $Res Function(MerchantCounts) _then;

/// Create a copy of MerchantCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branches = null,Object? employees = null,Object? devices = null,}) {
  return _then(_self.copyWith(
branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as int,employees: null == employees ? _self.employees : employees // ignore: cast_nullable_to_non_nullable
as int,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MerchantCounts].
extension MerchantCountsPatterns on MerchantCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantCounts() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantCounts value)  $default,){
final _that = this;
switch (_that) {
case _MerchantCounts():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantCounts value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantCounts() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int branches,  int employees,  int devices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantCounts() when $default != null:
return $default(_that.branches,_that.employees,_that.devices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int branches,  int employees,  int devices)  $default,) {final _that = this;
switch (_that) {
case _MerchantCounts():
return $default(_that.branches,_that.employees,_that.devices);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int branches,  int employees,  int devices)?  $default,) {final _that = this;
switch (_that) {
case _MerchantCounts() when $default != null:
return $default(_that.branches,_that.employees,_that.devices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantCounts implements MerchantCounts {
  const _MerchantCounts({this.branches = 0, this.employees = 0, this.devices = 0});
  factory _MerchantCounts.fromJson(Map<String, dynamic> json) => _$MerchantCountsFromJson(json);

@override@JsonKey() final  int branches;
@override@JsonKey() final  int employees;
@override@JsonKey() final  int devices;

/// Create a copy of MerchantCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantCountsCopyWith<_MerchantCounts> get copyWith => __$MerchantCountsCopyWithImpl<_MerchantCounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantCountsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantCounts&&(identical(other.branches, branches) || other.branches == branches)&&(identical(other.employees, employees) || other.employees == employees)&&(identical(other.devices, devices) || other.devices == devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branches,employees,devices);

@override
String toString() {
  return 'MerchantCounts(branches: $branches, employees: $employees, devices: $devices)';
}


}

/// @nodoc
abstract mixin class _$MerchantCountsCopyWith<$Res> implements $MerchantCountsCopyWith<$Res> {
  factory _$MerchantCountsCopyWith(_MerchantCounts value, $Res Function(_MerchantCounts) _then) = __$MerchantCountsCopyWithImpl;
@override @useResult
$Res call({
 int branches, int employees, int devices
});




}
/// @nodoc
class __$MerchantCountsCopyWithImpl<$Res>
    implements _$MerchantCountsCopyWith<$Res> {
  __$MerchantCountsCopyWithImpl(this._self, this._then);

  final _MerchantCounts _self;
  final $Res Function(_MerchantCounts) _then;

/// Create a copy of MerchantCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branches = null,Object? employees = null,Object? devices = null,}) {
  return _then(_MerchantCounts(
branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as int,employees: null == employees ? _self.employees : employees // ignore: cast_nullable_to_non_nullable
as int,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MerchantActivityItem {

 String get id;@JsonKey(name: 'activity_type') String get activityType; String get summary;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of MerchantActivityItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantActivityItemCopyWith<MerchantActivityItem> get copyWith => _$MerchantActivityItemCopyWithImpl<MerchantActivityItem>(this as MerchantActivityItem, _$identity);

  /// Serializes this MerchantActivityItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantActivityItem&&(identical(other.id, id) || other.id == id)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityType,summary,createdAt);

@override
String toString() {
  return 'MerchantActivityItem(id: $id, activityType: $activityType, summary: $summary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MerchantActivityItemCopyWith<$Res>  {
  factory $MerchantActivityItemCopyWith(MerchantActivityItem value, $Res Function(MerchantActivityItem) _then) = _$MerchantActivityItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'activity_type') String activityType, String summary,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$MerchantActivityItemCopyWithImpl<$Res>
    implements $MerchantActivityItemCopyWith<$Res> {
  _$MerchantActivityItemCopyWithImpl(this._self, this._then);

  final MerchantActivityItem _self;
  final $Res Function(MerchantActivityItem) _then;

/// Create a copy of MerchantActivityItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? activityType = null,Object? summary = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MerchantActivityItem].
extension MerchantActivityItemPatterns on MerchantActivityItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantActivityItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantActivityItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantActivityItem value)  $default,){
final _that = this;
switch (_that) {
case _MerchantActivityItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantActivityItem value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantActivityItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'activity_type')  String activityType,  String summary, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantActivityItem() when $default != null:
return $default(_that.id,_that.activityType,_that.summary,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'activity_type')  String activityType,  String summary, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MerchantActivityItem():
return $default(_that.id,_that.activityType,_that.summary,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'activity_type')  String activityType,  String summary, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MerchantActivityItem() when $default != null:
return $default(_that.id,_that.activityType,_that.summary,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantActivityItem implements MerchantActivityItem {
  const _MerchantActivityItem({required this.id, @JsonKey(name: 'activity_type') required this.activityType, required this.summary, @JsonKey(name: 'created_at') this.createdAt});
  factory _MerchantActivityItem.fromJson(Map<String, dynamic> json) => _$MerchantActivityItemFromJson(json);

@override final  String id;
@override@JsonKey(name: 'activity_type') final  String activityType;
@override final  String summary;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of MerchantActivityItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantActivityItemCopyWith<_MerchantActivityItem> get copyWith => __$MerchantActivityItemCopyWithImpl<_MerchantActivityItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantActivityItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantActivityItem&&(identical(other.id, id) || other.id == id)&&(identical(other.activityType, activityType) || other.activityType == activityType)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityType,summary,createdAt);

@override
String toString() {
  return 'MerchantActivityItem(id: $id, activityType: $activityType, summary: $summary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MerchantActivityItemCopyWith<$Res> implements $MerchantActivityItemCopyWith<$Res> {
  factory _$MerchantActivityItemCopyWith(_MerchantActivityItem value, $Res Function(_MerchantActivityItem) _then) = __$MerchantActivityItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'activity_type') String activityType, String summary,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$MerchantActivityItemCopyWithImpl<$Res>
    implements _$MerchantActivityItemCopyWith<$Res> {
  __$MerchantActivityItemCopyWithImpl(this._self, this._then);

  final _MerchantActivityItem _self;
  final $Res Function(_MerchantActivityItem) _then;

/// Create a copy of MerchantActivityItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? activityType = null,Object? summary = null,Object? createdAt = freezed,}) {
  return _then(_MerchantActivityItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityType: null == activityType ? _self.activityType : activityType // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MerchantNotificationItem {

 String get id; String get category; String get title; String get body;@JsonKey(name: 'is_read') bool get isRead;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of MerchantNotificationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantNotificationItemCopyWith<MerchantNotificationItem> get copyWith => _$MerchantNotificationItemCopyWithImpl<MerchantNotificationItem>(this as MerchantNotificationItem, _$identity);

  /// Serializes this MerchantNotificationItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantNotificationItem&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,title,body,isRead,createdAt);

@override
String toString() {
  return 'MerchantNotificationItem(id: $id, category: $category, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MerchantNotificationItemCopyWith<$Res>  {
  factory $MerchantNotificationItemCopyWith(MerchantNotificationItem value, $Res Function(MerchantNotificationItem) _then) = _$MerchantNotificationItemCopyWithImpl;
@useResult
$Res call({
 String id, String category, String title, String body,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$MerchantNotificationItemCopyWithImpl<$Res>
    implements $MerchantNotificationItemCopyWith<$Res> {
  _$MerchantNotificationItemCopyWithImpl(this._self, this._then);

  final MerchantNotificationItem _self;
  final $Res Function(MerchantNotificationItem) _then;

/// Create a copy of MerchantNotificationItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MerchantNotificationItem].
extension MerchantNotificationItemPatterns on MerchantNotificationItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantNotificationItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantNotificationItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantNotificationItem value)  $default,){
final _that = this;
switch (_that) {
case _MerchantNotificationItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantNotificationItem value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantNotificationItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  String title,  String body, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantNotificationItem() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.body,_that.isRead,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  String title,  String body, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MerchantNotificationItem():
return $default(_that.id,_that.category,_that.title,_that.body,_that.isRead,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  String title,  String body, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MerchantNotificationItem() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.body,_that.isRead,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantNotificationItem implements MerchantNotificationItem {
  const _MerchantNotificationItem({required this.id, required this.category, required this.title, this.body = '', @JsonKey(name: 'is_read') this.isRead = false, @JsonKey(name: 'created_at') this.createdAt});
  factory _MerchantNotificationItem.fromJson(Map<String, dynamic> json) => _$MerchantNotificationItemFromJson(json);

@override final  String id;
@override final  String category;
@override final  String title;
@override@JsonKey() final  String body;
@override@JsonKey(name: 'is_read') final  bool isRead;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of MerchantNotificationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantNotificationItemCopyWith<_MerchantNotificationItem> get copyWith => __$MerchantNotificationItemCopyWithImpl<_MerchantNotificationItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantNotificationItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantNotificationItem&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,title,body,isRead,createdAt);

@override
String toString() {
  return 'MerchantNotificationItem(id: $id, category: $category, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MerchantNotificationItemCopyWith<$Res> implements $MerchantNotificationItemCopyWith<$Res> {
  factory _$MerchantNotificationItemCopyWith(_MerchantNotificationItem value, $Res Function(_MerchantNotificationItem) _then) = __$MerchantNotificationItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, String title, String body,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$MerchantNotificationItemCopyWithImpl<$Res>
    implements _$MerchantNotificationItemCopyWith<$Res> {
  __$MerchantNotificationItemCopyWithImpl(this._self, this._then);

  final _MerchantNotificationItem _self;
  final $Res Function(_MerchantNotificationItem) _then;

/// Create a copy of MerchantNotificationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = freezed,}) {
  return _then(_MerchantNotificationItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MerchantDashboardSnapshot {

 String get businessStatus; String get verificationStatus; String get merchantHealth; MerchantCounts? get counts; List<MerchantNotificationItem> get notifications; List<MerchantActivityItem> get activityTimeline; List<Map<String, dynamic>> get pendingTasks; Map<String, dynamic> get placeholders; Map<String, dynamic> get systemStatus;
/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantDashboardSnapshotCopyWith<MerchantDashboardSnapshot> get copyWith => _$MerchantDashboardSnapshotCopyWithImpl<MerchantDashboardSnapshot>(this as MerchantDashboardSnapshot, _$identity);

  /// Serializes this MerchantDashboardSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantDashboardSnapshot&&(identical(other.businessStatus, businessStatus) || other.businessStatus == businessStatus)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.merchantHealth, merchantHealth) || other.merchantHealth == merchantHealth)&&(identical(other.counts, counts) || other.counts == counts)&&const DeepCollectionEquality().equals(other.notifications, notifications)&&const DeepCollectionEquality().equals(other.activityTimeline, activityTimeline)&&const DeepCollectionEquality().equals(other.pendingTasks, pendingTasks)&&const DeepCollectionEquality().equals(other.placeholders, placeholders)&&const DeepCollectionEquality().equals(other.systemStatus, systemStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessStatus,verificationStatus,merchantHealth,counts,const DeepCollectionEquality().hash(notifications),const DeepCollectionEquality().hash(activityTimeline),const DeepCollectionEquality().hash(pendingTasks),const DeepCollectionEquality().hash(placeholders),const DeepCollectionEquality().hash(systemStatus));

@override
String toString() {
  return 'MerchantDashboardSnapshot(businessStatus: $businessStatus, verificationStatus: $verificationStatus, merchantHealth: $merchantHealth, counts: $counts, notifications: $notifications, activityTimeline: $activityTimeline, pendingTasks: $pendingTasks, placeholders: $placeholders, systemStatus: $systemStatus)';
}


}

/// @nodoc
abstract mixin class $MerchantDashboardSnapshotCopyWith<$Res>  {
  factory $MerchantDashboardSnapshotCopyWith(MerchantDashboardSnapshot value, $Res Function(MerchantDashboardSnapshot) _then) = _$MerchantDashboardSnapshotCopyWithImpl;
@useResult
$Res call({
 String businessStatus, String verificationStatus, String merchantHealth, MerchantCounts? counts, List<MerchantNotificationItem> notifications, List<MerchantActivityItem> activityTimeline, List<Map<String, dynamic>> pendingTasks, Map<String, dynamic> placeholders, Map<String, dynamic> systemStatus
});


$MerchantCountsCopyWith<$Res>? get counts;

}
/// @nodoc
class _$MerchantDashboardSnapshotCopyWithImpl<$Res>
    implements $MerchantDashboardSnapshotCopyWith<$Res> {
  _$MerchantDashboardSnapshotCopyWithImpl(this._self, this._then);

  final MerchantDashboardSnapshot _self;
  final $Res Function(MerchantDashboardSnapshot) _then;

/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessStatus = null,Object? verificationStatus = null,Object? merchantHealth = null,Object? counts = freezed,Object? notifications = null,Object? activityTimeline = null,Object? pendingTasks = null,Object? placeholders = null,Object? systemStatus = null,}) {
  return _then(_self.copyWith(
businessStatus: null == businessStatus ? _self.businessStatus : businessStatus // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as String,merchantHealth: null == merchantHealth ? _self.merchantHealth : merchantHealth // ignore: cast_nullable_to_non_nullable
as String,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as MerchantCounts?,notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as List<MerchantNotificationItem>,activityTimeline: null == activityTimeline ? _self.activityTimeline : activityTimeline // ignore: cast_nullable_to_non_nullable
as List<MerchantActivityItem>,pendingTasks: null == pendingTasks ? _self.pendingTasks : pendingTasks // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,placeholders: null == placeholders ? _self.placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,systemStatus: null == systemStatus ? _self.systemStatus : systemStatus // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MerchantCountsCopyWith<$Res>? get counts {
    if (_self.counts == null) {
    return null;
  }

  return $MerchantCountsCopyWith<$Res>(_self.counts!, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}


/// Adds pattern-matching-related methods to [MerchantDashboardSnapshot].
extension MerchantDashboardSnapshotPatterns on MerchantDashboardSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantDashboardSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantDashboardSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantDashboardSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessStatus,  String verificationStatus,  String merchantHealth,  MerchantCounts? counts,  List<MerchantNotificationItem> notifications,  List<MerchantActivityItem> activityTimeline,  List<Map<String, dynamic>> pendingTasks,  Map<String, dynamic> placeholders,  Map<String, dynamic> systemStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot() when $default != null:
return $default(_that.businessStatus,_that.verificationStatus,_that.merchantHealth,_that.counts,_that.notifications,_that.activityTimeline,_that.pendingTasks,_that.placeholders,_that.systemStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessStatus,  String verificationStatus,  String merchantHealth,  MerchantCounts? counts,  List<MerchantNotificationItem> notifications,  List<MerchantActivityItem> activityTimeline,  List<Map<String, dynamic>> pendingTasks,  Map<String, dynamic> placeholders,  Map<String, dynamic> systemStatus)  $default,) {final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot():
return $default(_that.businessStatus,_that.verificationStatus,_that.merchantHealth,_that.counts,_that.notifications,_that.activityTimeline,_that.pendingTasks,_that.placeholders,_that.systemStatus);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessStatus,  String verificationStatus,  String merchantHealth,  MerchantCounts? counts,  List<MerchantNotificationItem> notifications,  List<MerchantActivityItem> activityTimeline,  List<Map<String, dynamic>> pendingTasks,  Map<String, dynamic> placeholders,  Map<String, dynamic> systemStatus)?  $default,) {final _that = this;
switch (_that) {
case _MerchantDashboardSnapshot() when $default != null:
return $default(_that.businessStatus,_that.verificationStatus,_that.merchantHealth,_that.counts,_that.notifications,_that.activityTimeline,_that.pendingTasks,_that.placeholders,_that.systemStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantDashboardSnapshot implements MerchantDashboardSnapshot {
  const _MerchantDashboardSnapshot({this.businessStatus = '', this.verificationStatus = '', this.merchantHealth = '', this.counts, final  List<MerchantNotificationItem> notifications = const [], final  List<MerchantActivityItem> activityTimeline = const [], final  List<Map<String, dynamic>> pendingTasks = const [], final  Map<String, dynamic> placeholders = const {}, final  Map<String, dynamic> systemStatus = const {}}): _notifications = notifications,_activityTimeline = activityTimeline,_pendingTasks = pendingTasks,_placeholders = placeholders,_systemStatus = systemStatus;
  factory _MerchantDashboardSnapshot.fromJson(Map<String, dynamic> json) => _$MerchantDashboardSnapshotFromJson(json);

@override@JsonKey() final  String businessStatus;
@override@JsonKey() final  String verificationStatus;
@override@JsonKey() final  String merchantHealth;
@override final  MerchantCounts? counts;
 final  List<MerchantNotificationItem> _notifications;
@override@JsonKey() List<MerchantNotificationItem> get notifications {
  if (_notifications is EqualUnmodifiableListView) return _notifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notifications);
}

 final  List<MerchantActivityItem> _activityTimeline;
@override@JsonKey() List<MerchantActivityItem> get activityTimeline {
  if (_activityTimeline is EqualUnmodifiableListView) return _activityTimeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activityTimeline);
}

 final  List<Map<String, dynamic>> _pendingTasks;
@override@JsonKey() List<Map<String, dynamic>> get pendingTasks {
  if (_pendingTasks is EqualUnmodifiableListView) return _pendingTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingTasks);
}

 final  Map<String, dynamic> _placeholders;
@override@JsonKey() Map<String, dynamic> get placeholders {
  if (_placeholders is EqualUnmodifiableMapView) return _placeholders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_placeholders);
}

 final  Map<String, dynamic> _systemStatus;
@override@JsonKey() Map<String, dynamic> get systemStatus {
  if (_systemStatus is EqualUnmodifiableMapView) return _systemStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_systemStatus);
}


/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantDashboardSnapshotCopyWith<_MerchantDashboardSnapshot> get copyWith => __$MerchantDashboardSnapshotCopyWithImpl<_MerchantDashboardSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantDashboardSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantDashboardSnapshot&&(identical(other.businessStatus, businessStatus) || other.businessStatus == businessStatus)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.merchantHealth, merchantHealth) || other.merchantHealth == merchantHealth)&&(identical(other.counts, counts) || other.counts == counts)&&const DeepCollectionEquality().equals(other._notifications, _notifications)&&const DeepCollectionEquality().equals(other._activityTimeline, _activityTimeline)&&const DeepCollectionEquality().equals(other._pendingTasks, _pendingTasks)&&const DeepCollectionEquality().equals(other._placeholders, _placeholders)&&const DeepCollectionEquality().equals(other._systemStatus, _systemStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,businessStatus,verificationStatus,merchantHealth,counts,const DeepCollectionEquality().hash(_notifications),const DeepCollectionEquality().hash(_activityTimeline),const DeepCollectionEquality().hash(_pendingTasks),const DeepCollectionEquality().hash(_placeholders),const DeepCollectionEquality().hash(_systemStatus));

@override
String toString() {
  return 'MerchantDashboardSnapshot(businessStatus: $businessStatus, verificationStatus: $verificationStatus, merchantHealth: $merchantHealth, counts: $counts, notifications: $notifications, activityTimeline: $activityTimeline, pendingTasks: $pendingTasks, placeholders: $placeholders, systemStatus: $systemStatus)';
}


}

/// @nodoc
abstract mixin class _$MerchantDashboardSnapshotCopyWith<$Res> implements $MerchantDashboardSnapshotCopyWith<$Res> {
  factory _$MerchantDashboardSnapshotCopyWith(_MerchantDashboardSnapshot value, $Res Function(_MerchantDashboardSnapshot) _then) = __$MerchantDashboardSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String businessStatus, String verificationStatus, String merchantHealth, MerchantCounts? counts, List<MerchantNotificationItem> notifications, List<MerchantActivityItem> activityTimeline, List<Map<String, dynamic>> pendingTasks, Map<String, dynamic> placeholders, Map<String, dynamic> systemStatus
});


@override $MerchantCountsCopyWith<$Res>? get counts;

}
/// @nodoc
class __$MerchantDashboardSnapshotCopyWithImpl<$Res>
    implements _$MerchantDashboardSnapshotCopyWith<$Res> {
  __$MerchantDashboardSnapshotCopyWithImpl(this._self, this._then);

  final _MerchantDashboardSnapshot _self;
  final $Res Function(_MerchantDashboardSnapshot) _then;

/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessStatus = null,Object? verificationStatus = null,Object? merchantHealth = null,Object? counts = freezed,Object? notifications = null,Object? activityTimeline = null,Object? pendingTasks = null,Object? placeholders = null,Object? systemStatus = null,}) {
  return _then(_MerchantDashboardSnapshot(
businessStatus: null == businessStatus ? _self.businessStatus : businessStatus // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as String,merchantHealth: null == merchantHealth ? _self.merchantHealth : merchantHealth // ignore: cast_nullable_to_non_nullable
as String,counts: freezed == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as MerchantCounts?,notifications: null == notifications ? _self._notifications : notifications // ignore: cast_nullable_to_non_nullable
as List<MerchantNotificationItem>,activityTimeline: null == activityTimeline ? _self._activityTimeline : activityTimeline // ignore: cast_nullable_to_non_nullable
as List<MerchantActivityItem>,pendingTasks: null == pendingTasks ? _self._pendingTasks : pendingTasks // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,placeholders: null == placeholders ? _self._placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,systemStatus: null == systemStatus ? _self._systemStatus : systemStatus // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of MerchantDashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MerchantCountsCopyWith<$Res>? get counts {
    if (_self.counts == null) {
    return null;
  }

  return $MerchantCountsCopyWith<$Res>(_self.counts!, (value) {
    return _then(_self.copyWith(counts: value));
  });
}
}


/// @nodoc
mixin _$MerchantSettingsSnapshot {

 String get language; String get currency; String get timezone;@JsonKey(name: 'payment_preferences') Map<String, dynamic> get paymentPreferences;@JsonKey(name: 'receipt_branding') Map<String, dynamic> get receiptBranding;@JsonKey(name: 'tax_settings') Map<String, dynamic> get taxSettings;
/// Create a copy of MerchantSettingsSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MerchantSettingsSnapshotCopyWith<MerchantSettingsSnapshot> get copyWith => _$MerchantSettingsSnapshotCopyWithImpl<MerchantSettingsSnapshot>(this as MerchantSettingsSnapshot, _$identity);

  /// Serializes this MerchantSettingsSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MerchantSettingsSnapshot&&(identical(other.language, language) || other.language == language)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other.paymentPreferences, paymentPreferences)&&const DeepCollectionEquality().equals(other.receiptBranding, receiptBranding)&&const DeepCollectionEquality().equals(other.taxSettings, taxSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,currency,timezone,const DeepCollectionEquality().hash(paymentPreferences),const DeepCollectionEquality().hash(receiptBranding),const DeepCollectionEquality().hash(taxSettings));

@override
String toString() {
  return 'MerchantSettingsSnapshot(language: $language, currency: $currency, timezone: $timezone, paymentPreferences: $paymentPreferences, receiptBranding: $receiptBranding, taxSettings: $taxSettings)';
}


}

/// @nodoc
abstract mixin class $MerchantSettingsSnapshotCopyWith<$Res>  {
  factory $MerchantSettingsSnapshotCopyWith(MerchantSettingsSnapshot value, $Res Function(MerchantSettingsSnapshot) _then) = _$MerchantSettingsSnapshotCopyWithImpl;
@useResult
$Res call({
 String language, String currency, String timezone,@JsonKey(name: 'payment_preferences') Map<String, dynamic> paymentPreferences,@JsonKey(name: 'receipt_branding') Map<String, dynamic> receiptBranding,@JsonKey(name: 'tax_settings') Map<String, dynamic> taxSettings
});




}
/// @nodoc
class _$MerchantSettingsSnapshotCopyWithImpl<$Res>
    implements $MerchantSettingsSnapshotCopyWith<$Res> {
  _$MerchantSettingsSnapshotCopyWithImpl(this._self, this._then);

  final MerchantSettingsSnapshot _self;
  final $Res Function(MerchantSettingsSnapshot) _then;

/// Create a copy of MerchantSettingsSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? currency = null,Object? timezone = null,Object? paymentPreferences = null,Object? receiptBranding = null,Object? taxSettings = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,paymentPreferences: null == paymentPreferences ? _self.paymentPreferences : paymentPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,receiptBranding: null == receiptBranding ? _self.receiptBranding : receiptBranding // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,taxSettings: null == taxSettings ? _self.taxSettings : taxSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [MerchantSettingsSnapshot].
extension MerchantSettingsSnapshotPatterns on MerchantSettingsSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MerchantSettingsSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MerchantSettingsSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MerchantSettingsSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  String currency,  String timezone, @JsonKey(name: 'payment_preferences')  Map<String, dynamic> paymentPreferences, @JsonKey(name: 'receipt_branding')  Map<String, dynamic> receiptBranding, @JsonKey(name: 'tax_settings')  Map<String, dynamic> taxSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot() when $default != null:
return $default(_that.language,_that.currency,_that.timezone,_that.paymentPreferences,_that.receiptBranding,_that.taxSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  String currency,  String timezone, @JsonKey(name: 'payment_preferences')  Map<String, dynamic> paymentPreferences, @JsonKey(name: 'receipt_branding')  Map<String, dynamic> receiptBranding, @JsonKey(name: 'tax_settings')  Map<String, dynamic> taxSettings)  $default,) {final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot():
return $default(_that.language,_that.currency,_that.timezone,_that.paymentPreferences,_that.receiptBranding,_that.taxSettings);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  String currency,  String timezone, @JsonKey(name: 'payment_preferences')  Map<String, dynamic> paymentPreferences, @JsonKey(name: 'receipt_branding')  Map<String, dynamic> receiptBranding, @JsonKey(name: 'tax_settings')  Map<String, dynamic> taxSettings)?  $default,) {final _that = this;
switch (_that) {
case _MerchantSettingsSnapshot() when $default != null:
return $default(_that.language,_that.currency,_that.timezone,_that.paymentPreferences,_that.receiptBranding,_that.taxSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MerchantSettingsSnapshot implements MerchantSettingsSnapshot {
  const _MerchantSettingsSnapshot({this.language = 'sw', this.currency = 'TZS', this.timezone = 'Africa/Dar_es_Salaam', @JsonKey(name: 'payment_preferences') final  Map<String, dynamic> paymentPreferences = const {}, @JsonKey(name: 'receipt_branding') final  Map<String, dynamic> receiptBranding = const {}, @JsonKey(name: 'tax_settings') final  Map<String, dynamic> taxSettings = const {}}): _paymentPreferences = paymentPreferences,_receiptBranding = receiptBranding,_taxSettings = taxSettings;
  factory _MerchantSettingsSnapshot.fromJson(Map<String, dynamic> json) => _$MerchantSettingsSnapshotFromJson(json);

@override@JsonKey() final  String language;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String timezone;
 final  Map<String, dynamic> _paymentPreferences;
@override@JsonKey(name: 'payment_preferences') Map<String, dynamic> get paymentPreferences {
  if (_paymentPreferences is EqualUnmodifiableMapView) return _paymentPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_paymentPreferences);
}

 final  Map<String, dynamic> _receiptBranding;
@override@JsonKey(name: 'receipt_branding') Map<String, dynamic> get receiptBranding {
  if (_receiptBranding is EqualUnmodifiableMapView) return _receiptBranding;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_receiptBranding);
}

 final  Map<String, dynamic> _taxSettings;
@override@JsonKey(name: 'tax_settings') Map<String, dynamic> get taxSettings {
  if (_taxSettings is EqualUnmodifiableMapView) return _taxSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_taxSettings);
}


/// Create a copy of MerchantSettingsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MerchantSettingsSnapshotCopyWith<_MerchantSettingsSnapshot> get copyWith => __$MerchantSettingsSnapshotCopyWithImpl<_MerchantSettingsSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MerchantSettingsSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MerchantSettingsSnapshot&&(identical(other.language, language) || other.language == language)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other._paymentPreferences, _paymentPreferences)&&const DeepCollectionEquality().equals(other._receiptBranding, _receiptBranding)&&const DeepCollectionEquality().equals(other._taxSettings, _taxSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,currency,timezone,const DeepCollectionEquality().hash(_paymentPreferences),const DeepCollectionEquality().hash(_receiptBranding),const DeepCollectionEquality().hash(_taxSettings));

@override
String toString() {
  return 'MerchantSettingsSnapshot(language: $language, currency: $currency, timezone: $timezone, paymentPreferences: $paymentPreferences, receiptBranding: $receiptBranding, taxSettings: $taxSettings)';
}


}

/// @nodoc
abstract mixin class _$MerchantSettingsSnapshotCopyWith<$Res> implements $MerchantSettingsSnapshotCopyWith<$Res> {
  factory _$MerchantSettingsSnapshotCopyWith(_MerchantSettingsSnapshot value, $Res Function(_MerchantSettingsSnapshot) _then) = __$MerchantSettingsSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String language, String currency, String timezone,@JsonKey(name: 'payment_preferences') Map<String, dynamic> paymentPreferences,@JsonKey(name: 'receipt_branding') Map<String, dynamic> receiptBranding,@JsonKey(name: 'tax_settings') Map<String, dynamic> taxSettings
});




}
/// @nodoc
class __$MerchantSettingsSnapshotCopyWithImpl<$Res>
    implements _$MerchantSettingsSnapshotCopyWith<$Res> {
  __$MerchantSettingsSnapshotCopyWithImpl(this._self, this._then);

  final _MerchantSettingsSnapshot _self;
  final $Res Function(_MerchantSettingsSnapshot) _then;

/// Create a copy of MerchantSettingsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? currency = null,Object? timezone = null,Object? paymentPreferences = null,Object? receiptBranding = null,Object? taxSettings = null,}) {
  return _then(_MerchantSettingsSnapshot(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,paymentPreferences: null == paymentPreferences ? _self._paymentPreferences : paymentPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,receiptBranding: null == receiptBranding ? _self._receiptBranding : receiptBranding // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,taxSettings: null == taxSettings ? _self._taxSettings : taxSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
