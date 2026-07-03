import '../repositories/belanja_repository.dart';

/// Use case untuk cancel cart
class CancelCart {
  final BelanjaRepository repository;

  CancelCart(this.repository);

  Future<BelanjaResult<bool>> call({
    required String cartMobileId,
    required String alasan,
  }) {
    /// Validasi alasan tidak kosong
    if (alasan.trim().isEmpty) {
      return Future.value(
        BelanjaResult.failure('Alasan pembatalan harus diisi'),
      );
    }
    return repository.cancelCart(
      cartMobileId: cartMobileId,
      alasan: alasan,
    );
  }
}
