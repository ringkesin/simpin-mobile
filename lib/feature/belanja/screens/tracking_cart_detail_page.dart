import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/core/widgets/kkba_loading_indicator.dart';
import '../models/cart_model.dart';
import '../service/cart_api_service.dart';
import '../models/product.dart';

class TrackingCartDetailPage extends StatefulWidget {
  final String cartId;
  const TrackingCartDetailPage({super.key, required this.cartId});

  @override
  State<TrackingCartDetailPage> createState() => _TrackingCartDetailPageState();
}

class _TrackingCartDetailPageState extends State<TrackingCartDetailPage> {
  final CartApiService _api = CartApiService();
  CartModel? _cart;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await _api.getCartDetail(widget.cartId);
    if (!mounted) return;
    setState(() {
      _cart = data;
      _loading = false;
    });
    if (data == null) {
      final msg = _api.lastErrorMessage ?? 'Gagal memuat detail cart';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Belanjaan',
          style: GoogleFonts.lexendDeca(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
      ),
      body: _loading
          ? const Center(child: KkbaLoadingIndicator())
          : _cart == null
              ? Center(
                  child: Text('Data tidak tersedia', style: GoogleFonts.lexendDeca(color: AppColors.secondaryTextLight)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDE5ED)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengiriman', style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
                          const SizedBox(height: 8),
                          _infoRow('Lokasi', _cart!.lokasiDeliveryNama ?? '-'),
                          _infoRow('PIC', _cart!.deliveryPicName ?? '-'),
                          _infoRow('Telepon', _cart!.deliveryPicPhone ?? '-'),
                          _infoRow('Estimasi', _fmtDate(_cart!.estimatedDeliveryAt)),
                          if ((_cart!.deliveryRemarks ?? '').isNotEmpty) _infoRow('Catatan', _cart!.deliveryRemarks!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDE5ED)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daftar Item', style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
                          const SizedBox(height: 12),
                          ..._cart!.items.map((it) => _itemRow(it)).toList(),
                          const SizedBox(height: 16),
                          Divider(color: const Color(0xFFDDE5ED), height: 1),
                          const SizedBox(height: 16),
                          _priceRow('Subtotal', _cart!.summary.subtotal, valueWeight: FontWeight.w700),
                          _priceRow('Diskon', -_cart!.summary.discount, valueColor: AppColors.secondaryTextLight, valueWeight: FontWeight.w700),
                          _priceRow('Total', _cart!.summary.total, labelWeight: FontWeight.w800, valueWeight: FontWeight.w800),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _itemRow(CartItemModel it) {
    final Product p = it.product;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE5ED))),
            clipBehavior: Clip.hardEdge,
            child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                ? const Icon(Icons.image, color: Colors.grey)
                : Image.network(p.imageUrl!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.name, style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
          ),
          Text(formatRp(it.totalPrice), style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int value, {FontWeight labelWeight = FontWeight.w600, FontWeight valueWeight = FontWeight.w700, Color? valueColor}) {
    final bool isNegative = value < 0;
    final String display = isNegative ? '-${formatRp(value.abs()).replaceFirst('Rp', '')}' : formatRp(value);
    final Color effectiveColor = valueColor ?? (isNegative ? AppColors.secondaryTextLight : AppColors.primaryTextLight);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.lexendDeca(fontWeight: labelWeight, color: AppColors.primaryTextLight))),
          Text(display, style: GoogleFonts.lexendDeca(fontWeight: valueWeight, color: effectiveColor)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.lexendDeca(color: AppColors.secondaryTextLight)) ),
          Expanded(child: Text(value, style: GoogleFonts.lexendDeca(color: AppColors.primaryTextLight, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    DateTime? dt;
    try {
      dt = DateTime.tryParse(iso);
    } catch (_) {}
    if (dt == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d $m $y';
  }
}
