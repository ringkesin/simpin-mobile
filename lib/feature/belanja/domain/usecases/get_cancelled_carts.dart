import '../entities/tracking_cart.dart';
import '../repositories/belanja_repository.dart';

/// Use case untuk get cancelled carts
class GetCancelledCarts {
  final BelanjaRepository repository;

  GetCancelledCarts(this.repository);

  Future<BelanjaResult<List<TrackingCartEntity>>> call({
    required int page,
    required int perPage,
  }) {
    return repository.getCancelledCarts(page: page, perPage: perPage);
  }
}
