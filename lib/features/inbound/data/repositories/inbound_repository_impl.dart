import '../../../../core/utils/result.dart';
import '../../domain/entities/inbound_entities.dart';
import '../../domain/repositories/inbound_repository.dart';
import '../datasources/inbound_remote_data_source.dart';

class InboundRepositoryImpl implements InboundRepository {
  final Map<int, InboundDocument> _store = <int, InboundDocument>{};
  int _nextId = 100;
  final InboundRemoteDataSource _remoteDataSource;

  InboundRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<InboundDocument>> getInboundDocuments() async {
    return _store.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<List<InboundDocument>> getInboundDocumentsByStatus(
    InboundStatus status,
  ) async {
    return (await getInboundDocuments())
        .where((document) => document.status == status)
        .toList(growable: false);
  }

  @override
  Future<InboundDocument> createInboundDocument(
      CreateInboundParams params) async {
    final items = params.items
        .map(
          (item) => InboundItem(
            id: _nextId++,
            itemId: item.itemId,
            itemName: item.itemName,
            barcode: item.barcode,
            expectedQuantity: item.expectedQuantity,
            toLocation: item.toLocation,
          ),
        )
        .toList(growable: false);

    final document = InboundDocument(
      id: _nextId++,
      documentNumber: params.documentNumber,
      supplierName: params.supplierName,
      status: InboundStatus.pending,
      items: items,
      createdBy: 1,
      createdAt: DateTime.now(),
      expectedArrival: params.expectedArrival,
    );

    _store[document.id] = document;
    return document;
  }

  @override
  Future<InboundDocument> startInboundDocument(int inboundId) async {
    final document = _requireDocument(inboundId);
    final updated = document.copyWith(
      status: InboundStatus.inProgress,
      startedAt: DateTime.now(),
    );
    _store[inboundId] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> receiveInboundItem(
      ReceiveInboundItemParams params) async {
    final document = _requireDocument(params.inboundId);
    if (params.receivedQuantity <= 0) return document;

    final itemIndex =
        document.items.indexWhere((item) => item.itemId == params.itemId);
    if (itemIndex == -1) {
      throw Exception('Inbound item not found');
    }

    final updatedItems = document.items
        .map(
          (item) => item.itemId != params.itemId
              ? item
              : item.copyWith(
                  receivedQuantity:
                      item.receivedQuantity + params.receivedQuantity,
                  notes: params.notes,
                ),
        )
        .toList(growable: false);

    final updated = document.copyWith(items: updatedItems);
    _store[params.inboundId] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> completeInboundDocument(int inboundId) async {
    final document = _requireDocument(inboundId);
    final updated = document.copyWith(
      status: InboundStatus.completed,
      completedAt: DateTime.now(),
    );
    _store[inboundId] = updated;
    return updated;
  }

  @override
  Future<Result<InboundReceiptScanResult>> scanReceipt(String barcode) {
    return _remoteDataSource.scanReceipt(barcode);
  }

  @override
  Future<Result<InboundReceipt>> getReceipt(String receiptId) {
    return _remoteDataSource.getReceipt(receiptId);
  }

  @override
  Future<Result<InboundReceipt>> startReceipt(String receiptId) {
    return _remoteDataSource.startReceipt(receiptId);
  }

  @override
  Future<Result<InboundReceiptItem>> scanReceiptItem({
    required String receiptId,
    required String barcode,
  }) {
    return _remoteDataSource.scanReceiptItem(
      receiptId: receiptId,
      barcode: barcode,
    );
  }

  @override
  Future<Result<InboundReceipt>> confirmReceiptItem({
    required String receiptId,
    required String itemId,
    required int quantity,
    required DateTime expirationDate,
  }) {
    return _remoteDataSource.confirmReceiptItem(
      receiptId: receiptId,
      itemId: itemId,
      quantity: quantity,
      expirationDate: expirationDate,
    );
  }

  InboundDocument _requireDocument(int inboundId) {
    final document = _store[inboundId];
    if (document == null) {
      throw Exception('Inbound document not found');
    }
    return document;
  }
}
