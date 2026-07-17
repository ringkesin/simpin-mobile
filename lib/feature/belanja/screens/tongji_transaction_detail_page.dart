import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/core/widgets/kkba_loading_indicator.dart';
import 'package:kkba_mobile/theme.dart';
import '../service/pos_api_service.dart';

class TongjiTransactionDetailPage extends StatefulWidget {
  final String transaksiPenjualanId;
  final String? title;

  const TongjiTransactionDetailPage({
    super.key,
    required this.transaksiPenjualanId,
    this.title,
  });

  @override
  State<TongjiTransactionDetailPage> createState() =>
      _TongjiTransactionDetailPageState();
}

class _TongjiTransactionDetailPageState
    extends State<TongjiTransactionDetailPage> {
  final PosApiService _api = PosApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await _api.getPenjualanDetail(widget.transaksiPenjualanId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
    if (data == null) {
      final msg = _api.lastErrorMessage ?? 'Gagal memuat detail transaksi';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _pickString(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.trim().isNotEmpty) return s;
    }
    return '-';
  }

  int _pickInt(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  DateTime? _pickDate(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final dt = DateTime.tryParse(v.toString());
      if (dt != null) return dt;
    }
    return null;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _formatMoney(int value) {
    return '${formatRp(value)},-';
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> data) {
    dynamic raw =
        data['items'] ??
        data['detail'] ??
        data['details'] ??
        data['penjualan_items'] ??
        data['produk'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (widget.title ?? '').trim().isNotEmpty
            ? widget.title!
            : 'Detail Transaksi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextLight,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
      ),
      body:
          _loading
              ? const Center(child: KkbaLoadingIndicator())
              : _data == null
              ? Center(
                child: Text(
                  'Data tidak tersedia',
                  style: GoogleFonts.lexendDeca(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
              )
              : _buildContent(_data!),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final no = _pickString(data, [
      'no_transaksi_penjualan',
      'no_transaksi',
      'nomor_transaksi',
      'kode_transaksi',
      'no',
      'nomor',
    ]);
    final tanggal = _formatDateTime(
      _pickDate(data, ['tanggal', 'created_at', 'waktu', 'tanggal_transaksi']),
    );
    final total = _pickInt(data, [
      'total',
      'grand_total',
      'total_bayar',
      'total_amount',
      'jumlah',
      'amount',
    ]);
    final payment = _pickString(data, [
      'metode_pembayaran',
      'payment_method',
      'metode',
      'cara_bayar',
    ]);
    final outlet = _pickString(data, ['outlet', 'nama_outlet', 'lokasi']);
    final items = _extractItems(data);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE5ED)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan',
                style: GoogleFonts.lexendDeca(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTextLight,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow('No Transaksi', no),
              _infoRow('Tanggal', tanggal),
              if (outlet != '-') _infoRow('Outlet', outlet),
              if (payment != '-') _infoRow('Pembayaran', payment),
              _infoRow('Total', _formatMoney(total)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE5ED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTextLight,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map(_itemRow),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE5ED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTextLight,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _itemRow(Map<String, dynamic> it) {
    String pickStr(List<String> keys) {
      for (final k in keys) {
        final v = it[k];
        if (v == null) continue;
        final s = v.toString();
        if (s.trim().isNotEmpty) return s;
      }
      return '-';
    }

    int pickInt(List<String> keys) {
      for (final k in keys) {
        final v = it[k];
        if (v == null) continue;
        if (v is int) return v;
        final parsed = int.tryParse(v.toString());
        if (parsed != null) return parsed;
      }
      return 0;
    }

    final name = pickStr([
      'nama_produk',
      'product_name',
      'produk_nama',
      'nama',
    ]);
    final qty = pickInt(['qty', 'quantity', 'jumlah']);
    final price = pickInt(['harga', 'price', 'harga_jual']);
    final subtotal = pickInt(['subtotal', 'total', 'total_price', 'jumlah']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty $qty x ${formatRp(price)}',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatRp(subtotal),
            style: GoogleFonts.lexendDeca(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTextLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lexendDeca(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
