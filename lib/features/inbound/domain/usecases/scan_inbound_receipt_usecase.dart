import '../../../../core/utils/result.dart';
import '../entities/inbound_entities.dart';
import '../repositories/inbound_repository.dart';

class ScanInboundReceiptUseCase {
  ScanInboundReceiptUseCase(this._repository);

  final InboundRepository _repository;

  Future<Result<InboundReceiptScanResult>> execute(String barcode) {
    return _repository.scanReceipt(barcode);
  }
}
