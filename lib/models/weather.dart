class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.time,
  });

  final double temperature;
  final double windSpeed;
  final int windDirection;
  final int weatherCode;
  final DateTime time;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      windDirection: (json['wind_direction_10m'] as num?)?.toInt() ?? 0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get weatherDescription => WeatherCodeMapper.description(weatherCode);

  String get weatherIcon => WeatherCodeMapper.iconAsset(weatherCode);
}

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.precipitationProbability,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int humidity;
  final int precipitationProbability;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      humidity: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toInt() ?? 0,
    );
  }

  static List<HourlyForecast> listFromApi(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>?;
    if (hourly == null) return const [];

    final times = (hourly['time'] as List?) ?? const [];
    final temperatures = (hourly['temperature_2m'] as List?) ?? const [];
    final weatherCodes = (hourly['weather_code'] as List?) ?? const [];
    final humidities = (hourly['relative_humidity_2m'] as List?) ?? const [];
    final precipitationProbabilities =
        (hourly['precipitation_probability'] as List?) ?? const [];

    final length = [
      times.length,
      temperatures.length,
      weatherCodes.length,
      humidities.length,
      precipitationProbabilities.length,
    ].reduce((a, b) => a < b ? a : b);

    return List<HourlyForecast>.generate(length, (index) {
      return HourlyForecast(
        time: DateTime.tryParse(times[index]?.toString() ?? '') ?? DateTime.now(),
        temperature: (temperatures[index] as num?)?.toDouble() ?? 0.0,
        weatherCode: (weatherCodes[index] as num?)?.toInt() ?? 0,
        humidity: (humidities[index] as num?)?.toInt() ?? 0,
        precipitationProbability:
            (precipitationProbabilities[index] as num?)?.toInt() ?? 0,
      );
    });
  }

  String get weatherDescription => WeatherCodeMapper.description(weatherCode);

  String get weatherIcon => WeatherCodeMapper.iconAsset(weatherCode);
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
    required this.precipitationProbabilityMax,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int weatherCode;
  final int precipitationProbabilityMax;
  final DateTime? sunrise;
  final DateTime? sunset;

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      maxTemperature: (json['temperature_2m_max'] as num?)?.toDouble() ?? 0.0,
      minTemperature: (json['temperature_2m_min'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      precipitationProbabilityMax:
          (json['precipitation_probability_max'] as num?)?.toInt() ?? 0,
      sunrise: DateTime.tryParse(json['sunrise']?.toString() ?? ''),
      sunset: DateTime.tryParse(json['sunset']?.toString() ?? ''),
    );
  }

  static List<DailyForecast> listFromApi(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily == null) return const [];

    final dates = (daily['time'] as List?) ?? const [];
    final maxTemperatures = (daily['temperature_2m_max'] as List?) ?? const [];
    final minTemperatures = (daily['temperature_2m_min'] as List?) ?? const [];
    final weatherCodes = (daily['weather_code'] as List?) ?? const [];
    final precipitationProbabilityMax =
        (daily['precipitation_probability_max'] as List?) ?? const [];
    final sunrises = (daily['sunrise'] as List?) ?? const [];
    final sunsets = (daily['sunset'] as List?) ?? const [];

    final length = [
      dates.length,
      maxTemperatures.length,
      minTemperatures.length,
      weatherCodes.length,
      precipitationProbabilityMax.length,
    ].reduce((a, b) => a < b ? a : b);

    return List<DailyForecast>.generate(length, (index) {
      return DailyForecast(
        date: DateTime.tryParse(dates[index]?.toString() ?? '') ?? DateTime.now(),
        maxTemperature: (maxTemperatures[index] as num?)?.toDouble() ?? 0.0,
        minTemperature: (minTemperatures[index] as num?)?.toDouble() ?? 0.0,
        weatherCode: (weatherCodes[index] as num?)?.toInt() ?? 0,
        precipitationProbabilityMax:
            (precipitationProbabilityMax[index] as num?)?.toInt() ?? 0,
        sunrise: index < sunrises.length
            ? DateTime.tryParse(sunrises[index]?.toString() ?? '')
            : null,
        sunset: index < sunsets.length
            ? DateTime.tryParse(sunsets[index]?.toString() ?? '')
            : null,
      );
    });
  }

  String get weatherDescription => WeatherCodeMapper.description(weatherCode);

  String get weatherIcon => WeatherCodeMapper.iconAsset(weatherCode);
}

class WeatherCodeMapper {
  static String description(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow fall';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  static String iconAsset(int code) {
    if (code == 0) return 'clear';
    if (code == 1 || code == 2) return 'partly_cloudy';
    if (code == 3) return 'cloudy';
    if (code == 45 || code == 48) return 'fog';
    if ([51, 53, 55, 56, 57].contains(code)) return 'drizzle';
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return 'rain';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'snow';
    if ([95, 96, 99].contains(code)) return 'thunderstorm';
    return 'unknown';
  }
}
