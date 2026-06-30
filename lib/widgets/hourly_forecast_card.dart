import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

import '../models/weather.dart';
import 'weather_icon_mapper.dart';

class HourlyForecastCard extends StatelessWidget {
  const HourlyForecastCard({
    super.key,
    required this.forecast,
  });

  final HourlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 88;

        return Container(
          width: compact ? 78 : 88,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 12,
            horizontal: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: scheme.surface.withOpacity(0.16),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('HH:mm').format(forecast.time),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              BoxedIcon(
                WeatherIconMapper.fromCode(forecast.weatherCode),
                color: onSurface,
                size: compact ? 22 : 26,
              ),
              Text(
                '${forecast.temperature.round()}°',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
