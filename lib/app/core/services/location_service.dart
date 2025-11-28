import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class LocationService {
  final Logger _logger = Logger();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Get current location
  /// Returns null if permission denied or location unavailable
  Future<Position?> getCurrentLocation() async {
    try {
      _logger.i('Getting current location...');
      
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        return null;
      }

      // Check permission
      var permission = await Permission.location.status;
      _logger.i('Location permission status: $permission');
      
      if (permission.isDenied) {
        _logger.i('Location permission denied, requesting...');
        // Request permission
        permission = await Permission.location.request();
        _logger.i('Location permission request result: $permission');
        
        if (permission.isDenied) {
          _logger.w('Location permission denied after request');
          return null;
        }
      }

      if (permission.isPermanentlyDenied) {
        _logger.w('Location permission permanently denied');
        return null;
      }

      if (!permission.isGranted) {
        _logger.w('Location permission not granted: $permission');
        return null;
      }

      _logger.i('Getting current position...');
      // Get current position with better accuracy and timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      _logger.i('Current location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e, stackTrace) {
      _logger.e('Get current location error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}


