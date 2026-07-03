import '../repositories/belanja_repository.dart';

/// Use case untuk mark cart sebagai delivered
class MarkDelivered {
  final BelanjaRepository repository;

  MarkDelivered(this.repository);

  Future<BelanjaResult<bool>> call({required String cartMobileId}) {
    return repository.markDelivered(cartMobileId: cartMobileId);
  }
}
