// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeatherModelImpl _$$WeatherModelImplFromJson(Map<String, dynamic> json) =>
    _$WeatherModelImpl(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      visibility: (json['visibility'] as num).toInt(),
      pressure: (json['pressure'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$WeatherModelImplToJson(_$WeatherModelImpl instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'feelsLike': instance.feelsLike,
      'humidity': instance.humidity,
      'description': instance.description,
      'icon': instance.icon,
      'city': instance.city,
      'country': instance.country,
      'windSpeed': instance.windSpeed,
      'visibility': instance.visibility,
      'pressure': instance.pressure,
    };
