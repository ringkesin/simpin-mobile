import '../repositories/belanja_repository.dart';

/// Use case untuk pay cart
class PayCart {
  final BelanjaRepository repository;

  PayCart(this.repository);

  Future<BelanjaResult<PayData>> call({
    required String cartMobileId,
    required int metodePembayaranId,
  }) {
    return repository.payCart(
      cartMobileId: cartMobileId,
      metodePembayaranId: metodePembayaranId,
    );
  }
}
