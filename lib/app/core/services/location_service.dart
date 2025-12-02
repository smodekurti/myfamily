import 'dart:async';
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
  /// Falls back to last known position if current position times out
  /// Proactively requests permission and prompts to enable location services if needed
  Future<Position?> getCurrentLocation() async {
    try {
      // First, check and request permission if needed
      var permission = await Permission.location.status;
      
      if (permission.isDenied) {
        _logger.i('Location permission denied, requesting permission...');
        // Request permission proactively
        permission = await Permission.location.request();
        
        if (permission.isDenied) {
          _logger.w('Location permission denied after request');
          return null;
        }
      }

      if (permission.isPermanentlyDenied) {
        _logger.w('Location permission permanently denied. User needs to enable it in settings.');
        // Open app settings so user can enable permission
        await openAppSettings();
        return null;
      }

      if (!permission.isGranted) {
        _logger.w('Location permission not granted: $permission');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled, prompting user to enable...');
        // Prompt user to enable location services
        final enabled = await Geolocator.openLocationSettings();
        if (!enabled) {
          _logger.w('User did not enable location services');
          // Try to get last known position as fallback
          return await _getLastKnownPosition();
        }
        // Wait a moment for location services to initialize
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Try to get current position with lower accuracy for faster results
      // Lower accuracy works better on emulators and devices with poor GPS signal
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Lower accuracy for faster results
          timeLimit: const Duration(seconds: 10), // Reduced timeout
        );
        return position;
      } on TimeoutException {
        _logger.w('Current position request timed out, trying last known position');
        // Fallback to last known position if current position times out
        return await _getLastKnownPosition();
      } catch (e) {
        _logger.w('Error getting current position: $e, trying last known position');
        // Fallback to last known position on any error
        return await _getLastKnownPosition();
      }
    } catch (e, stackTrace) {
      _logger.e('Get current location error: $e', error: e, stackTrace: stackTrace);
      // Final fallback to last known position
      return await _getLastKnownPosition();
    }
  }

  /// Get last known position as fallback
  Future<Position?> _getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _logger.i('Using last known position: ${position.latitude}, ${position.longitude}');
        return position;
      }
      _logger.w('No last known position available');
      return null;
    } catch (e) {
      _logger.w('Error getting last known position: $e');
      return null;
    }
  }
}


