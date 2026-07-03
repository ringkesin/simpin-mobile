import '../repositories/belanja_repository.dart';

class AddToCart {
  final BelanjaRepository repository;

  AddToCart(this.repository);

  Future<BelanjaResult<bool>> call({
    required String productId,
    required int quantity,
    String remarks = '',
  }) async {
    return await repository.addToCart(
      productId: productId,
      quantity: quantity,
      remarks: remarks,
    );
  }
}
