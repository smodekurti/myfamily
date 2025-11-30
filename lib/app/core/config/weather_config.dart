/// Weather API configuration for MyFamily app
class WeatherConfig {
  // National Weather Service API - Free, no API key required
  // Documentation: https://www.weather.gov/documentation/services-web-api
  
  /// NWS API base URL
  static const String baseUrl = 'https://api.weather.gov';
  
  /// User-Agent header (required by NWS API)
  /// Should identify your application and contact info
  static const String userAgent = 'MyFamily App (contact: support@myfamily.app)';
  
  /// Geocoding API for zipcode lookup (Zippopotam - free, no key, zipcode-specific)
  static const String zipcodeGeocodingUrl = 'https://api.zippopotam.us/us';
  
  /// Geocoding API for city lookup (Open-Meteo - free, no key)
  static const String openMeteoGeocodingUrl = 'https://geocoding-api.open-meteo.com/v1';
}
