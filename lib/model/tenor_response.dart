// models/tenor_response.dart

import 'dart:convert';

TenorResponse tenorResponseFromJson(String str) =>
    TenorResponse.fromJson(json.decode(str));

String tenorResponseToJson(TenorResponse data) => json.encode(data.toJson());

class TenorResponse {
  final bool success;
  final List<TenorItem>? data; // Jadikan list nullable
  final String? message;

  TenorResponse({required this.success, this.data, this.message});

  factory TenorResponse.fromJson(Map<String, dynamic> json) => TenorResponse(
    success: json["success"] ?? false,
    // Handle jika data null atau bukan list
    data:
        json["data"] == null || json["data"] is! List
            ? [] // Default ke list kosong jika tidak valid
            : List<TenorItem>.from(
              json["data"].map((x) => TenorItem.fromJson(x)),
            ),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data":
        data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
  };
}

class TenorItem {
  final int? tenor; // Jadikan nullable

  TenorItem({
    this.tenor = 0, // Default value
  });

  factory TenorItem.fromJson(Map<String, dynamic> json) => TenorItem(
    tenor: (json["tenor"] as int?) ?? 0, // Handle null
  );

  Map<String, dynamic> toJson() => {"tenor": tenor};
}
