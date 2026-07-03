import '../entities/tracking_cart.dart';
import '../repositories/belanja_repository.dart';

/// Use case untuk get confirmed carts
class GetConfirmedCarts {
  final BelanjaRepository repository;

  GetConfirmedCarts(this.repository);

  Future<BelanjaResult<List<TrackingCartEntity>>> call({
    required int page,
    required int perPage,
  }) {
    return repository.getConfirmedCarts(page: page, perPage: perPage);
  }
}
