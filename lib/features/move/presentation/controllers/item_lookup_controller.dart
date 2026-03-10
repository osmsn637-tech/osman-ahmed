import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/usecases/lookup_item_by_barcode_usecase.dart';

enum ItemLookupErrorType { validation, notFound, retryable, generic }

class ItemLookupState {
  const ItemLookupState({
    this.isLoading = false,
    this.summary,
    this.errorMessage,
    this.errorType,
    this.lastBarcode = '',
  });

  final bool isLoading;
  final ItemLocationSummaryEntity? summary;
  final String? errorMessage;
  final ItemLookupErrorType? errorType;
  final String lastBarcode;

  ItemLookupState copyWith({
    bool? isLoading,
    ItemLocationSummaryEntity? summary,
    String? errorMessage,
    ItemLookupErrorType? errorType,
    String? lastBarcode,
  }) {
    return ItemLookupState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
      errorType: errorType,
      lastBarcode: lastBarcode ?? this.lastBarcode,
    );
  }
}

class ItemLookupController extends ChangeNotifier {
  ItemLookupController(
      {required LookupItemByBarcodeUseCase lookupItemByBarcode})
      : _lookupItemByBarcode = lookupItemByBarcode,
        _state = const ItemLookupState();

  final LookupItemByBarcodeUseCase _lookupItemByBarcode;
  final _cache = <String, ItemLocationSummaryEntity>{};

  ItemLookupState _state;
  ItemLookupState get state => _state;

  void onBarcodeChanged(String barcode) {
    final normalized = _normalizeBarcode(barcode);
    _state = _state.copyWith(
      lastBarcode: normalized,
      errorMessage: null,
      errorType: null,
    );
    notifyListeners();

    // Honeywell wedge scanners usually append Enter/newline.
    if (barcode.contains('\n') && normalized.isNotEmpty) {
      lookup(normalized);
    }
  }

  Future<void> lookup(String barcode) async {
    final value = _normalizeBarcode(barcode);
    if (value.isEmpty) {
      _state = _state.copyWith(
        errorMessage: 'Enter a valid barcode',
        errorType: ItemLookupErrorType.validation,
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
        lastBarcode: value,
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
      lastBarcode: value,
    );
    notifyListeners();

    final result = await _lookupItemByBarcode(value);
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

  Future<void> retry() => lookup(_state.lastBarcode);

  void clear() {
    _state = const ItemLookupState();
    notifyListeners();
  }

  (String, ItemLookupErrorType) _mapError(Object error) {
    if (error is AppException &&
        (error is UnauthorizedException || error is AuthExpiredException)) {
      final message = error.message.trim().isEmpty
          ? 'Lookup authorization failed'
          : error.message;
      return (message, ItemLookupErrorType.retryable);
    }
    if (error is ValidationException) {
      if (error.message.toLowerCase().contains('not found')) {
        return ('Item not found', ItemLookupErrorType.notFound);
      }
      return (error.message, ItemLookupErrorType.validation);
    }
    if (error is NetworkException ||
        error is ServerException ||
        error is UnknownException) {
      final message = error is AppException && error.message.trim().isNotEmpty
          ? error.message
          : 'Could not load item details';
      return (message, ItemLookupErrorType.retryable);
    }

    final message = error.toString();
    if (message.toLowerCase().contains('not found')) {
      return ('Item not found', ItemLookupErrorType.notFound);
    }
    return (message, ItemLookupErrorType.generic);
  }

  String _normalizeBarcode(String barcode) {
    return barcode
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '')
        .trim();
  }
}
