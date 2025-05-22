class KeperluanPinjamanModel {
  final int? id;
  final String? nama;

  KeperluanPinjamanModel({this.id, this.nama});

  factory KeperluanPinjamanModel.fromJson(Map<String, dynamic> json) {
    return KeperluanPinjamanModel(
      id: json['p_pinjaman_keperluan_id'],
      nama: json['keperluan'],
    );
  }
}
