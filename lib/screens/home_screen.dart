import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

import '../cubits/weather_cubit.dart';
import '../models/weather.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state) {
          final gradient = _gradientForState(state);

          return Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(context, state),
                child: _buildStateView(context, state),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _LocationButton(
        onTap: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
      ),
    );
  }

  Future<void> _onRefresh(BuildContext context, WeatherState state) async {
    final cubit = context.read<WeatherCubit>();

    if (state is WeatherSuccess) {
      await cubit.fetchWeatherByCity(state.data.cityName);
      return;
    }

    await cubit.fetchWeatherByLocation();
  }

  Widget _buildStateView(BuildContext context, WeatherState state) {
    if (state is WeatherLoading || state is WeatherInitial) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (state is WeatherError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_rounded, size: 72, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Could not load weather',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    final success = state as WeatherSuccess;
    final data = success.data;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: _TopActionBar(
              city: data.cityName,
              onSearchTap: () => _showSearchDialog(context),
              onLocationTap: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _CurrentWeatherCard(
              current: data.weather.current,
              humidity: data.weather.hourly.isNotEmpty ? data.weather.hourly.first.humidity : 0,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              'Next 24 hours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: data.weather.hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hour = data.weather.hourly[index];
                return _HourlyItem(forecast: hour);
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              '7-day forecast',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList.separated(
            itemCount: data.weather.daily.length,
            itemBuilder: (context, index) => _DailyItem(
              forecast: data.weather.daily[index],
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search City'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Enter city name',
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    final city = controller.text.trim();
    if (city.isNotEmpty && context.mounted) {
      context.read<WeatherCubit>().fetchWeatherByCity(city);
    }
  }

  LinearGradient _gradientForState(WeatherState state) {
    if (state is! WeatherSuccess) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
      );
    }

    final weatherCode = state.data.weather.current.weatherCode;

    if (weatherCode == 0) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
      );
    }

    if ([1, 2, 3].contains(weatherCode)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
      );
    }

    if ([45, 48].contains(weatherCode)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
      );
    }

    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(weatherCode)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF314755), Color(0xFF26A0DA)],
      );
    }

    if ([71, 73, 75, 77, 85, 86].contains(weatherCode)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE6DADA), Color(0xFF274046)],
      );
    }

    if ([95, 96, 99].contains(weatherCode)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    );
  }
}

class _TopActionBar extends StatelessWidget {
  const _TopActionBar({
    required this.city,
    required this.onSearchTap,
    required this.onLocationTap,
  });

  final String city;
  final VoidCallback onSearchTap;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMM').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onSearchTap,
          icon: const Icon(Icons.search_rounded),
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onLocationTap,
          icon: const Icon(Icons.my_location_rounded),
          color: Colors.white,
        ),
      ],
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({
    required this.current,
    required this.humidity,
  });

  final CurrentWeather current;
  final int humidity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BoxedIcon(
                _iconForCode(current.weatherCode),
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  current.weatherDescription,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${current.temperature.round()}°',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: WeatherIcons.thermometer,
                label: 'Feels like',
                value: '${current.temperature.round()}°',
              ),
              _MetricChip(
                icon: WeatherIcons.humidity,
                label: 'Humidity',
                value: '$humidity%',
              ),
              _MetricChip(
                icon: WeatherIcons.strong_wind,
                label: 'Wind',
                value: '${current.windSpeed.toStringAsFixed(1)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  const _HourlyItem({required this.forecast});

  final HourlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('HH:mm').format(forecast.time),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          BoxedIcon(
            _iconForCode(forecast.weatherCode),
            color: Colors.white,
            size: 28,
          ),
          Text(
            '${forecast.temperature.round()}°',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DailyItem extends StatelessWidget {
  const _DailyItem({required this.forecast});

  final DailyForecast forecast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              DateFormat('EEE, d MMM').format(forecast.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          BoxedIcon(
            _iconForCode(forecast.weatherCode),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              forecast.weatherDescription,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                  ),
            ),
          ),
          Text(
            '${forecast.maxTemperature.round()}° / ${forecast.minTemperature.round()}°',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BoxedIcon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: Colors.white.withOpacity(0.20),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.my_location_rounded),
      label: const Text('My Location'),
    );
  }
}

IconData _iconForCode(int code) {
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
