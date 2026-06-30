import 'package:flutter/material.dart';

import '../models/weather.dart';
import 'weather_icon_mapper.dart';

class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({
    super.key,
    required this.current,
    required this.humidity,
    this.feelsLike,
  });

  final CurrentWeather current;
  final int humidity;
  final double? feelsLike;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final tempFontSize = compact ? 56.0 : 72.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: scheme.surface.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    WeatherIconMapper.fromCode(current.weatherCode),
                    color: onSurface,
                    size: compact ? 34 : 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      current.weatherDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${current.temperature.round()}°',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: tempFontSize,
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  _MetricBadge(
                    icon: Icons.thermostat_rounded,
                    label: 'Feels like',
                    value: '${(feelsLike ?? current.temperature).round()}°',
                  ),
                  _MetricBadge(
                    icon: Icons.water_drop_rounded,
                    label: 'Humidity',
                    value: '$humidity%',
                  ),
                  _MetricBadge(
                    icon: Icons.air_rounded,
                    label: 'Wind',
                    value: '${current.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onSurface),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
