import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/location_lookup_summary_entity.dart';
import '../../domain/usecases/lookup_items_by_location_usecase.dart';

enum LocationLookupErrorType { validation, notFound, retryable, generic }

class LocationLookupState {
  const LocationLookupState({
    this.isLoading = false,
    this.summary,
    this.errorMessage,
    this.errorType,
    this.lastLocationCode = '',
  });

  final bool isLoading;
  final LocationLookupSummaryEntity? summary;
  final String? errorMessage;
  final LocationLookupErrorType? errorType;
  final String lastLocationCode;

  LocationLookupState copyWith({
    bool? isLoading,
    LocationLookupSummaryEntity? summary,
    String? errorMessage,
    LocationLookupErrorType? errorType,
    String? lastLocationCode,
  }) {
    return LocationLookupState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
      errorType: errorType,
      lastLocationCode: lastLocationCode ?? this.lastLocationCode,
    );
  }
}

class LocationLookupController extends ChangeNotifier {
  LocationLookupController({
    required LookupItemsByLocationUseCase lookupItemsByLocation,
  })  : _lookupItemsByLocation = lookupItemsByLocation,
        _state = const LocationLookupState();

  final LookupItemsByLocationUseCase _lookupItemsByLocation;
  final _cache = <String, LocationLookupSummaryEntity>{};

  LocationLookupState _state;
  LocationLookupState get state => _state;

  Future<void> lookup(String locationCode) async {
    final value = _normalize(locationCode);
    if (value.isEmpty) {
      _state = _state.copyWith(
        errorMessage: 'Enter a valid location barcode',
        errorType: LocationLookupErrorType.validation,
      );
      notifyListeners();
      return;
    }

    if (_cache.containsKey(value)) {
      _state = _state.copyWith(
        summary: _cache[value],
        errorMessage: null,
        errorType: null,
        isLoading: false,
        lastLocationCode: value,
      );
      notifyListeners();
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
      return;
    }

    _state = _state.copyWith(
      isLoading: true,
      errorMessage: null,
      errorType: null,
      lastLocationCode: value,
    );
    notifyListeners();

    final result = await _lookupItemsByLocation(value);
    result.when(
      success: (data) {
        _cache[value] = data;
        _state = _state.copyWith(
          isLoading: false,
          summary: data,
          errorMessage: null,
          errorType: null,
        );
        notifyListeners();
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      },
      failure: (error) {
        final mapped = _mapError(error);
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: mapped.$1,
          errorType: mapped.$2,
          summary: null,
        );
        notifyListeners();
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.alert);
      },
    );
  }

  Future<void> retry() => lookup(_state.lastLocationCode);

  (String, LocationLookupErrorType) _mapError(Object error) {
    if (error is AppException &&
        (error is UnauthorizedException || error is AuthExpiredException)) {
      final message = error.message.trim().isEmpty
          ? 'Lookup authorization failed'
          : error.message;
      return (message, LocationLookupErrorType.retryable);
    }
    if (error is ValidationException) {
      if (error.message.toLowerCase().contains('not found')) {
        return ('Location not found', LocationLookupErrorType.notFound);
      }
      return (error.message, LocationLookupErrorType.validation);
    }
    if (error is NetworkException ||
        error is ServerException ||
        error is UnknownException) {
      final message = error is AppException && error.message.trim().isNotEmpty
          ? error.message
          : 'Could not load location details';
      return (message, LocationLookupErrorType.retryable);
    }

    final message = error.toString();
    if (message.toLowerCase().contains('not found')) {
      return ('Location not found', LocationLookupErrorType.notFound);
    }
    return (message, LocationLookupErrorType.generic);
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '').trim();
  }
}
