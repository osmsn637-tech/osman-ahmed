import 'package:equatable/equatable.dart';

enum InboundStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed');

  const InboundStatus(this.value);
  final String value;

  static InboundStatus fromString(String value) {
    return InboundStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InboundStatus.pending,
    );
  }
}

class InboundDocument extends Equatable {
  const InboundDocument({
    required this.id,
    required this.documentNumber,
    required this.supplierName,
    required this.status,
    required this.items,
    required this.createdBy,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.expectedArrival,
  });

  final int id;
  final String documentNumber;
  final String supplierName;
  final InboundStatus status;
  final List<InboundItem> items;
  final int createdBy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? expectedArrival;

  int get totalItems => items.length;
  int get receivedItems =>
      items.where((item) => item.receivedQuantity > 0).length;
  bool get isPending => status == InboundStatus.pending;
  bool get isInProgress => status == InboundStatus.inProgress;
  bool get isCompleted => status == InboundStatus.completed;

  InboundDocument copyWith({
    int? id,
    String? documentNumber,
    String? supplierName,
    InboundStatus? status,
    List<InboundItem>? items,
    int? createdBy,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expectedArrival,
  }) {
    return InboundDocument(
      id: id ?? this.id,
      documentNumber: documentNumber ?? this.documentNumber,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      items: items ?? this.items,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      expectedArrival: expectedArrival ?? this.expectedArrival,
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentNumber,
        supplierName,
        status,
        items,
        createdBy,
        createdAt,
        startedAt,
        completedAt,
        expectedArrival,
      ];
}

class InboundItem extends Equatable {
  const InboundItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    this.receivedQuantity = 0,
    required this.toLocation,
    this.notes,
  });

  final int id;
  final int itemId;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final int receivedQuantity;
  final String toLocation;
  final String? notes;

  bool get isReceived => receivedQuantity > 0;
  bool get isFullyReceived => receivedQuantity >= expectedQuantity;

  InboundItem copyWith({
    int? id,
    int? itemId,
    String? itemName,
    String? barcode,
    int? expectedQuantity,
    int? receivedQuantity,
    String? toLocation,
    String? notes,
  }) {
    return InboundItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      toLocation: toLocation ?? this.toLocation,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemName,
        barcode,
        expectedQuantity,
        receivedQuantity,
        toLocation,
        notes,
      ];
}

class CreateInboundParams {
  const CreateInboundParams({
    required this.documentNumber,
    required this.supplierName,
    required this.items,
    this.expectedArrival,
  });

  final String documentNumber;
  final String supplierName;
  final List<CreateInboundItem> items;
  final DateTime? expectedArrival;
}

class CreateInboundItem {
  const CreateInboundItem({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    required this.toLocation,
  });

  final int itemId;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final String toLocation;
}

class ReceiveInboundItemParams {
  const ReceiveInboundItemParams({
    required this.inboundId,
    required this.itemId,
    required this.receivedQuantity,
    required this.locationId,
    required this.expirationDate,
    this.isReturn = false,
    this.notes,
  });

  final int inboundId;
  final int itemId;
  final int receivedQuantity;
  final int locationId;
  final DateTime expirationDate;
  final bool isReturn;
  final String? notes;
}

class InboundReceiptScanResult extends Equatable {
  const InboundReceiptScanResult({
    required this.barcode,
    required this.receiptId,
    required this.poNumber,
    this.status = 'pending',
    this.items = const <InboundReceiptItem>[],
  });

  final String barcode;
  final String receiptId;
  final String poNumber;
  final String status;
  final List<InboundReceiptItem> items;

  InboundReceipt toReceipt() {
    return InboundReceipt(
      id: receiptId,
      poNumber: poNumber,
      status: status,
      items: items,
    );
  }

  @override
  List<Object?> get props => [barcode, receiptId, poNumber, status, items];
}

class InboundReceipt extends Equatable {
  const InboundReceipt({
    required this.id,
    required this.poNumber,
    required this.items,
    this.status = 'pending',
  });

  final String id;
  final String poNumber;
  final String status;
  final List<InboundReceiptItem> items;

  InboundReceipt copyWith({
    String? id,
    String? poNumber,
    String? status,
    List<InboundReceiptItem>? items,
  }) {
    return InboundReceipt(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, poNumber, status, items];
}

class InboundReceiptItem extends Equatable {
  const InboundReceiptItem({
    required this.id,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    this.imageUrl,
    this.receivedQuantity = 0,
    this.expirationDate,
  });

  final String id;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final String? imageUrl;
  final int receivedQuantity;
  final DateTime? expirationDate;

  InboundReceiptItem copyWith({
    String? id,
    String? itemName,
    String? barcode,
    int? expectedQuantity,
    Object? imageUrl = _sentinel,
    int? receivedQuantity,
    Object? expirationDate = _sentinel,
  }) {
    return InboundReceiptItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      expirationDate: expirationDate == _sentinel
          ? this.expirationDate
          : expirationDate as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemName,
        barcode,
        expectedQuantity,
        imageUrl,
        receivedQuantity,
        expirationDate,
      ];
}

const Object _sentinel = Object();
