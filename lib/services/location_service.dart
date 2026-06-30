import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<LocationPermission> ensureLocationPermission({
    bool openSettingsIfDeniedForever = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Geolocator.openLocationSettings();
      }
      throw const LocationServiceException(
        'Location services are disabled. Please enable Location Services on your device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location access was denied. Allow location access to fetch local weather.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfDeniedForever) {
        await Geolocator.openAppSettings();
      }
      throw const LocationServiceException(
        'Location access is permanently denied. Please enable it in iOS Settings > Privacy & Security > Location Services.',
      );
    }

    return permission;
  }

  Future<Position> getCurrentPosition() async {
    try {
      await ensureLocationPermission(openSettingsIfDeniedForever: true);

      return Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(),
      );
    } on LocationServiceException {
      rethrow;
    } on MissingPluginException {
      throw const LocationServiceException(
        'Location plugin is not available on this build. Please reinstall the app and try again.',
      );
    } catch (e) {
      throw LocationServiceException(
        'Unable to get current position: $e',
      );
    }
  }

  Future<String> getCityFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        throw const LocationServiceException(
          'No location details found for current coordinates.',
        );
      }

      final place = placemarks.first;
      final city = _resolveBestCity(place);

      if (city.isEmpty) {
        throw const LocationServiceException(
          'Could not determine city name for current location.',
        );
      }

      return city;
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException(
        'Unable to resolve city from coordinates: $e',
      );
    }
  }

  Future<String> getCurrentCity() async {
    final position = await getCurrentPosition();
    return getCityFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  LocationSettings _locationSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.otherNavigation,
          pauseLocationUpdatesAutomatically: true,
        );
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: false,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
        );
    }
  }

  String _resolveBestCity(Placemark place) {
    return place.locality?.trim().isNotEmpty == true
        ? place.locality!.trim()
        : place.subAdministrativeArea?.trim().isNotEmpty == true
            ? place.subAdministrativeArea!.trim()
            : place.administrativeArea?.trim().isNotEmpty == true
                ? place.administrativeArea!.trim()
                : '';
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => 'LocationServiceException: $message';
}
