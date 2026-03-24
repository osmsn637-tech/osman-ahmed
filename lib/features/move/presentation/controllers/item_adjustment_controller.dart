import 'package:flutter/foundation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/item_location_entity.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/stock_adjustment_params.dart';

class ItemAdjustmentState {
  const ItemAdjustmentState({
    this.selectedLocationId,
    this.selectedLocationCode,
    this.selectedLocationType,
    this.quantity = 0,
    this.hasQuantityInput = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  static const Object _unset = Object();

  final int? selectedLocationId;
  final String? selectedLocationCode;
  final String? selectedLocationType;
  final int quantity;
  final bool hasQuantityInput;
  final bool isSubmitting;
  final String? errorMessage;
  final bool success;

  bool get canSubmit =>
      selectedLocationCode != null &&
      selectedLocationCode!.trim().isNotEmpty &&
      hasQuantityInput &&
      !isSubmitting;

  ItemAdjustmentState copyWith({
    Object? selectedLocationId = _unset,
    Object? selectedLocationCode = _unset,
    Object? selectedLocationType = _unset,
    int? quantity,
    bool? hasQuantityInput,
    bool? isSubmitting,
    Object? errorMessage = _unset,
    bool? success,
  }) {
    return ItemAdjustmentState(
      selectedLocationId: selectedLocationId == _unset
          ? this.selectedLocationId
          : selectedLocationId as int?,
      selectedLocationCode: selectedLocationCode == _unset
          ? this.selectedLocationCode
          : selectedLocationCode as String?,
      selectedLocationType: selectedLocationType == _unset
          ? this.selectedLocationType
          : selectedLocationType as String?,
      quantity: quantity ?? this.quantity,
      hasQuantityInput: hasQuantityInput ?? this.hasQuantityInput,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      success: success ?? this.success,
    );
  }
}

class ItemAdjustmentController extends ChangeNotifier {
  ItemAdjustmentController({
    required Future<Result<void>> Function(StockAdjustmentParams params)
        adjustStock,
    required SessionController session,
  })  : _adjustStock = adjustStock,
        _session = session;

  final Future<Result<void>> Function(StockAdjustmentParams params) _adjustStock;
  final SessionController _session;

  static const String _defaultReason = 'Count Correction';

  ItemAdjustmentState _state = const ItemAdjustmentState();
  ItemAdjustmentState get state => _state;

  void selectLocation(ItemLocationEntity location) {
    _setState(
      _state.copyWith(
        selectedLocationId: location.locationId,
        selectedLocationCode: location.code,
        selectedLocationType: location.type,
        errorMessage: null,
        success: false,
      ),
    );
  }

  void updateSelectedLocationCode(
    String value, {
    List<ItemLocationEntity> knownLocations = const <ItemLocationEntity>[],
  }) {
    final normalized = value.trim();
    final matched = knownLocations.cast<ItemLocationEntity?>().firstWhere(
          (location) =>
              location?.code.trim().toUpperCase() == normalized.toUpperCase(),
          orElse: () => null,
        );

    _setState(
      _state.copyWith(
        selectedLocationCode: value,
        selectedLocationId: matched?.locationId ?? _stableIntFromString(normalized),
        selectedLocationType:
            matched?.type.isNotEmpty == true ? matched!.type : _inferType(normalized),
        errorMessage: null,
        success: false,
      ),
    );
  }

  void setQuantityText(String value) {
    final normalized = value.trim();
    final parsed = int.tryParse(normalized);
    final hasExplicitQuantity =
        normalized.isNotEmpty && parsed != null && parsed >= 0;
    _setState(
      _state.copyWith(
        quantity: hasExplicitQuantity ? parsed : 0,
        hasQuantityInput: hasExplicitQuantity,
        errorMessage: null,
        success: false,
      ),
    );
  }

  Future<void> submitForItem(ItemLocationSummaryEntity summary) async {
    if (_state.isSubmitting) return;

    final workerId = _session.state.user?.id;
    if (workerId == null) {
      _setState(
        _state.copyWith(
          errorMessage: 'Session missing. Please re-login.',
          success: false,
        ),
      );
      return;
    }

    if (!_state.canSubmit) {
      _setState(
        _state.copyWith(
          errorMessage: 'Select a location and quantity.',
          success: false,
        ),
      );
      return;
    }

    _setState(
      _state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        success: false,
      ),
    );

    final result = await _adjustStock(
      StockAdjustmentParams(
        itemId: summary.itemId,
        locationId: _state.selectedLocationId!,
        locationBarcode: (_state.selectedLocationCode ?? '').trim(),
        newQuantity: _state.quantity,
        reason: _defaultReason,
        workerId: workerId,
      ),
    );

    result.when(
      success: (_) {
        _setState(
          _state.copyWith(
            isSubmitting: false,
            errorMessage: null,
            success: true,
          ),
        );
      },
      failure: (error) {
        _setState(
          _state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
            success: false,
          ),
        );
      },
    );
  }

  void _setState(ItemAdjustmentState nextState) {
    _state = nextState;
    notifyListeners();
  }

  static int? _stableIntFromString(String value) {
    if (value.isEmpty) return null;
    var hash = 0;
    for (final unit in value.toUpperCase().codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash == 0 ? null : hash;
  }

  static String _inferType(String code) {
    final upper = code.toUpperCase();
    if (upper.contains('BLK')) return 'bulk';
    if (upper.isEmpty) return '';
    return 'shelf';
  }
}
