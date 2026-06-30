import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

import '../models/weather.dart';
import 'weather_icon_mapper.dart';

class DailyForecastCard extends StatelessWidget {
  const DailyForecastCard({
    super.key,
    required this.forecast,
  });

  final DailyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surface.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: compact ? 90 : 106,
                child: Text(
                  DateFormat('EEE, d MMM').format(forecast.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              BoxedIcon(
                WeatherIconMapper.fromCode(forecast.weatherCode),
                size: compact ? 22 : 24,
                color: onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  forecast.weatherDescription,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurface.withOpacity(0.96),
                      ),
                ),
              ),
              Text(
                '${forecast.maxTemperature.round()}° / ${forecast.minTemperature.round()}°',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
