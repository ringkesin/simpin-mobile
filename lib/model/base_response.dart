// lib/model/base_response.dart
class BaseResponse {
  final bool success;
  final String? message;

  BaseResponse({required this.success, this.message});

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}
