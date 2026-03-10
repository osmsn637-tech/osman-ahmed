import '../../../../core/utils/result.dart';
import '../../domain/entities/receive_item_params.dart';
import '../../../move/domain/repositories/item_repository.dart';

class ReceiveItemUseCase {
  const ReceiveItemUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<void>> call(ReceiveItemParams params) {
    return _repository.receiveItem(params);
  }
}
