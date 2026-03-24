import 'package:flutter_test/flutter_test.dart';
import 'package:wherehouse/core/constants/app_endpoints.dart';
import 'package:wherehouse/core/utils/result.dart';
import 'package:wherehouse/features/inbound/domain/entities/inbound_entities.dart';

import '../../../../support/fake_repositories.dart';

void main() {
  test('AppEndpoints exposes inbound receipt scan route', () {
    expect(
      AppEndpoints.inboundReceiptScanByPo,
      '/mobile/v1/inbound/receipts/scan-by-po',
    );
    expect(
      AppEndpoints.inboundReceiptDetail('receipt-1001'),
      '/mobile/v1/inbound/receipts/receipt-1001',
    );
    expect(
      AppEndpoints.inboundReceiptStart('receipt-1001'),
      '/mobile/v1/inbound/receipts/receipt-1001/start',
    );
    expect(
      AppEndpoints.inboundReceiptScanItem('receipt-1001'),
      '/mobile/v1/inbound/receipts/receipt-1001/scan-item',
    );
    expect(
      AppEndpoints.inboundReceiptItemConfirm('item-1'),
      '/mobile/v1/inbound/receipt-items/item-1/confirm',
    );
  });

  test('fake inbound repository accepts a non-empty receipt barcode', () async {
    final repo = FakeInboundRepository();

    final result = await repo.scanReceipt('RCV-1001');

    expect(result, isA<Success<InboundReceiptScanResult>>());
    final scan = (result as Success<InboundReceiptScanResult>).data;
    expect(scan.barcode, 'RCV-1001');
    expect(scan.receiptId, 'receipt-1001');
    expect(scan.poNumber, 'RCV-1001');
    expect(scan.items, isNotEmpty);
  });

  test('fake inbound repository rejects an empty receipt barcode', () async {
    final repo = FakeInboundRepository();

    final result = await repo.scanReceipt('   ');

    expect(result, isA<Failure<InboundReceiptScanResult>>());
  });

  test('fake inbound repository exposes receipt details and updates quantities',
      () async {
    final repo = FakeInboundRepository(
      receipts: [
        const InboundReceipt(
          id: 'receipt-1001',
          poNumber: 'PO-1001',
          items: [
            InboundReceiptItem(
              id: 'item-1',
              itemName: 'Blue Mug',
              barcode: 'SKU-001',
              expectedQuantity: 4,
            ),
            InboundReceiptItem(
              id: 'item-2',
              itemName: 'Red Mug',
              barcode: 'SKU-002',
              expectedQuantity: 2,
            ),
          ],
        ),
      ],
    );

    final loaded = await repo.getReceipt('receipt-1001');
    final scanned = await repo.scanReceiptItem(
      receiptId: 'receipt-1001',
      barcode: 'SKU-002',
    );
    final confirmed = await repo.confirmReceiptItem(
      receiptId: 'receipt-1001',
      itemId: 'item-2',
      quantity: 5,
      expirationDate: DateTime(2026, 4, 1),
    );

    expect(loaded, isA<Success<InboundReceipt>>());
    expect(scanned, isA<Success<InboundReceiptItem>>());
    expect(confirmed, isA<Success<InboundReceipt>>());

    final receipt = (confirmed as Success<InboundReceipt>).data;
    expect(
      receipt.items.firstWhere((item) => item.id == 'item-2').receivedQuantity,
      5,
    );
    expect(
      receipt.items.firstWhere((item) => item.id == 'item-2').expirationDate,
      DateTime(2026, 4, 1),
    );
  });

  test('starting a receipt switches it to receiving', () async {
    final repo = FakeInboundRepository(
      receipts: [
        const InboundReceipt(
          id: 'receipt-1001',
          poNumber: 'PO-1001',
          items: [
            InboundReceiptItem(
              id: 'item-1',
              itemName: 'Blue Mug',
              barcode: 'SKU-001',
              expectedQuantity: 4,
            ),
          ],
        ),
      ],
    );

    final result = await repo.startReceipt('receipt-1001');

    expect(result, isA<Success<InboundReceipt>>());
    expect((result as Success<InboundReceipt>).data.status, 'receiving');
  });
}
