import '../../../../shared/controllers/scan_debounce_controller.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/item_location_entity.dart';
import '../../domain/entities/item_location_summary_entity.dart';
import '../../domain/entities/move_item_params.dart';
import '../../domain/usecases/get_item_locations_usecase.dart';
import '../../domain/usecases/move_item_usecase.dart';

class MoveState {
  const MoveState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.summary,
    this.destinationCode = '',
    this.moveQuantity = '',
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSubmitting;
  final ItemLocationSummaryEntity? summary;
  final String destinationCode;
  final String moveQuantity;
  final String? errorMessage;
  final String? successMessage;

  MoveState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    ItemLocationSummaryEntity? summary,
    String? destinationCode,
    String? moveQuantity,
    String? errorMessage,
    String? successMessage,
  }) {
    return MoveState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      summary: summary ?? this.summary,
      destinationCode: destinationCode ?? this.destinationCode,
      moveQuantity: moveQuantity ?? this.moveQuantity,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class MoveController extends ScanDebounceController {
  MoveController({
    required GetItemLocationsUseCase getItemLocationsUseCase,
    required MoveItemUseCase moveItemUseCase,
    required SessionController session,
  })  : _getItemLocationsUseCase = getItemLocationsUseCase,
        _moveItemUseCase = moveItemUseCase,
        _session = session;

  final GetItemLocationsUseCase _getItemLocationsUseCase;
  final MoveItemUseCase _moveItemUseCase;
  final SessionController _session;

  MoveState _state = const MoveState();
  MoveState get state => _state;

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
            moveQuantity: data.totalQuantity.toString(),
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
        moveQuantity: qty, errorMessage: null, successMessage: null);
    notifyListeners();
  }

  void setFullQuantity() {
    final total = _state.summary?.totalQuantity ?? 0;
    setQuantity(total.toString());
  }

  Future<void> submitMove() async {
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

    final fromLocation = _selectFromLocation(summary.locations);
    if (fromLocation == null) {
      _state =
          _state.copyWith(errorMessage: 'No source location with stock found.');
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
    final qty = int.tryParse(_state.moveQuantity.isEmpty
        ? '${summary.totalQuantity}'
        : _state.moveQuantity);
    if (qty == null || qty <= 0) {
      _state = _state.copyWith(errorMessage: 'Enter a valid quantity.');
      notifyListeners();
      return;
    }
    if (qty > summary.totalQuantity) {
      _state = _state.copyWith(
          errorMessage:
              'Quantity exceeds available (${summary.totalQuantity}).');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
        isSubmitting: true, errorMessage: null, successMessage: null);
    notifyListeners();

    final params = MoveItemParams(
      itemId: summary.itemId,
      barcode: summary.barcode,
      fromLocationId: fromLocation.locationId,
      toLocationId: toLocationId,
      quantity: qty,
      workerId: workerId,
    );

    final result = await _moveItemUseCase.execute(params);
    result.when(
      success: (_) {
        _state = _state.copyWith(
          isSubmitting: false,
          successMessage: 'Move completed',
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

  ItemLocationEntity? _selectFromLocation(List<ItemLocationEntity> locations) {
    try {
      return locations.firstWhere((loc) => loc.quantity > 0);
    } catch (_) {
      return null;
    }
  }
}
