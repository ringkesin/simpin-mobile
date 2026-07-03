import '../repositories/belanja_repository.dart';

/// Use case untuk reset payment (jika order_id sudah dipakai)
class ResetPayment {
  final BelanjaRepository repository;

  ResetPayment(this.repository);

  Future<BelanjaResult<bool>> call({required String cartMobileId}) {
    return repository.resetPayment(cartMobileId: cartMobileId);
  }
}
