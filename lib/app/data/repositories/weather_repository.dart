import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/weather_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/weather_config.dart';

class WeatherRepository {
  final Logger _logger = Logger();

  /// Get weather for a location (by city name, zipcode, or coordinates)
  /// Uses National Weather Service (NWS) API - Free, no API key required
  /// Note: NWS API only covers US territories
  Future<WeatherModel?> getWeather({
    String? cityName,
    String? zipcode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      double? lat = latitude;
      double? lon = longitude;
      String? city = cityName;

      // If zipcode provided, get coordinates first
      if (zipcode != null && zipcode.isNotEmpty) {
        final coords = await _getCoordinatesForZipcode(zipcode);
        if (coords != null) {
          lat = coords['latitude'] as double;
          lon = coords['longitude'] as double;
          city = coords['name'] as String?;
        } else {
          return null;
        }
      }
      // If city name provided, get coordinates first
      else if (cityName != null && cityName.isNotEmpty) {
        final coords = await _getCoordinatesForLocation(cityName);
        if (coords != null) {
          lat = coords['latitude'] as double;
          lon = coords['longitude'] as double;
          city = coords['name'] as String? ?? cityName;
        } else {
          return null;
        }
      }
      // If coordinates provided, use them directly
      else if (lat != null && lon != null) {
        // Coordinates already set
        // Try to get city name from coordinates if not provided
        if (city == null || city.isEmpty) {
          final reverseGeoCity = await _getCityNameFromCoordinates(lat, lon);
          if (reverseGeoCity != null) {
            city = reverseGeoCity;
          }
        }
      }
      // Fallback to default location
      else {
        lat = 37.7749; // San Francisco default
        lon = -122.4194;
        city = AppConstants.defaultWeatherCity;
      }

      // At this point, lat and lon are guaranteed to be non-null due to fallback
      // Get weather from Open-Meteo API (Global coverage)
      return await _getWeatherFromOpenMeteo(
        latitude: lat,
        longitude: lon,
        city: city ?? 'Unknown Location',
      );
    } catch (e, stackTrace) {
      _logger.e('Get weather error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get city name from coordinates using BigDataCloud API (Reverse Geocoding)
  Future<String?> _getCityNameFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '${WeatherConfig.reverseGeocodingUrl}?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      _logger.d('Reverse geocoding URL: $url');
      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Prioritize locality (e.g. "Buffalo Grove") over city (e.g. "Chicago")
        // BigDataCloud often puts the metro area in 'city' and the specific town in 'locality'
        String? locality = data['locality'] as String?;
        String? city = data['city'] as String?;

        String cityName = '';
        if (locality != null && locality.isNotEmpty) {
          cityName = locality;
        } else if (city != null && city.isNotEmpty) {
          cityName = city;
        }

        final state = data['principalSubdivision'] as String?;
        final stateCode =
            data['principalSubdivisionCode'] as String?; // e.g. "US-IL"
        final countryCode = data['countryCode'] as String?;

        if (cityName.isNotEmpty) {
          // For US, try to show "City, State"
          if (countryCode == 'US') {
            // Try to use state abbreviation (e.g. "IL") from "US-IL"
            if (stateCode != null && stateCode.startsWith('US-')) {
              final shortState = stateCode.split('-').last;
              return '$cityName, $shortState';
            }
            // Fallback to full state name
            if (state != null && state.isNotEmpty) {
              return '$cityName, $state';
            }
          }
          return cityName;
        }
      } else {
        _logger.w(
          'Reverse geocoding failed with status: ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      _logger.w('Reverse geocoding failed: $e');
      return null;
    }
  }

  /// Get coordinates for a zipcode using Zippopotam API (zipcode-specific, free, no key)
  Future<Map<String, dynamic>?> _getCoordinatesForZipcode(
    String zipcode,
  ) async {
    try {
      // Clean zipcode (remove extension if present)
      final cleanZipcode = zipcode.trim().split('-').first;

      // Zippopotam API - specifically for US zipcodes
      final url = Uri.parse(
        '${WeatherConfig.zipcodeGeocodingUrl}/$cleanZipcode',
      );

      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['places'] as List?;

        if (places != null && places.isNotEmpty) {
          // Use the first place (usually the primary city for the zipcode)
          final place = places.first as Map<String, dynamic>;

          final latitude = double.tryParse(place['latitude'] as String? ?? '');
          final longitude = double.tryParse(
            place['longitude'] as String? ?? '',
          );

          if (latitude != null && longitude != null) {
            final city = place['place name'] as String? ?? '';
            final state = place['state'] as String? ?? '';
            final stateAbbreviation =
                place['state abbreviation'] as String? ?? state;

            return {
              'latitude': latitude,
              'longitude': longitude,
              'name': city.isNotEmpty
                  ? '$city, $stateAbbreviation'
                  : 'Zipcode $cleanZipcode',
              'country': 'US',
            };
          }
        }
      } else if (response.statusCode == 404) {
        // Zipcode not found in Zippopotam (might be international or invalid)
        // Fall through to Open-Meteo fallback
      }

      // Fallback to Open-Meteo geocoding if Zippopotam fails
      return await _getCoordinatesFromOpenMeteo(zipcode, isZipcode: true);
    } catch (e, stackTrace) {
      _logger.e(
        'Get coordinates for zipcode error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to Open-Meteo
      return await _getCoordinatesFromOpenMeteo(zipcode, isZipcode: true);
    }
  }

  /// Get coordinates for a city name using Open-Meteo Geocoding API
  Future<Map<String, dynamic>?> _getCoordinatesForLocation(
    String location,
  ) async {
    // Clean the location string - extract city name from "City, State" format
    // Handles both state abbreviations (e.g., "Los Angeles, CA") and full names (e.g., "Los Angeles, California")
    String cleanLocation = location.trim();

    // Extract city name by removing everything after the first comma
    // This handles both "City, State" and "City, State, Country" formats
    if (cleanLocation.contains(',')) {
      cleanLocation = cleanLocation.split(',').first.trim();
    }

    // If location is empty after cleaning, use original
    if (cleanLocation.isEmpty) {
      cleanLocation = location.trim();
    }

    // Try multiple search strategies for better results
    // Strategy 1: Try just the city name
    var result = await _getCoordinatesFromOpenMeteo(
      cleanLocation,
      isZipcode: false,
    );
    if (result != null) {
      return result;
    }

    // Strategy 2: Try with ", US" suffix for US cities
    result = await _getCoordinatesFromOpenMeteo(
      '$cleanLocation, US',
      isZipcode: false,
    );
    if (result != null) {
      return result;
    }

    // Strategy 3: Try original location if it was different
    if (cleanLocation != location.trim()) {
      result = await _getCoordinatesFromOpenMeteo(
        location.trim(),
        isZipcode: false,
      );
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  /// Get coordinates using Open-Meteo Geocoding API (fallback for city names)
  Future<Map<String, dynamic>?> _getCoordinatesFromOpenMeteo(
    String location, {
    bool isZipcode = false,
  }) async {
    try {
      // For zipcodes, try searching with "US" prefix to improve results
      // For city names, search as-is (already cleaned in _getCoordinatesForLocation)
      final searchQuery = isZipcode ? '$location, US' : location;
      final url = Uri.parse(
        '${WeatherConfig.openMeteoGeocodingUrl}/search?name=${Uri.encodeComponent(searchQuery)}&count=10&language=en&format=json',
      );

      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          // For US locations, prefer US results
          Map<String, dynamic>? bestResult;

          for (var result in results) {
            final resultMap = result as Map<String, dynamic>;
            final country = resultMap['country'] as String? ?? '';

            // Prefer US results for NWS API
            if (country == 'US') {
              bestResult = resultMap;
              break;
            }
          }

          // If no US result, use first result
          bestResult ??= results.first as Map<String, dynamic>;

          final name = bestResult['name'] as String? ?? location;
          final admin1 = bestResult['admin1'] as String?; // State/Province
          final country = bestResult['country'] as String? ?? 'US';

          // For display, use the format: "City, State" if state is available
          final displayName = admin1 != null ? '$name, $admin1' : name;

          return {
            'latitude': bestResult['latitude'] as double,
            'longitude': bestResult['longitude'] as double,
            'name': displayName,
            'country': country,
          };
        }
      } else {
        // No results found
      }

      return null;
    } catch (e, stackTrace) {
      _logger.e(
        'Open-Meteo geocoding error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get weather from Open-Meteo API (Global coverage)
  Future<WeatherModel?> _getWeatherFromOpenMeteo({
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    try {
      final url = Uri.parse(
        '${WeatherConfig.openMeteoWeatherUrl}/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch',
      );

      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode != 200) {
        _logger.e(
          'Open-Meteo API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }

      final data = json.decode(response.body);
      final current = data['current'] as Map<String, dynamic>?;

      if (current == null) {
        _logger.e('Invalid Open-Meteo response: missing current weather data');
        return null;
      }

      return _parseOpenMeteoWeatherData(current: current, city: city);
    } catch (e, stackTrace) {
      _logger.e(
        'Get weather from Open-Meteo error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Parse weather data from Open-Meteo API response
  WeatherModel _parseOpenMeteoWeatherData({
    required Map<String, dynamic> current,
    required String city,
  }) {
    final temperature = (current['temperature_2m'] as num).toDouble();
    final feelsLike = (current['apparent_temperature'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toInt();
    final windSpeed = (current['wind_speed_10m'] as num).toDouble();
    final weatherCode = (current['weather_code'] as num).toInt();

    final weatherInfo = _getWeatherInfoFromCode(weatherCode);

    return WeatherModel(
      temperature: temperature,
      feelsLike: feelsLike,
      humidity: humidity,
      description: weatherInfo.description,
      icon: weatherInfo.icon,
      city: city,
      country:
          '', // Country is not provided in weather response, but we have it from geocoding
      windSpeed: windSpeed,
      visibility:
          10, // Open-Meteo doesn't provide visibility in basic free tier
      pressure: null,
    );
  }

  /// Map Open-Meteo WMO weather codes to description and icon
  ({String description, String icon}) _getWeatherInfoFromCode(int code) {
    // WMO Weather interpretation codes (WW)
    // Code	Description
    // 0	Clear sky
    // 1, 2, 3	Mainly clear, partly cloudy, and overcast
    // 45, 48	Fog and depositing rime fog
    // 51, 53, 55	Drizzle: Light, moderate, and dense intensity
    // 56, 57	Freezing Drizzle: Light and dense intensity
    // 61, 63, 65	Rain: Slight, moderate and heavy intensity
    // 66, 67	Freezing Rain: Light and heavy intensity
    // 71, 73, 75	Snow fall: Slight, moderate, and heavy intensity
    // 77	Snow grains
    // 80, 81, 82	Rain showers: Slight, moderate, and violent
    // 85, 86	Snow showers slight and heavy
    // 95 *	Thunderstorm: Slight or moderate
    // 96, 99 *	Thunderstorm with slight and heavy hail

    switch (code) {
      case 0:
        return (description: 'Clear sky', icon: '01d');
      case 1:
        return (description: 'Mainly clear', icon: '02d');
      case 2:
        return (description: 'Partly cloudy', icon: '02d');
      case 3:
        return (description: 'Overcast', icon: '04d');
      case 45:
      case 48:
        return (description: 'Fog', icon: '50d');
      case 51:
      case 53:
      case 55:
        return (description: 'Drizzle', icon: '09d');
      case 56:
      case 57:
        return (description: 'Freezing Drizzle', icon: '09d');
      case 61:
      case 63:
      case 65:
        return (description: 'Rain', icon: '10d');
      case 66:
      case 67:
        return (description: 'Freezing Rain', icon: '13d');
      case 71:
      case 73:
      case 75:
      case 77:
        return (description: 'Snow', icon: '13d');
      case 80:
      case 81:
      case 82:
        return (description: 'Rain showers', icon: '09d');
      case 85:
      case 86:
        return (description: 'Snow showers', icon: '13d');
      case 95:
      case 96:
      case 99:
        return (description: 'Thunderstorm', icon: '11d');
      default:
        return (description: 'Unknown', icon: '01d');
    }
  }
}
