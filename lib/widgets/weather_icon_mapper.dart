import 'package:flutter/material.dart';

class WeatherIconMapper {
  const WeatherIconMapper._();

  static IconData fromCode(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code == 1 || code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if ([51, 53, 55, 56, 57].contains(code)) return Icons.grain_rounded;
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return Icons.umbrella_rounded;
    if ([71, 73, 75, 77, 85, 86].contains(code)) return Icons.ac_unit_rounded;
    if ([95, 96, 99].contains(code)) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }
}
