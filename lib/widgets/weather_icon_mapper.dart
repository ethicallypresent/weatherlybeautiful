import 'package:flutter/widgets.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherIconMapper {
  const WeatherIconMapper._();

  static IconData fromCode(int code) {
    if (code == 0) return WeatherIcons.day_sunny;
    if (code == 1 || code == 2) return WeatherIcons.day_cloudy;
    if (code == 3) return WeatherIcons.cloudy;
    if (code == 45 || code == 48) return WeatherIcons.fog;
    if ([51, 53, 55, 56, 57].contains(code)) return WeatherIcons.sprinkle;
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return WeatherIcons.rain;
    if ([71, 73, 75, 77, 85, 86].contains(code)) return WeatherIcons.snow;
    if ([95, 96, 99].contains(code)) return WeatherIcons.thunderstorm;
    return WeatherIcons.na;
  }
}
