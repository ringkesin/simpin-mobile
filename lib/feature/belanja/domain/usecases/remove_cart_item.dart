import '../repositories/belanja_repository.dart';

class RemoveCartItem {
  final BelanjaRepository repository;

  RemoveCartItem(this.repository);

  Future<BelanjaResult<bool>> call({
    required String productId,
  }) async {
    return await repository.removeItem(productId: productId);
  }
}
