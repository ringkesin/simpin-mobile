import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';
import '../service/cart_api_service.dart';
import '../models/tracking_cart_model.dart';
import 'payment_webview_page.dart';
import 'dart:async';

class BelanjaanPage extends StatefulWidget {
  const BelanjaanPage({super.key});

  @override
  State<BelanjaanPage> createState() => _BelanjaanPageState();
}

class _BelanjaanPageState extends State<BelanjaanPage> {
  int _tabIndex =
      0; // 0: Waiting, 1: Confirmed, 2: Cancelled, 3: Delivery, 4: History
  final CartApiService _cartApiService = CartApiService();
  bool _loading = false;
  List<TrackingCart> _waiting = [];
  List<TrackingCart> _confirmed = [];
  List<TrackingCart> _cancelled = [];
  List<TrackingCart> _delivery = [];
  List<TrackingCart> _history = [];
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _fetch(page: 1);
  }

  Future<void> _fetch({required int page}) async {
    setState(() => _loading = true);
    PagedTrackingCarts res;
    if (_tabIndex == 0) {
      res = await _cartApiService.getHistoryCarts(page: page, perPage: 10);
      _history = res.items;
    } else if (_tabIndex == 1) {
      res = await _cartApiService.getWaitingAdminCarts(page: page, perPage: 10);
      _waiting = res.items;
    } else if (_tabIndex == 2) {
      res = await _cartApiService.getConfirmedCarts(page: page, perPage: 10);
      _confirmed = res.items;
    } else if (_tabIndex == 3) {
      res = await _cartApiService.getCancelledCarts(page: page, perPage: 10);
      _cancelled = res.items;
    } else {
      res = await _cartApiService.getDeliveryStatusCarts(
        page: page,
        perPage: 10,
      );
      _delivery = res.items;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _page = res.currentPage;
      _lastPage = res.lastPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.arrowLeft,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        title: Text(
          'Tracking Belanjaan',
          style: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextLight,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabs(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        ...((_tabIndex == 0
                                ? _history
                                : _tabIndex == 1
                                ? _waiting
                                : _tabIndex == 2
                                ? _confirmed
                                : _tabIndex == 3
                                ? _cancelled
                                : _delivery)
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTrackingCard(c),
                              ),
                            )
                            .toList()),
                      const SizedBox(height: 16),
                      Text(
                        _tabIndex == 0
                            ? 'Riwayat pesanan'
                            : _tabIndex == 1
                            ? 'Menunggu konfirmasi admin ...'
                            : _tabIndex == 2
                            ? 'Menunggu pembayaran ...'
                            : _tabIndex == 3
                            ? 'Pesanan dibatalkan'
                            : 'Status pengantaran',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 80, child: _tabButton('History', 0)),
          SizedBox(width: 80, child: _tabButton('Waiting', 1)),
          SizedBox(width: 100, child: _tabButton('Confirmed', 2)),
          SizedBox(width: 100, child: _tabButton('Canceled', 3)),
          SizedBox(width: 90, child: _tabButton('Delivery', 4)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final bool selected = _tabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _tabIndex = index);
        _fetch(page: 1);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    selected
                        ? AppColors.primaryLight
                        : AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 28,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(TrackingCart c) {
    final Color borderColor = const Color(0xFFDDE5ED);
    final Color statusColor =
        c.status == 'waiting_admin'
            ? const Color(0xFFF59E0B)
            : c.status == 'canceled'
            ? const Color(0xFFEF4444)
            : AppColors.primaryLight;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.lokasiDeliveryNama,
                        style: GoogleFonts.lexendDeca(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.createdAt,
                        style: GoogleFonts.lexendDeca(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.status,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (c.deliveryRemarks != null)
              Text(
                c.deliveryRemarks!,
                style: GoogleFonts.lexendDeca(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryTextLight,
                ),
              ),
            if (c.status == 'canceled' && c.remarks != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  c.remarks!,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            if (c.status == 'confirmed' && c.expiredAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  _CountdownTimer(endTime: DateTime.parse(c.expiredAt!)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.items.length} item | ${formatRp(c.subtotalAfterVoucher)}',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                ),
                if (c.status == 'confirmed') ...[
                  InkWell(
                    onTap: () => _onPayTap(c),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Bayar',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Detail',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPayTap(TrackingCart c) async {
    final method = await showModalBottomSheet<int>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Potong Gaji (Tongji)'),
                subtitle: const Text('Metode internal'),
                onTap: () => Navigator.pop(context, 3),
              ),
              ListTile(
                title: const Text('Midtrans (Snap)'),
                subtitle: const Text('Bayar online'),
                onTap: () => Navigator.pop(context, 6),
              ),
            ],
          ),
        );
      },
    );
    if (method == null) return;
    final data = await _cartApiService.payCart(
      cartMobileId: c.id,
      metodePembayaranId: method,
    );
    if (!mounted) return;
    if (data == null) {
      final msg = _cartApiService.lastErrorMessage ?? 'Pembayaran gagal';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (method == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil (Tongji)')),
      );
      _fetch(page: 1);
    } else if (method == 6) {
      final urlStr = (data['redirect_url'] ?? '').toString().trim().replaceAll(
        '`',
        '',
      );
      if (urlStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirect URL tidak tersedia')),
        );
        return;
      }
      final uri = Uri.parse(urlStr);
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PaymentWebViewPage(url: uri)));
      _fetch(page: 1);
    }
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  const _CountdownTimer({required this.endTime});
  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _t;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now().toUtc();
    final end = widget.endTime.toUtc();
    final diff = end.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= Duration.zero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            expired
                ? const Color(0xFFEF4444).withOpacity(0.08)
                : const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        expired ? 'Expired' : _fmt(_remaining),
        style: GoogleFonts.lexendDeca(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: expired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
        ),
      ),
    );
  }
}
