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
    this.quantity = 0,
    this.reason,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
  });

  static const Object _unset = Object();

  final int? selectedLocationId;
  final String? selectedLocationCode;
  final int quantity;
  final String? reason;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;
  final bool success;

  bool get canSubmit =>
      selectedLocationId != null &&
      quantity > 0 &&
      reason != null &&
      reason!.trim().isNotEmpty &&
      !isSubmitting;

  ItemAdjustmentState copyWith({
    Object? selectedLocationId = _unset,
    Object? selectedLocationCode = _unset,
    int? quantity,
    Object? reason = _unset,
    String? note,
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
      quantity: quantity ?? this.quantity,
      reason: reason == _unset ? this.reason : reason as String?,
      note: note ?? this.note,
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

  static const List<String> defaultReasons = <String>[
    'Damaged',
    'Return',
    'Count Correction',
    'Cycle Count',
    'Other',
  ];

  ItemAdjustmentState _state = const ItemAdjustmentState();
  ItemAdjustmentState get state => _state;

  List<String> get reasons => defaultReasons;

  void selectLocation(ItemLocationEntity location) {
    _setState(
      _state.copyWith(
        selectedLocationId: location.locationId,
        selectedLocationCode: location.code,
        errorMessage: null,
        success: false,
      ),
    );
  }

  void increment() {
    _setState(
      _state.copyWith(
        quantity: _state.quantity + 1,
        errorMessage: null,
        success: false,
      ),
    );
  }

  void decrement() {
    _setState(
      _state.copyWith(
        quantity: _state.quantity > 0 ? _state.quantity - 1 : 0,
        errorMessage: null,
        success: false,
      ),
    );
  }

  void setReason(String value) {
    final normalized = value.trim();
    _setState(
      _state.copyWith(
        reason: normalized.isEmpty ? null : normalized,
        errorMessage: null,
        success: false,
      ),
    );
  }

  void setNote(String value) {
    _setState(
      _state.copyWith(
        note: value,
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
          errorMessage: 'Select a location, quantity, and reason.',
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
        newQuantity: _state.quantity,
        reason: _state.reason!,
        workerId: workerId,
        note: _state.note.trim().isEmpty ? null : _state.note.trim(),
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
}
