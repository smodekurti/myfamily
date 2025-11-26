// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WeatherModel _$WeatherModelFromJson(Map<String, dynamic> json) {
  return _WeatherModel.fromJson(json);
}

/// @nodoc
mixin _$WeatherModel {
  double get temperature => throw _privateConstructorUsedError;
  double get feelsLike => throw _privateConstructorUsedError;
  int get humidity => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  double get windSpeed => throw _privateConstructorUsedError;
  int get visibility => throw _privateConstructorUsedError;
  double? get pressure => throw _privateConstructorUsedError;

  /// Serializes this WeatherModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeatherModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeatherModelCopyWith<WeatherModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeatherModelCopyWith<$Res> {
  factory $WeatherModelCopyWith(
    WeatherModel value,
    $Res Function(WeatherModel) then,
  ) = _$WeatherModelCopyWithImpl<$Res, WeatherModel>;
  @useResult
  $Res call({
    double temperature,
    double feelsLike,
    int humidity,
    String description,
    String icon,
    String city,
    String country,
    double windSpeed,
    int visibility,
    double? pressure,
  });
}

/// @nodoc
class _$WeatherModelCopyWithImpl<$Res, $Val extends WeatherModel>
    implements $WeatherModelCopyWith<$Res> {
  _$WeatherModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeatherModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
    Object? feelsLike = null,
    Object? humidity = null,
    Object? description = null,
    Object? icon = null,
    Object? city = null,
    Object? country = null,
    Object? windSpeed = null,
    Object? visibility = null,
    Object? pressure = freezed,
  }) {
    return _then(
      _value.copyWith(
            temperature: null == temperature
                ? _value.temperature
                : temperature // ignore: cast_nullable_to_non_nullable
                      as double,
            feelsLike: null == feelsLike
                ? _value.feelsLike
                : feelsLike // ignore: cast_nullable_to_non_nullable
                      as double,
            humidity: null == humidity
                ? _value.humidity
                : humidity // ignore: cast_nullable_to_non_nullable
                      as int,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            windSpeed: null == windSpeed
                ? _value.windSpeed
                : windSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as int,
            pressure: freezed == pressure
                ? _value.pressure
                : pressure // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WeatherModelImplCopyWith<$Res>
    implements $WeatherModelCopyWith<$Res> {
  factory _$$WeatherModelImplCopyWith(
    _$WeatherModelImpl value,
    $Res Function(_$WeatherModelImpl) then,
  ) = __$$WeatherModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double temperature,
    double feelsLike,
    int humidity,
    String description,
    String icon,
    String city,
    String country,
    double windSpeed,
    int visibility,
    double? pressure,
  });
}

/// @nodoc
class __$$WeatherModelImplCopyWithImpl<$Res>
    extends _$WeatherModelCopyWithImpl<$Res, _$WeatherModelImpl>
    implements _$$WeatherModelImplCopyWith<$Res> {
  __$$WeatherModelImplCopyWithImpl(
    _$WeatherModelImpl _value,
    $Res Function(_$WeatherModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WeatherModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = null,
    Object? feelsLike = null,
    Object? humidity = null,
    Object? description = null,
    Object? icon = null,
    Object? city = null,
    Object? country = null,
    Object? windSpeed = null,
    Object? visibility = null,
    Object? pressure = freezed,
  }) {
    return _then(
      _$WeatherModelImpl(
        temperature: null == temperature
            ? _value.temperature
            : temperature // ignore: cast_nullable_to_non_nullable
                  as double,
        feelsLike: null == feelsLike
            ? _value.feelsLike
            : feelsLike // ignore: cast_nullable_to_non_nullable
                  as double,
        humidity: null == humidity
            ? _value.humidity
            : humidity // ignore: cast_nullable_to_non_nullable
                  as int,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        windSpeed: null == windSpeed
            ? _value.windSpeed
            : windSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as int,
        pressure: freezed == pressure
            ? _value.pressure
            : pressure // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WeatherModelImpl implements _WeatherModel {
  const _$WeatherModelImpl({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.city,
    required this.country,
    required this.windSpeed,
    required this.visibility,
    required this.pressure,
  });

  factory _$WeatherModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeatherModelImplFromJson(json);

  @override
  final double temperature;
  @override
  final double feelsLike;
  @override
  final int humidity;
  @override
  final String description;
  @override
  final String icon;
  @override
  final String city;
  @override
  final String country;
  @override
  final double windSpeed;
  @override
  final int visibility;
  @override
  final double? pressure;

  @override
  String toString() {
    return 'WeatherModel(temperature: $temperature, feelsLike: $feelsLike, humidity: $humidity, description: $description, icon: $icon, city: $city, country: $country, windSpeed: $windSpeed, visibility: $visibility, pressure: $pressure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeatherModelImpl &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.feelsLike, feelsLike) ||
                other.feelsLike == feelsLike) &&
            (identical(other.humidity, humidity) ||
                other.humidity == humidity) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.windSpeed, windSpeed) ||
                other.windSpeed == windSpeed) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.pressure, pressure) ||
                other.pressure == pressure));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    temperature,
    feelsLike,
    humidity,
    description,
    icon,
    city,
    country,
    windSpeed,
    visibility,
    pressure,
  );

  /// Create a copy of WeatherModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeatherModelImplCopyWith<_$WeatherModelImpl> get copyWith =>
      __$$WeatherModelImplCopyWithImpl<_$WeatherModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeatherModelImplToJson(this);
  }
}

abstract class _WeatherModel implements WeatherModel {
  const factory _WeatherModel({
    required final double temperature,
    required final double feelsLike,
    required final int humidity,
    required final String description,
    required final String icon,
    required final String city,
    required final String country,
    required final double windSpeed,
    required final int visibility,
    required final double? pressure,
  }) = _$WeatherModelImpl;

  factory _WeatherModel.fromJson(Map<String, dynamic> json) =
      _$WeatherModelImpl.fromJson;

  @override
  double get temperature;
  @override
  double get feelsLike;
  @override
  int get humidity;
  @override
  String get description;
  @override
  String get icon;
  @override
  String get city;
  @override
  String get country;
  @override
  double get windSpeed;
  @override
  int get visibility;
  @override
  double? get pressure;

  /// Create a copy of WeatherModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeatherModelImplCopyWith<_$WeatherModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
