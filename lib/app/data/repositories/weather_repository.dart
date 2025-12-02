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
          _logger.w('Could not find coordinates for zipcode: $zipcode');
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
          _logger.w('Could not find coordinates for city: $cityName');
          return null;
        }
      }
      // If coordinates provided, use them directly
      else if (lat != null && lon != null) {
        // Coordinates already set
      }
      // Fallback to default location
      else {
        lat = 37.7749; // San Francisco default
        lon = -122.4194;
        city = AppConstants.defaultWeatherCity;
      }

      // At this point, lat and lon are guaranteed to be non-null due to fallback
      // Get weather from NWS API
      return await _getWeatherFromNWS(
        latitude: lat!,
        longitude: lon!,
        city: city ?? AppConstants.defaultWeatherCity,
      );
    } catch (e, stackTrace) {
      _logger.e('Get weather error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get weather from National Weather Service API
  Future<WeatherModel?> _getWeatherFromNWS({
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    try {
      // Step 1: Get gridpoint from coordinates
      final pointsUrl = Uri.parse(
        '${WeatherConfig.baseUrl}/points/${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}'
      );

      final pointsResponse = await http.get(
        pointsUrl,
        headers: {'User-Agent': WeatherConfig.userAgent},
      ).timeout(AppConstants.requestTimeout);

      if (pointsResponse.statusCode != 200) {
        _logger.e('NWS points API error: ${pointsResponse.statusCode} - ${pointsResponse.body}');
        return null;
      }

      final pointsData = json.decode(pointsResponse.body);
      final properties = pointsData['properties'] as Map<String, dynamic>?;
      if (properties == null) {
        _logger.e('Invalid NWS points response: missing properties');
        return null;
      }

      final forecastUrl = properties['forecast'] as String?;
      final forecastHourlyUrl = properties['forecastHourly'] as String?;
      
      if (forecastUrl == null || forecastHourlyUrl == null) {
        _logger.e('Invalid NWS points response: missing forecast URLs');
        return null;
      }

      // Step 2: Get current conditions from hourly forecast
      final hourlyResponse = await http.get(
        Uri.parse(forecastHourlyUrl),
        headers: {'User-Agent': WeatherConfig.userAgent},
      ).timeout(AppConstants.requestTimeout);

      if (hourlyResponse.statusCode != 200) {
        _logger.e('NWS hourly forecast API error: ${hourlyResponse.statusCode} - ${hourlyResponse.body}');
        return null;
      }

      final hourlyData = json.decode(hourlyResponse.body);
      final periods = hourlyData['properties']?['periods'] as List?;
      
      if (periods == null || periods.isEmpty) {
        _logger.e('Invalid NWS hourly forecast response: missing periods');
        return null;
      }

      // Get current period (first period)
      final currentPeriod = periods.first as Map<String, dynamic>;

      // Step 3: Get regular forecast for additional details
      final forecastResponse = await http.get(
        Uri.parse(forecastUrl),
        headers: {'User-Agent': WeatherConfig.userAgent},
      ).timeout(AppConstants.requestTimeout);

      Map<String, dynamic>? forecastData;
      if (forecastResponse.statusCode == 200) {
        forecastData = json.decode(forecastResponse.body);
      }

      return _parseNWSWeatherData(
        currentPeriod: currentPeriod,
        forecastData: forecastData,
        city: city,
      );
    } catch (e, stackTrace) {
      _logger.e('Get weather from NWS error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get coordinates for a zipcode using Zippopotam API (zipcode-specific, free, no key)
  Future<Map<String, dynamic>?> _getCoordinatesForZipcode(String zipcode) async {
    try {
      // Clean zipcode (remove extension if present)
      final cleanZipcode = zipcode.trim().split('-').first;
      
      // Zippopotam API - specifically for US zipcodes
      final url = Uri.parse('${WeatherConfig.zipcodeGeocodingUrl}/$cleanZipcode');

      final response = await http.get(url).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['places'] as List?;
        
        if (places != null && places.isNotEmpty) {
          // Use the first place (usually the primary city for the zipcode)
          final place = places.first as Map<String, dynamic>;
          
          final latitude = double.tryParse(place['latitude'] as String? ?? '');
          final longitude = double.tryParse(place['longitude'] as String? ?? '');
          
          if (latitude != null && longitude != null) {
            final city = place['place name'] as String? ?? '';
            final state = place['state'] as String? ?? '';
            final stateAbbreviation = place['state abbreviation'] as String? ?? state;
            
            return {
              'latitude': latitude,
              'longitude': longitude,
              'name': city.isNotEmpty ? '$city, $stateAbbreviation' : 'Zipcode $cleanZipcode',
              'country': 'US',
            };
          }
        }
      } else if (response.statusCode == 404) {
        _logger.w('Zipcode not found in Zippopotam: $cleanZipcode');
      }
      
      // Fallback to Open-Meteo geocoding if Zippopotam fails
      return await _getCoordinatesFromOpenMeteo(zipcode, isZipcode: true);
    } catch (e, stackTrace) {
      _logger.e('Get coordinates for zipcode error: $e', error: e, stackTrace: stackTrace);
      // Fallback to Open-Meteo
      return await _getCoordinatesFromOpenMeteo(zipcode, isZipcode: true);
    }
  }

  /// Get coordinates for a city name using Open-Meteo Geocoding API
  Future<Map<String, dynamic>?> _getCoordinatesForLocation(String location) async {
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
    var result = await _getCoordinatesFromOpenMeteo(cleanLocation, isZipcode: false);
    if (result != null) {
      return result;
    }
    
    // Strategy 2: Try with ", US" suffix for US cities
    result = await _getCoordinatesFromOpenMeteo('$cleanLocation, US', isZipcode: false);
    if (result != null) {
      return result;
    }
    
    // Strategy 3: Try original location if it was different
    if (cleanLocation != location.trim()) {
      result = await _getCoordinatesFromOpenMeteo(location.trim(), isZipcode: false);
      if (result != null) {
        return result;
      }
    }
    
    return null;
  }

  /// Get coordinates using Open-Meteo Geocoding API (fallback for city names)
  Future<Map<String, dynamic>?> _getCoordinatesFromOpenMeteo(String location, {bool isZipcode = false}) async {
    try {
      // For zipcodes, try searching with "US" prefix to improve results
      // For city names, search as-is (already cleaned in _getCoordinatesForLocation)
      final searchQuery = isZipcode ? '$location, US' : location;
      final url = Uri.parse(
        '${WeatherConfig.openMeteoGeocodingUrl}/search?name=${Uri.encodeComponent(searchQuery)}&count=10&language=en&format=json'
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
        } else {
          _logger.w('Open-Meteo geocoding returned no results for: $location (searchQuery: $searchQuery)');
        }
      } else {
        _logger.w('Open-Meteo geocoding API error: ${response.statusCode}');
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.e('Open-Meteo geocoding error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse weather data from NWS API response
  WeatherModel _parseNWSWeatherData({
    required Map<String, dynamic> currentPeriod,
    Map<String, dynamic>? forecastData,
    required String city,
  }) {
    // Extract current weather data
    final temperature = (currentPeriod['temperature'] as num).toDouble();
    final windSpeed = (currentPeriod['windSpeed'] as String? ?? '0 mph')
        .replaceAll(' mph', '')
        .split(' to ')
        .first;
    final windSpeedNum = double.tryParse(windSpeed) ?? 0.0;
    
    final relativeHumidity = currentPeriod['relativeHumidity']?['value'] as num?;
    final humidity = relativeHumidity != null ? relativeHumidity.toInt() : 0;
    
    final shortForecast = currentPeriod['shortForecast'] as String? ?? 'Unknown';
    final icon = _getIconFromForecast(shortForecast);
    
    // Extract additional data from forecast if available
    double? pressure;
    if (forecastData != null) {
      final properties = forecastData['properties'] as Map<String, dynamic>?;
      final periods = properties?['periods'] as List?;
      if (periods != null && periods.isNotEmpty) {
        // NWS doesn't provide pressure in standard forecast, use default
        pressure = null;
      }
    }
    
    return WeatherModel(
      temperature: temperature,
      feelsLike: temperature, // NWS doesn't provide feels_like, use same as temperature
      humidity: humidity,
      description: shortForecast,
      icon: icon,
      city: city,
      country: 'US',
      windSpeed: windSpeedNum,
      visibility: 10, // NWS doesn't provide visibility in standard forecast
      pressure: pressure,
    );
  }

  /// Map NWS forecast text to OpenWeatherMap icon codes
  String _getIconFromForecast(String forecast) {
    final lowerForecast = forecast.toLowerCase();
    
    if (lowerForecast.contains('sunny') || lowerForecast.contains('clear')) {
      return '01d';
    } else if (lowerForecast.contains('partly cloudy') || lowerForecast.contains('partly sunny')) {
      return '02d';
    } else if (lowerForecast.contains('cloudy') || lowerForecast.contains('overcast')) {
      return '04d';
    } else if (lowerForecast.contains('rain') || lowerForecast.contains('shower')) {
      return '10d';
    } else if (lowerForecast.contains('thunderstorm') || lowerForecast.contains('thunder')) {
      return '11d';
    } else if (lowerForecast.contains('snow') || lowerForecast.contains('snowy')) {
      return '13d';
    } else if (lowerForecast.contains('fog') || lowerForecast.contains('mist')) {
      return '50d';
    } else if (lowerForecast.contains('drizzle')) {
      return '09d';
    } else {
      return '01d'; // Default to clear
    }
  }
}
