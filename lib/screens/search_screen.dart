import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/weather_cubit.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  static const List<String> _quickCities = <String>[
    'London',
    'New York',
    'Tokyo',
    'Paris',
    'Berlin',
    'Singapore',
    'Dubai',
    'Sydney',
    'Istanbul',
    'Toronto',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final city = _controller.text.trim();
    if (city.isEmpty) {
      _showErrorMessage('Please enter a city name.');
      return;
    }

    context.read<WeatherCubit>().fetchWeatherByCity(city);
  }

  Future<void> _showErrorMessage(String message) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (!isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Weatherly'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return BlocListener<WeatherCubit, WeatherState>(
      listener: (context, state) {
        if (state is WeatherSuccess) {
          Navigator.of(context).pop(state.data.cityName);
          return;
        }

        if (state is WeatherError) {
          _showErrorMessage(state.message);
        }
      },
      child: isIOS
          ? CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Search City'),
              ),
              child: SafeArea(
                child: _SearchContent(
                  controller: _controller,
                  quickCities: _quickCities,
                  onSearch: _search,
                  isIOS: true,
                ),
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: const Text('Search City'),
                centerTitle: true,
              ),
              body: SafeArea(
                child: _SearchContent(
                  controller: _controller,
                  quickCities: _quickCities,
                  onSearch: _search,
                  isIOS: false,
                ),
              ),
            ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({
    required this.controller,
    required this.quickCities,
    required this.onSearch,
    required this.isIOS,
  });

  final TextEditingController controller;
  final List<String> quickCities;
  final VoidCallback onSearch;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final horizontalPadding = width <= 390 ? 14.0 : 16.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          keyboardInset + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isIOS)
              CupertinoSearchTextField(
                controller: controller,
                onSubmitted: (_) => onSearch(),
                placeholder: 'Search city',
              )
            else
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            BlocBuilder<WeatherCubit, WeatherState>(
              builder: (context, state) {
                final isLoading = state is WeatherLoading;

                if (isIOS) {
                  return SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: isLoading ? null : onSearch,
                      child: isLoading
                          ? const CupertinoActivityIndicator()
                          : const Text('Search Weather'),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onSearch,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.travel_explore_rounded),
                    label: Text(isLoading ? 'Searching...' : 'Search Weather'),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Quick cities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickCities.map((city) {
                if (isIOS) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(18),
                    onPressed: () {
                      controller.text = city;
                      onSearch();
                    },
                    child: Text(
                      city,
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ActionChip(
                  avatar: Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  label: Text(city),
                  onPressed: () {
                    controller.text = city;
                    onSearch();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                        scheme.primaryContainer.withValues(alpha: 0.75),
                        scheme.secondaryContainer.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tip: Search by major city name for best geocoding results.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
