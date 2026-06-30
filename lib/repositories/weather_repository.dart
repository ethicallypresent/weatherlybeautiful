import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherRepository {
  WeatherRepository({
    LocationService? locationService,
    WeatherService? weatherService,
  })  : _locationService = locationService ?? LocationService(),
        _weatherService = weatherService ?? WeatherService();

  final LocationService _locationService;
  final WeatherService _weatherService;

  Future<WeatherRepositoryResult> getWeatherByCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final cityName = await _locationService.getCityFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final weather = await _weatherService.fetchWeatherByCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return WeatherRepositoryResult(
        cityName: cityName,
        latitude: position.latitude,
        longitude: position.longitude,
        weather: weather,
      );
    } catch (e) {
      throw WeatherRepositoryException(
        'Failed to load weather for current location: $e',
      );
    }
  }

  Future<WeatherRepositoryResult> getWeatherByCity(String city) async {
    try {
      final locations = await locationFromAddress(city);
      if (locations.isEmpty) {
        throw const WeatherRepositoryException(
          'No coordinates found for the provided city name.',
        );
      }

      final location = locations.first;
      final weather = await _weatherService.fetchWeatherByCoordinates(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      return WeatherRepositoryResult(
        cityName: city,
        latitude: location.latitude,
        longitude: location.longitude,
        weather: weather,
      );
    } catch (e) {
      if (e is WeatherRepositoryException) rethrow;
      throw WeatherRepositoryException(
        'Failed to load weather for city "$city": $e',
      );
    }
  }

  Future<WeatherRepositoryResult> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cityName = await _locationService.getCityFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      final weather = await _weatherService.fetchWeatherByCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      return WeatherRepositoryResult(
        cityName: cityName,
        latitude: latitude,
        longitude: longitude,
        weather: weather,
      );
    } catch (e) {
      throw WeatherRepositoryException(
        'Failed to load weather for coordinates ($latitude, $longitude): $e',
      );
    }
  }
}

class WeatherRepositoryResult {
  const WeatherRepositoryResult({
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.weather,
  });

  final String cityName;
  final double latitude;
  final double longitude;
  final WeatherResult weather;
}

class WeatherRepositoryException implements Exception {
  const WeatherRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'WeatherRepositoryException: $message';
}
