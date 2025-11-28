import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/weather_model.dart';
import '../../core/constants/app_constants.dart';

class WeatherRepository {
  final Logger _logger = Logger();
  
  // Open-Meteo API - Free, no API key required
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  static const String _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1';
  
  /// Get weather for a location (by city name, zipcode, or coordinates)
  /// Uses Open-Meteo free API - no API key required
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
      String? country = '';

      // If city name or zipcode provided, get coordinates first
      if ((cityName != null && cityName.isNotEmpty || zipcode != null && zipcode.isNotEmpty) && lat == null && lon == null) {
        final searchQuery = zipcode != null && zipcode.isNotEmpty ? zipcode : cityName!;
        final coords = await _getCoordinatesForLocation(searchQuery, isZipcode: zipcode != null && zipcode.isNotEmpty);
        if (coords == null) {
          _logger.w('Could not find coordinates for location: $searchQuery');
          return null;
        }
        lat = coords['latitude'];
        lon = coords['longitude'];
        city = coords['name'] as String?;
        country = coords['country'] as String? ?? '';
      } else if (lat == null || lon == null) {
        // Use default location if nothing provided
        lat = 37.7749; // San Francisco default
        lon = -122.4194;
        city = AppConstants.defaultWeatherCity;
      }

      // Get current weather from Open-Meteo
      final url = Uri.parse(
        '$_baseUrl/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,pressure_msl&timezone=auto'
      );

      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data, city ?? AppConstants.defaultWeatherCity, country);
      } else {
        _logger.e('Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Get weather error: $e');
      return null;
    }
  }

  /// Get coordinates for a location (city name or zipcode) using geocoding API
  Future<Map<String, dynamic>?> _getCoordinatesForLocation(String location, {bool isZipcode = false}) async {
    try {
      // Open-Meteo geocoding API supports both city names and postal codes (zipcodes)
      // For zipcodes, we can search by postal code or include it in the name search
      final queryParam = isZipcode ? 'postal_code' : 'name';
      final url = Uri.parse(
        '$_geocodingUrl/search?$queryParam=${Uri.encodeComponent(location)}&count=1&language=en&format=json'
      );


      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final result = results.first as Map<String, dynamic>;
          final name = result['name'] as String? ?? location;
          final admin1 = result['admin1'] as String?; // State/Province
          final country = result['country'] as String? ?? '';
          
          // For zipcodes, construct a better display name
          final displayName = isZipcode && admin1 != null 
              ? '$name, $admin1' 
              : name;
          
          
          return {
            'latitude': result['latitude'] as double,
            'longitude': result['longitude'] as double,
            'name': displayName,
            'country': country,
          };
        } else {
          _logger.w('No results found for location: $location');
        }
      } else {
        _logger.e('Geocoding API error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Geocoding error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse weather data from Open-Meteo API response
  WeatherModel _parseWeatherData(Map<String, dynamic> data, String city, String country) {
    final current = data['current'] as Map<String, dynamic>;
    final temperature = (current['temperature_2m'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toInt();
    final weatherCode = current['weather_code'] as int;
    final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final pressure = (current['pressure_msl'] as num?)?.toDouble();

    // Map WMO weather code to description and icon
    final weatherInfo = _getWeatherInfoFromCode(weatherCode);
    
    return WeatherModel(
      temperature: temperature,
      feelsLike: temperature, // Open-Meteo doesn't provide feels_like, use same as temperature
      humidity: humidity,
      description: weatherInfo['description'] as String,
      icon: weatherInfo['icon'] as String,
      city: city,
      country: country,
      windSpeed: windSpeed,
      visibility: 10000, // Open-Meteo doesn't provide visibility, use default
      pressure: pressure,
    );
  }

  /// Map WMO weather code to description and icon
  /// WMO Weather interpretation codes (WW): https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM
  Map<String, String> _getWeatherInfoFromCode(int code) {
    // Clear sky
    if (code == 0) {
      return {'description': 'Clear sky', 'icon': '01d'};
    }
    // Mainly clear
    if (code == 1) {
      return {'description': 'Mainly clear', 'icon': '02d'};
    }
    // Partly cloudy
    if (code == 2) {
      return {'description': 'Partly cloudy', 'icon': '02d'};
    }
    // Overcast
    if (code == 3) {
      return {'description': 'Overcast', 'icon': '04d'};
    }
    // Fog
    if (code == 45 || code == 48) {
      return {'description': 'Fog', 'icon': '50d'};
    }
    // Drizzle
    if (code >= 51 && code <= 57) {
      return {'description': 'Drizzle', 'icon': '09d'};
    }
    // Rain
    if (code >= 61 && code <= 67) {
      return {'description': 'Rain', 'icon': '10d'};
    }
    // Snow
    if (code >= 71 && code <= 77) {
      return {'description': 'Snow', 'icon': '13d'};
    }
    // Rain showers
    if (code >= 80 && code <= 82) {
      return {'description': 'Rain showers', 'icon': '09d'};
    }
    // Snow showers
    if (code >= 85 && code <= 86) {
      return {'description': 'Snow showers', 'icon': '13d'};
    }
    // Thunderstorm
    if (code >= 95 && code <= 99) {
      return {'description': 'Thunderstorm', 'icon': '11d'};
    }
    // Default
    return {'description': 'Unknown', 'icon': '01d'};
  }
}

