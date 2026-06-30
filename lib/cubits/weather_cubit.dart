import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/weather_repository.dart';

abstract class WeatherState {
  const WeatherState({this.previousData});

  final WeatherRepositoryResult? previousData;
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading({super.previousData, this.message});

  final String? message;

  bool get isRefreshing => previousData != null;
}

class WeatherSuccess extends WeatherState {
  const WeatherSuccess(this.data) : super(previousData: data);

  final WeatherRepositoryResult data;
}

class WeatherError extends WeatherState {
  const WeatherError(
    this.message, {
    super.previousData,
    this.canRetry = true,
  });

  final String message;
  final bool canRetry;
}

class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit({WeatherRepository? repository})
      : _repository = repository ?? WeatherRepository(),
        super(const WeatherInitial());

  final WeatherRepository _repository;
  WeatherRepositoryResult? _lastSuccessData;
  bool _isFetching = false;

  Future<void> fetchWeatherByLocation() async {
    if (_isFetching) return;
    _isFetching = true;

    emit(WeatherLoading(
      previousData: _lastSuccessData,
      message: _lastSuccessData == null ? 'Fetching your location...' : 'Refreshing weather...',
    ));

    try {
      final result = await _repository.getWeatherByCurrentLocation();
      _lastSuccessData = result;
      emit(WeatherSuccess(result));
    } catch (e) {
      emit(WeatherError(
        _messageFromError(e),
        previousData: _lastSuccessData,
      ));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchWeatherByCity(String city) async {
    final query = city.trim();
    if (query.isEmpty) {
      emit(WeatherError(
        'Please enter a city name.',
        previousData: _lastSuccessData,
        canRetry: false,
      ));
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    emit(WeatherLoading(
      previousData: _lastSuccessData,
      message: 'Searching $query...',
    ));

    try {
      final result = await _repository.getWeatherByCity(query);
      _lastSuccessData = result;
      emit(WeatherSuccess(result));
    } catch (e) {
      emit(WeatherError(
        _messageFromError(e),
        previousData: _lastSuccessData,
      ));
    } finally {
      _isFetching = false;
    }
  }

  String _messageFromError(Object error) {
    if (error is WeatherRepositoryException) {
      return error.message;
    }

    return 'Something went wrong while loading weather data.';
  }
}
