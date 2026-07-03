/// Entity untuk item dalam cart (domain layer)
/// Berbeda dari model - entity hanya berisi data yang relevan untuk domain
class CartItem {
  final String id;
  final String produkItemId;
  final int uomId;
  final int hargaJual;
  final int qty;
  final int subtotal;
  final String? remarks;

  const CartItem({
    required this.id,
    required this.produkItemId,
    required this.uomId,
    required this.hargaJual,
    required this.qty,
    required this.subtotal,
    this.remarks,
  });

  /// Helper untuk cek apakah item ini valid
  bool get isValid => id.isNotEmpty && qty > 0 && hargaJual >= 0;
}
