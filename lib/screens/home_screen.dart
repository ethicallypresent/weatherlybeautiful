import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../cubits/weather_cubit.dart';
import '../repositories/weather_repository.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/hourly_forecast_card.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark
            ? SystemUiOverlayStyle.light
            : const SystemUiOverlayStyle(
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.light,
              ),
        child: BlocConsumer<WeatherCubit, WeatherState>(
          listener: (context, state) {
            if (state is WeatherError && state.previousData != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
          builder: (context, state) {
            final gradient = _gradientForState(state);

            return Container(
              decoration: BoxDecoration(gradient: gradient),
              child: SafeArea(
                child: RefreshIndicator.adaptive(
                  onRefresh: () => _onRefresh(context, state),
                  child: _buildStateView(context, state),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _LocationButton(
        onTap: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final horizontalPadding = _horizontalPadding(context);

    if (state is WeatherLoading && state.previousData != null) {
      return _buildWeatherContent(
        context,
        state.previousData!,
        isRefreshing: true,
      );
    }

    if (state is WeatherError && state.previousData != null) {
      return _buildWeatherContent(
        context,
        state.previousData!,
        bannerMessage: state.message,
      );
    }

    if (state is WeatherLoading || state is WeatherInitial) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          const SizedBox(height: 220),
          Center(
            child: isIOS
                ? const CupertinoActivityIndicator(radius: 16)
                : const CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (state is WeatherError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
        children: [
          const SizedBox(height: 120),
          Icon(
            isIOS ? CupertinoIcons.cloud : Icons.cloud_off_rounded,
            size: 72,
            color: Colors.white,
          ),
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
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 24),
          isIOS
              ? CupertinoButton.filled(
                  onPressed: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
                  child: const Text('Try Again'),
                )
              : FilledButton.icon(
                  onPressed: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
        ],
      );
    }

    final success = state as WeatherSuccess;
    return _buildWeatherContent(context, success.data);
  }

  Widget _buildWeatherContent(
    BuildContext context,
    WeatherRepositoryResult data, {
    bool isRefreshing = false,
    String? bannerMessage,
  }) {
    final horizontalPadding = _horizontalPadding(context);

    return Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 10),
                child: _TopActionBar(
                  city: data.cityName,
                  onSearchTap: () => _openSearchScreen(context),
                  onLocationTap: () => context.read<WeatherCubit>().fetchWeatherByLocation(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                child: CurrentWeatherCard(
                  current: data.weather.current,
                  humidity: data.weather.hourly.isNotEmpty ? data.weather.hourly.first.humidity : 0,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 6),
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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: data.weather.hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final hour = data.weather.hourly[index];
                    return HourlyForecastCard(forecast: hour);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 10),
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
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                MediaQuery.of(context).padding.bottom + 92,
              ),
              sliver: SliverList.separated(
                itemCount: data.weather.daily.length,
                itemBuilder: (context, index) => DailyForecastCard(
                  forecast: data.weather.daily[index],
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
          ],
        ),
        if (isRefreshing)
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: CupertinoActivityIndicator(radius: 12),
            ),
          ),
        if (bannerMessage != null)
          Positioned(
            top: 6,
            left: horizontalPadding,
            right: horizontalPadding,
            child: _InlineBanner(message: bannerMessage),
          ),
      ],
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 390) return 14;
    if (width <= 430) return 16;
    return 20;

}

Future<void> _openSearchScreen(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    await Navigator.of(context).push<void>(
      isIOS
          ? CupertinoPageRoute<void>(
              builder: (_) => const SearchScreen(),
            )
          : MaterialPageRoute<void>(
              builder: (_) => const SearchScreen(),
            ),
    );
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

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
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
              ),
            ],
          ),
        ),
        isIOS
            ? CupertinoButton(
                onPressed: onSearchTap,
                minimumSize: Size.zero,
                padding: const EdgeInsets.all(8),
                child: const Icon(CupertinoIcons.search, color: Colors.white),
              )
            : IconButton.filledTonal(
                onPressed: onSearchTap,
                icon: const Icon(Icons.search_rounded),
                color: Colors.white,
              ),
        const SizedBox(width: 8),
        isIOS
            ? CupertinoButton(
                onPressed: onLocationTap,
                minimumSize: Size.zero,
                padding: const EdgeInsets.all(8),
                child: const Icon(CupertinoIcons.location_solid, color: Colors.white),
              )
            : IconButton.filledTonal(
                onPressed: onLocationTap,
                icon: const Icon(Icons.my_location_rounded),
                color: Colors.white,
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.location_fill, color: Colors.white),
            SizedBox(width: 8),
            Text('My Location', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.20),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.my_location_rounded),
      label: const Text('My Location'),
    );
  }
}
