import '../../domain/entities/inbound_entities.dart';

abstract class InboundRepository {
  Future<List<InboundDocument>> getInboundDocuments();
  Future<List<InboundDocument>> getInboundDocumentsByStatus(InboundStatus status);
  Future<InboundDocument> createInboundDocument(CreateInboundParams params);
  Future<InboundDocument> startInboundDocument(int inboundId);
  Future<InboundDocument> receiveInboundItem(ReceiveInboundItemParams params);
  Future<InboundDocument> completeInboundDocument(int inboundId);
}
