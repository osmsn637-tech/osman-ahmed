import '../../../../core/utils/result.dart';
import '../../domain/entities/inbound_entities.dart';

abstract class InboundRepository {
  Future<List<InboundDocument>> getInboundDocuments();
  Future<List<InboundDocument>> getInboundDocumentsByStatus(
      InboundStatus status);
  Future<InboundDocument> createInboundDocument(CreateInboundParams params);
  Future<InboundDocument> startInboundDocument(int inboundId);
  Future<InboundDocument> receiveInboundItem(ReceiveInboundItemParams params);
  Future<InboundDocument> completeInboundDocument(int inboundId);
  Future<Result<InboundReceiptScanResult>> scanReceipt(String barcode);
  Future<Result<InboundReceipt>> getReceipt(String receiptId);
  Future<Result<InboundReceipt>> startReceipt(String receiptId);
  Future<Result<InboundReceiptItem>> scanReceiptItem({
    required String receiptId,
    required String barcode,
  });
  Future<Result<InboundReceipt>> confirmReceiptItem({
    required String receiptId,
    required String itemId,
    required int quantity,
  });
}
