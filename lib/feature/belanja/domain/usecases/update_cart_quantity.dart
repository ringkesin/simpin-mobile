import '../repositories/belanja_repository.dart';

class UpdateCartQuantity {
  final BelanjaRepository repository;

  UpdateCartQuantity(this.repository);

  Future<BelanjaResult<bool>> call({
    required String productId,
    required int quantity,
  }) async {
    return await repository.updateQuantity(
      productId: productId,
      quantity: quantity,
    );
  }
}
