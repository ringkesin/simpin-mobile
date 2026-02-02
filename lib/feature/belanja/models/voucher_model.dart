class VoucherModel {
  final String id;
  final String code;
  final String description;
  final int discountAmount;
  final int minPurchase;
  final String validUntil;

  VoucherModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.minPurchase,
    required this.validUntil,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final int nilai = json['nilai'] ?? 0;
    return VoucherModel(
      id: json['id']?.toString() ?? '',
      code: json['kode_voucher'] ?? '',
      description: json['remarks'] ?? 'Potongan Rp $nilai',
      discountAmount: nilai,
      minPurchase: 0,
      validUntil: json['valid_sampai'] ?? '',
    );
  }
}
