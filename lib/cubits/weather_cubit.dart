import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/weather_repository.dart';

abstract class WeatherState {
  const WeatherState();
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherSuccess extends WeatherState {
  const WeatherSuccess(this.data);

  final WeatherRepositoryResult data;
}

class WeatherError extends WeatherState {
  const WeatherError(this.message);

  final String message;
}

class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit({WeatherRepository? repository})
      : _repository = repository ?? WeatherRepository(),
        super(const WeatherInitial());

  final WeatherRepository _repository;

  Future<void> fetchWeatherByLocation() async {
    emit(const WeatherLoading());

    try {
      final result = await _repository.getWeatherByCurrentLocation();
      emit(WeatherSuccess(result));
    } catch (e) {
      emit(WeatherError(_messageFromError(e)));
    }
  }

  Future<void> fetchWeatherByCity(String city) async {
    final query = city.trim();
    if (query.isEmpty) {
      emit(const WeatherError('Please enter a city name.'));
      return;
    }

    emit(const WeatherLoading());

    try {
      final result = await _repository.getWeatherByCity(query);
      emit(WeatherSuccess(result));
    } catch (e) {
      emit(WeatherError(_messageFromError(e)));
    }
  }

  String _messageFromError(Object error) {
    if (error is WeatherRepositoryException) {
      return error.message;
    }

    return 'Something went wrong while loading weather data.';
  }
}
