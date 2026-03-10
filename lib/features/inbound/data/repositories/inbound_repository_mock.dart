import '../../../dashboard/domain/usecases/route_task_from_event_usecase.dart';
import '../../domain/entities/inbound_entities.dart';
import '../../domain/repositories/inbound_repository.dart';

class InboundRepositoryMock implements InboundRepository {
  InboundRepositoryMock(this._routeTaskFromEventUseCase);

  final RouteTaskFromEventUseCase _routeTaskFromEventUseCase;

  static final Map<int, InboundDocument> _store = {};
  static int _nextId = 100;

  List<InboundDocument> _getMockDocuments() {
    if (_store.isEmpty) {
      _store[1] = InboundDocument(
        id: 1,
        documentNumber: 'IB-2024-001',
        supplierName: 'Supplier ABC',
        status: InboundStatus.pending,
        items: const [
          InboundItem(
            id: 101,
            itemId: 1001,
            itemName: 'Widget A',
            barcode: '123456789',
            expectedQuantity: 50,
            receivedQuantity: 0,
            toLocation: 'A01-01-01',
          ),
          InboundItem(
            id: 102,
            itemId: 1002,
            itemName: 'Widget B',
            barcode: '987654321',
            expectedQuantity: 25,
            receivedQuantity: 0,
            toLocation: 'A01-01-02',
          ),
        ],
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      _store[2] = InboundDocument(
        id: 2,
        documentNumber: 'IB-2024-002',
        supplierName: 'Supplier XYZ',
        status: InboundStatus.inProgress,
        items: const [
          InboundItem(
            id: 201,
            itemId: 1003,
            itemName: 'Gadget C',
            barcode: '555666777',
            expectedQuantity: 100,
            receivedQuantity: 75,
            toLocation: 'B02-03-01',
          ),
        ],
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      _store[3] = InboundDocument(
        id: 3,
        documentNumber: 'IB-2024-003',
        supplierName: 'Supplier DEF',
        status: InboundStatus.completed,
        items: const [
          InboundItem(
            id: 301,
            itemId: 1004,
            itemName: 'Tool D',
            barcode: '111222333',
            expectedQuantity: 10,
            receivedQuantity: 10,
            toLocation: 'C03-04-01',
          ),
        ],
        createdBy: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    }
    return _store.values.toList();
  }

  @override
  Future<List<InboundDocument>> getInboundDocuments() async {
    return _getMockDocuments();
  }

  @override
  Future<List<InboundDocument>> getInboundDocumentsByStatus(InboundStatus status) async {
    return _getMockDocuments().where((doc) => doc.status == status).toList();
  }

  @override
  Future<InboundDocument> createInboundDocument(CreateInboundParams params) async {
    final items = params.items.map((item) => InboundItem(
      id: _nextId++,
      itemId: item.itemId,
      itemName: item.itemName,
      barcode: item.barcode,
      expectedQuantity: item.expectedQuantity,
      receivedQuantity: 0,
      toLocation: item.toLocation,
    )).toList();

    final doc = InboundDocument(
      id: _nextId++,
      documentNumber: params.documentNumber,
      supplierName: params.supplierName,
      status: InboundStatus.pending,
      items: items,
      createdBy: 1, // Mock user ID
      createdAt: DateTime.now(),
      expectedArrival: params.expectedArrival,
    );

    _store[doc.id] = doc;
    return doc;
  }

  @override
  Future<InboundDocument> startInboundDocument(int inboundId) async {
    final doc = _store[inboundId];
    if (doc == null) throw Exception('Inbound document not found');

    final updated = doc.copyWith(
      status: InboundStatus.inProgress,
      startedAt: DateTime.now(),
    );
    _store[inboundId] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> receiveInboundItem(ReceiveInboundItemParams params) async {
    final doc = _store[params.inboundId];
    if (doc == null) throw Exception('Inbound document not found');
    if (params.receivedQuantity <= 0) return doc;

    final itemIndex = doc.items.indexWhere((item) => item.itemId == params.itemId);
    if (itemIndex == -1) {
      throw Exception('Inbound item not found');
    }
    final targetItem = doc.items[itemIndex];

    final updatedItems = doc.items.map((item) {
      if (item.itemId == params.itemId) {
        return item.copyWith(
          receivedQuantity: item.receivedQuantity + params.receivedQuantity,
          notes: params.notes,
        );
      }
      return item;
    }).toList();

    final isReturn = params.isReturn ||
        ((params.notes ?? '').toLowerCase().contains('return'));
    final sourceEventId = 'inbound:${params.inboundId}:item:${params.itemId}:qty:${params.receivedQuantity}:return:$isReturn';
    final event = isReturn
        ? TaskTriggerEvent.inboundReturn(
            sourceEventId: sourceEventId,
            itemId: targetItem.itemId,
            itemName: targetItem.itemName,
            quantity: params.receivedQuantity,
            toLocation: targetItem.toLocation,
            createdBy: doc.createdBy.toString(),
          )
        : TaskTriggerEvent.inboundReceive(
            sourceEventId: sourceEventId,
            itemId: targetItem.itemId,
            itemName: targetItem.itemName,
            quantity: params.receivedQuantity,
            toLocation: targetItem.toLocation,
            createdBy: doc.createdBy.toString(),
          );
    await _routeTaskFromEventUseCase.execute(event);

    final updated = doc.copyWith(items: updatedItems);
    _store[params.inboundId] = updated;
    return updated;
  }

  @override
  Future<InboundDocument> completeInboundDocument(int inboundId) async {
    final doc = _store[inboundId];
    if (doc == null) throw Exception('Inbound document not found');

    final updated = doc.copyWith(
      status: InboundStatus.completed,
      completedAt: DateTime.now(),
    );
    _store[inboundId] = updated;
    return updated;
  }
}
