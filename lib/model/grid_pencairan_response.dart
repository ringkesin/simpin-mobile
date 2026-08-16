// lib/model/grid_pencairan_response.dart
import 'list_pengajuan.dart';

class GridPencairanResponse {
  final bool success;
  final List<PengajuanItem> data;
  final String message;
  final int? currentPage;
  final int? lastPage;
  final int? total;

  GridPencairanResponse({
    required this.success,
    required this.data,
    required this.message,
    this.currentPage,
    this.lastPage,
    this.total,
  });

  factory GridPencairanResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<PengajuanItem> items = [];
    int? currentPage;
    int? lastPage;
    int? total;

    if (rawData is List) {
      items =
          rawData
              .whereType<Map>()
              .map((e) => PengajuanItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
    } else if (rawData is Map<String, dynamic>) {
      currentPage = rawData['current_page'] as int?;
      lastPage = rawData['last_page'] as int?;
      total = rawData['total'] as int?;
      final inner = rawData['data'];
      if (inner is List) {
        items =
            inner
                .whereType<Map>()
                .map(
                  (e) => PengajuanItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
      }
    }

    return GridPencairanResponse(
      success: json['success'] == true,
      data: items,
      message: json['message']?.toString() ?? '',
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  bool get hasMore {
    if (currentPage == null || lastPage == null) return false;
    return currentPage! < lastPage!;
  }
}
