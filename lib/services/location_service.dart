import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceException(
          'Location services are disabled. Please enable GPS/location services.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Location permission denied. Please allow location access.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationServiceException(
          'Location permission permanently denied. Please enable it in app settings.',
        );
      }

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } on LocationServiceException {
      rethrow;
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
