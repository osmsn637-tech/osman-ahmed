import 'package:flutter/foundation.dart';

import '../../domain/entities/stock_adjustment_params.dart';
import '../../domain/usecases/adjust_stock_usecase.dart';
import '../../../auth/presentation/providers/session_provider.dart';

class StockAdjustmentState {
  const StockAdjustmentState({
    this.itemId = '',
    this.locationId = '',
    this.newQuantity = '',
    this.reason = 'Count Correction',
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final String itemId;
  final String locationId;
  final String newQuantity;
  final String reason;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  StockAdjustmentState copyWith({
    String? itemId,
    String? locationId,
    String? newQuantity,
    String? reason,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return StockAdjustmentState(
      itemId: itemId ?? this.itemId,
      locationId: locationId ?? this.locationId,
      newQuantity: newQuantity ?? this.newQuantity,
      reason: reason ?? this.reason,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class StockAdjustmentController extends ChangeNotifier {
  StockAdjustmentController({required AdjustStockUseCase adjustStockUseCase, required SessionController session})
      : _adjustStockUseCase = adjustStockUseCase,
        _session = session;

  final AdjustStockUseCase _adjustStockUseCase;
  final SessionController _session;

  StockAdjustmentState _state = const StockAdjustmentState();
  StockAdjustmentState get state => _state;

  final List<String> reasons = const ['Count Correction', 'Damage', 'Cycle Count', 'Other'];

  void updateItemId(String value) => _setState(state.copyWith(itemId: value, errorMessage: null, successMessage: null));
  void updateLocationId(String value) =>
      _setState(state.copyWith(locationId: value, errorMessage: null, successMessage: null));
  void updateQuantity(String value) =>
      _setState(state.copyWith(newQuantity: value, errorMessage: null, successMessage: null));
  void updateReason(String value) => _setState(state.copyWith(reason: value, errorMessage: null, successMessage: null));

  void handleScan(String barcode) {
    if (barcode.isEmpty) return;

    if (state.itemId.isEmpty) {
      _setState(state.copyWith(itemId: barcode, errorMessage: null, successMessage: null));
      return;
    }

    if (state.locationId.isEmpty) {
      _setState(state.copyWith(locationId: barcode, errorMessage: null, successMessage: null));
      return;
    }

    // If both are filled, prefer updating location with the latest scan
    _setState(state.copyWith(locationId: barcode, errorMessage: null, successMessage: null));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final workerId = _session.state.user?.id;
    final itemId = int.tryParse(state.itemId);
    final locationId = int.tryParse(state.locationId);
    final qty = int.tryParse(state.newQuantity);

    if (workerId == null) {
      _setState(state.copyWith(errorMessage: 'Session missing. Please re-login.'));
      return;
    }
    if (itemId == null || locationId == null || qty == null) {
      _setState(state.copyWith(errorMessage: 'Please enter valid item, location, and quantity.'));
      return;
    }

    _setState(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));

    final result = await _adjustStockUseCase(StockAdjustmentParams(
      itemId: itemId,
      locationId: locationId,
      newQuantity: qty,
      reason: state.reason,
      workerId: workerId,
    ));

    result.when(
      success: (_) {
        _setState(state.copyWith(
          isSubmitting: false,
          successMessage: 'Stock adjusted successfully.',
          itemId: '',
          locationId: '',
          newQuantity: '',
        ));
      },
      failure: (error) {
        _setState(state.copyWith(
          isSubmitting: false,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void _setState(StockAdjustmentState newState) {
    _state = newState;
    notifyListeners();
  }
}
