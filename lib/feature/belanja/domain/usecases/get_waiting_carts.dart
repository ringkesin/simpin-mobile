import '../entities/tracking_cart.dart';
import '../repositories/belanja_repository.dart';

/// Use case untuk get waiting carts
class GetWaitingCarts {
  final BelanjaRepository repository;

  GetWaitingCarts(this.repository);

  Future<BelanjaResult<List<TrackingCartEntity>>> call({
    required int page,
    required int perPage,
  }) {
    return repository.getWaitingCarts(page: page, perPage: perPage);
  }
}
