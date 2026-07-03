import '../repositories/belanja_repository.dart';
import '../entities/cart_entity.dart';

class GetCart {
  final BelanjaRepository repository;

  GetCart(this.repository);

  Future<BelanjaResult<CartEntity>> call() async {
    return await repository.getCart();
  }
}
