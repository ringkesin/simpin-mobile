import '../entities/tracking_cart.dart';
import '../repositories/belanja_repository.dart';

/// Use case untuk get all history carts
class GetHistoryCarts {
  final BelanjaRepository repository;

  GetHistoryCarts(this.repository);

  Future<BelanjaResult<List<TrackingCartEntity>>> call({
    required int page,
    required int perPage,
  }) {
    return repository.getHistoryCarts(page: page, perPage: perPage);
  }
}
