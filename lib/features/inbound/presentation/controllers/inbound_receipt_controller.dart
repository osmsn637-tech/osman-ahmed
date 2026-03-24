import 'package:flutter/foundation.dart';

import '../../domain/entities/inbound_entities.dart';
import '../../domain/repositories/inbound_repository.dart';

class InboundReceiptController extends ChangeNotifier {
  InboundReceiptController(
    this._repository, {
    required this.receiptId,
    InboundReceiptScanResult? initialScanResult,
  }) : _receipt = initialScanResult?.toReceipt() {
    if (_receipt == null) {
      loadReceipt();
    }
  }

  final InboundRepository _repository;
  final String receiptId;

  InboundReceipt? _receipt;
  String? _selectedItemId;
  String? _errorMessage;
  String? _scanErrorMessage;
  bool _isLoading = false;
  bool _isStarting = false;
  bool _isSubmitting = false;
  bool _detailOpenedByScan = false;
  bool _detailBarcodeValidated = false;

  InboundReceipt? get receipt => _receipt;
  InboundReceiptItem? get selectedItem {
    final currentReceipt = _receipt;
    final itemId = _selectedItemId;
    if (currentReceipt == null || itemId == null) return null;
    for (final item in currentReceipt.items) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  String? get errorMessage => _errorMessage;
  String? get scanErrorMessage => _scanErrorMessage;
  bool get isLoading => _isLoading;
  bool get isStarting => _isStarting;
  bool get isSubmitting => _isSubmitting;
  bool get isShowingDetail => _selectedItemId != null;
  bool get detailOpenedByScan => _detailOpenedByScan;
  bool get detailBarcodeValidated => _detailBarcodeValidated;
  bool get isQuantityEnabled => _detailOpenedByScan || _detailBarcodeValidated;
  bool get canReceiveItems => (_receipt?.status ?? 'pending') == 'receiving';

  Future<void> loadReceipt() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getReceipt(receiptId);
    result.when(
      success: (receipt) {
        _receipt = receipt;
      },
      failure: (error) {
        _errorMessage = _messageForError(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void openItem(String itemId, {required bool openedByScan}) {
    if (!canReceiveItems) return;
    _selectedItemId = itemId;
    _detailOpenedByScan = openedByScan;
    _detailBarcodeValidated = openedByScan;
    _scanErrorMessage = null;
    notifyListeners();
  }

  void closeDetail() {
    _selectedItemId = null;
    _detailOpenedByScan = false;
    _detailBarcodeValidated = false;
    _scanErrorMessage = null;
    notifyListeners();
  }

  Future<void> scanReceiptItem(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty || !canReceiveItems) return;

    final result = await _repository.scanReceiptItem(
      receiptId: receiptId,
      barcode: normalized,
    );

    result.when(
      success: (item) {
        openItem(item.id, openedByScan: true);
      },
      failure: (error) {
        _scanErrorMessage = _messageForError(error);
        notifyListeners();
      },
    );
  }

  Future<void> startReceiving() async {
    if (_isStarting || canReceiveItems) return;

    _isStarting = true;
    _scanErrorMessage = null;
    notifyListeners();

    final result = await _repository.startReceipt(receiptId);
    result.when(
      success: (receipt) {
        _receipt = receipt;
      },
      failure: (error) {
        _scanErrorMessage = _messageForError(error);
      },
    );

    _isStarting = false;
    notifyListeners();
  }

  void validateSelectedItemBarcode(String barcode) {
    final item = selectedItem;
    if (item == null) return;
    final normalized = barcode.trim().toUpperCase();
    if (normalized.isEmpty) return;
    if (item.barcode.trim().toUpperCase() != normalized) {
      _scanErrorMessage = 'Scanned item is not in this receipt line.';
      notifyListeners();
      return;
    }
    _detailBarcodeValidated = true;
    _scanErrorMessage = null;
    notifyListeners();
  }

  Future<bool> confirmSelectedItemQuantity(int quantity) async {
    final item = selectedItem;
    if (item == null || quantity <= 0) return false;

    _isSubmitting = true;
    notifyListeners();

    final result = await _repository.confirmReceiptItem(
      receiptId: receiptId,
      itemId: item.id,
      quantity: quantity,
    );

    var succeeded = false;
    result.when(
      success: (receipt) {
        _receipt = receipt;
        _selectedItemId = null;
        _detailOpenedByScan = false;
        _detailBarcodeValidated = false;
        _scanErrorMessage = null;
        succeeded = true;
      },
      failure: (error) {
        _scanErrorMessage = _messageForError(error);
      },
    );

    _isSubmitting = false;
    notifyListeners();
    return succeeded;
  }

  String quantityLabel(InboundReceiptItem item) {
    if (item.receivedQuantity > 0) {
      return '${item.receivedQuantity} received';
    }
    return 'Expected Qty: ${item.expectedQuantity}';
  }

  bool isItemMatched(InboundReceiptItem item) {
    return item.receivedQuantity > 0 &&
        item.receivedQuantity == item.expectedQuantity;
  }

  String _messageForError(Object error) {
    final message = error.toString();
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('ArgumentError: ', '')
        .trim();
  }
}
