import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherResult> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m,wind_direction_10m',
        'hourly':
            'temperature_2m,weather_code,relative_humidity_2m,precipitation_probability',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    try {
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw WeatherServiceException(
          'Failed to fetch weather data: HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherServiceException('Unexpected API response format.');
      }

      final currentJson = decoded['current'] as Map<String, dynamic>?;
      if (currentJson == null) {
        throw const WeatherServiceException(
          'Current weather data is missing from API response.',
        );
      }

      final current = CurrentWeather.fromJson(currentJson);
      final hourly = HourlyForecast.listFromApi(decoded).take(24).toList();
      final daily = DailyForecast.listFromApi(decoded).take(7).toList();

      return WeatherResult(
        current: current,
        hourly: hourly,
        daily: daily,
      );
    } on FormatException {
      throw const WeatherServiceException('Failed to parse weather data.');
    } on http.ClientException catch (e) {
      throw WeatherServiceException('Network error while fetching weather: $e');
    } catch (e) {
      if (e is WeatherServiceException) rethrow;
      throw WeatherServiceException('Unexpected error while fetching weather: $e');
    }
  }
}

class WeatherResult {
  const WeatherResult({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);

  final String message;

  @override
  String toString() => 'WeatherServiceException: $message';
}
