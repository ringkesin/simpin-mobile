class TongjiBalanceModel {
  final String periodeNama;
  final DateTime? periodeStartDate;
  final DateTime? periodeEndDate;
  final int limitAmount;
  final int usedAmount;
  final int remainingAmount;

  const TongjiBalanceModel({
    required this.periodeNama,
    required this.periodeStartDate,
    required this.periodeEndDate,
    required this.limitAmount,
    required this.usedAmount,
    required this.remainingAmount,
  });

  factory TongjiBalanceModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TongjiBalanceModel(
      periodeNama: json['periode_nama']?.toString() ?? '-',
      periodeStartDate: DateTime.tryParse(
        json['periode_start_date']?.toString() ?? '',
      ),
      periodeEndDate: DateTime.tryParse(
        json['periode_end_date']?.toString() ?? '',
      ),
      limitAmount: parseInt(json['limit_amount']),
      usedAmount: parseInt(json['used_amount']),
      remainingAmount: parseInt(json['remaining_amount']),
    );
  }
}

class TongjiTransactionModel {
  final String id;
  final DateTime? createdAt;
  final String direction;
  final int amount;
  final String description;
  final String periodeNama;
  final DateTime? periodeStartDate;
  final DateTime? periodeEndDate;
  final String? transaksiPenjualanId;
  final String? noTransaksiPenjualan;

  const TongjiTransactionModel({
    required this.id,
    required this.createdAt,
    required this.direction,
    required this.amount,
    required this.description,
    required this.periodeNama,
    required this.periodeStartDate,
    required this.periodeEndDate,
    required this.transaksiPenjualanId,
    required this.noTransaksiPenjualan,
  });

  bool get isDebit => direction.toLowerCase() == 'debit';

  factory TongjiTransactionModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TongjiTransactionModel(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      direction: json['direction']?.toString() ?? '-',
      amount: parseInt(json['amount']),
      description: json['description']?.toString() ?? '-',
      periodeNama: json['periode_nama']?.toString() ?? '-',
      periodeStartDate: DateTime.tryParse(
        json['periode_start_date']?.toString() ?? '',
      ),
      periodeEndDate: DateTime.tryParse(
        json['periode_end_date']?.toString() ?? '',
      ),
      transaksiPenjualanId: json['transaksi_penjualan_id']?.toString(),
      noTransaksiPenjualan: json['no_transaksi_penjualan']?.toString(),
    );
  }
}

class PagedTongjiTransactions {
  final List<TongjiTransactionModel> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PagedTongjiTransactions({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PagedTongjiTransactions.fromResponse(Map<String, dynamic> json) {
    final rawItems = json['data'] as List? ?? const [];
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return PagedTongjiTransactions(
      items:
          rawItems
              .whereType<Map>()
              .map(
                (item) => TongjiTransactionModel.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList(),
      currentPage: parseInt(meta['current_page'], fallback: 1),
      perPage: parseInt(meta['per_page'], fallback: rawItems.length),
      total: parseInt(meta['total'], fallback: rawItems.length),
      lastPage: parseInt(meta['last_page'], fallback: 1),
    );
  }
}
