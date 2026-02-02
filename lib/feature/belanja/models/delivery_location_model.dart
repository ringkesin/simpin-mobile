class DeliveryLocationModel {
  final int id;
  final String location;
  final String? remarks;

  DeliveryLocationModel({
    required this.id,
    required this.location,
    this.remarks,
  });

  factory DeliveryLocationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationModel(
      id: json['id'] ?? 0,
      location: json['lokasi'] ?? '',
      remarks: json['remarks'],
    );
  }
}
