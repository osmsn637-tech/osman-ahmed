import '../../../../core/utils/result.dart';
import '../entities/move_item_params.dart';
import '../entities/movement.dart';
import '../repositories/item_repository.dart';

class MoveItemUseCase {
  const MoveItemUseCase(this._repository);

  final ItemRepository _repository;

  Future<Result<Movement>> execute(MoveItemParams params) {
    return _repository.moveItem(params);
  }
}
