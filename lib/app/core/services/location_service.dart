import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class LocationService {
  final Logger _logger = Logger();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      _logger.d('Getting current location...');

      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled.');
        // Services are disabled. We cannot query the location.
        // We can request the user to enable it, but fail gracefully for now.
        // Or specific to Android, request to open settings.
        return null;
      }

      // 2. Check permissions using Geolocator (not permission_handler)
      LocationPermission permission = await Geolocator.checkPermission();
      _logger.d('Location permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        _logger.d('Location permission requested. Result: $permission');
        if (permission == LocationPermission.denied) {
          _logger.w('Location permission denied.');
          // Permissions are denied, next time you could try requesting again
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permission denied forever.');
        // Permissions are denied forever, handle appropriately
        return null;
      }

      // 3. Get position
      // Using medium accuracy is usually sufficient for weather and faster/battery efficient
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _logger.d('Got position: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        _logger.w(
          'Failed to get current position ($e). Trying last known position.',
        );
        return await _getLastKnownPosition();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Get current location error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to last known position
      return await _getLastKnownPosition();
    }
  }

  /// Get last known position as fallback
  Future<Position?> _getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _logger.d(
          'Got last known position: ${position.latitude}, ${position.longitude}',
        );
      } else {
        _logger.w('Last known position is null.');
      }
      return position;
    } catch (e) {
      _logger.e('Error getting last known position: $e');
      return null;
    }
  }
}
