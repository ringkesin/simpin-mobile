class JenisPinjamanModel {
  final int id;
  final String nama;

  JenisPinjamanModel({required this.id, required this.nama});

  factory JenisPinjamanModel.fromJson(Map<String, dynamic> json) {
    return JenisPinjamanModel(
      id: json['p_jenis_pinjaman_id'],
      nama: json['nama'],
    );
  }
}
