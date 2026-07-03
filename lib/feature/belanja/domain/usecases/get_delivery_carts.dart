import '../entities/tracking_cart.dart';
import '../repositories/belanja_repository.dart';

/// Use case untuk get delivery carts (on_delivery)
class GetDeliveryCarts {
  final BelanjaRepository repository;

  GetDeliveryCarts(this.repository);

  Future<BelanjaResult<List<TrackingCartEntity>>> call({
    required int page,
    required int perPage,
  }) {
    return repository.getDeliveryCarts(page: page, perPage: perPage);
  }
}
