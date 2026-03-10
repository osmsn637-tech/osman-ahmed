import '../../../../shared/controllers/scan_debounce_controller.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../move/domain/entities/item_location_summary_entity.dart';
import '../../../move/domain/usecases/get_item_locations_usecase.dart';
import '../../domain/entities/receive_item_params.dart';
import '../../domain/usecases/receive_item_usecase.dart';

class ReceiveState {
  const ReceiveState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.summary,
    this.destinationCode = '',
    this.quantity = '',
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSubmitting;
  final ItemLocationSummaryEntity? summary;
  final String destinationCode;
  final String quantity;
  final String? errorMessage;
  final String? successMessage;

  ReceiveState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    ItemLocationSummaryEntity? summary,
    String? destinationCode,
    String? quantity,
    String? errorMessage,
    String? successMessage,
  }) {
    return ReceiveState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      summary: summary ?? this.summary,
      destinationCode: destinationCode ?? this.destinationCode,
      quantity: quantity ?? this.quantity,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ReceiveController extends ScanDebounceController {
  ReceiveController({
    required GetItemLocationsUseCase getItemLocationsUseCase,
    required ReceiveItemUseCase receiveItemUseCase,
    required SessionController session,
  })  : _getItemLocationsUseCase = getItemLocationsUseCase,
        _receiveItemUseCase = receiveItemUseCase,
        _session = session;

  final GetItemLocationsUseCase _getItemLocationsUseCase;
  final ReceiveItemUseCase _receiveItemUseCase;
  final SessionController _session;

  ReceiveState _state = const ReceiveState();
  ReceiveState get state => _state;

  void onScan(String code) {
    handleScanCode(
      code: code,
      hasLoadedItem: _state.summary != null,
      onFirstScan: loadItem,
      onNextScan: setDestination,
    );
  }

  Future<void> loadItem(String barcode) async {
    runDebounced(action: () async {
      _state = _state.copyWith(
          isLoading: true,
          errorMessage: null,
          successMessage: null,
          destinationCode: '');
      notifyListeners();

      final result = await _getItemLocationsUseCase(barcode);
      result.when(
        success: (data) {
          _state = _state.copyWith(
            isLoading: false,
            summary: data,
            quantity: data.totalQuantity.toString(),
            errorMessage: null,
          );
          notifyListeners();
        },
        failure: (error) {
          _state = _state.copyWith(
              isLoading: false, summary: null, errorMessage: error.toString());
          notifyListeners();
        },
      );
    });
  }

  void setDestination(String code) {
    _state = _state.copyWith(
        destinationCode: code, errorMessage: null, successMessage: null);
    notifyListeners();
  }

  void setQuantity(String qty) {
    _state = _state.copyWith(
        quantity: qty, errorMessage: null, successMessage: null);
    notifyListeners();
  }

  void setDefaultQuantity() {
    final total = _state.summary?.totalQuantity ?? 0;
    setQuantity(total.toString());
  }

  Future<void> submit() async {
    final workerId = _session.state.user?.id;
    if (workerId == null) {
      _state =
          _state.copyWith(errorMessage: 'Session missing. Please login again.');
      notifyListeners();
      return;
    }
    final summary = _state.summary;
    if (summary == null) {
      _state = _state.copyWith(errorMessage: 'Scan an item first.');
      notifyListeners();
      return;
    }

    final toLocationId = int.tryParse(_state.destinationCode);
    if (toLocationId == null) {
      _state =
          _state.copyWith(errorMessage: 'Invalid destination location code.');
      notifyListeners();
      return;
    }
    final qty = int.tryParse(
        _state.quantity.isEmpty ? '${summary.totalQuantity}' : _state.quantity);
    if (qty == null || qty <= 0) {
      _state = _state.copyWith(errorMessage: 'Enter a valid quantity.');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
        isSubmitting: true, errorMessage: null, successMessage: null);
    notifyListeners();

    final params = ReceiveItemParams(
      itemId: summary.itemId,
      toLocationId: toLocationId,
      quantity: qty,
      workerId: workerId,
    );

    final result = await _receiveItemUseCase(params);
    result.when(
      success: (_) {
        _state = _state.copyWith(
          isSubmitting: false,
          successMessage: 'Received successfully',
          errorMessage: null,
        );
        notifyListeners();
      },
      failure: (error) {
        _state = _state.copyWith(
          isSubmitting: false,
          errorMessage: error.toString(),
          successMessage: null,
        );
        notifyListeners();
      },
    );
  }
}
