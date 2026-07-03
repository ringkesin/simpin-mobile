import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/feature/belanja/presentation/providers/belanja_providers.dart';
import 'package:kkba_mobile/feature/belanja/domain/entities/tracking_cart.dart';
import 'package:kkba_mobile/feature/belanja/domain/repositories/belanja_repository.dart';
import 'tracking_cart_detail_page.dart';
import 'payment_webview_page.dart';
import 'dart:async';

class BelanjaanPage extends ConsumerStatefulWidget {
  const BelanjaanPage({super.key});

  @override
  ConsumerState<BelanjaanPage> createState() => _BelanjaanPageState();
}

class _BelanjaanPageState extends ConsumerState<BelanjaanPage> {
  final Map<String, String> _snapRedirect = {};

  @override
  void initState() {
    super.initState();
    // Initial fetch for all tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTab(refresh: true);
    });
  }

  void _fetchCurrentTab({bool refresh = false}) {
    final tabIndex = ref.read(belanjaTabIndexProvider);
    _fetchTab(tabIndex, refresh: refresh);
  }

  void _fetchTab(int tabIndex, {bool refresh = false}) {
    switch (tabIndex) {
      case 0:
        ref.read(historyCartsProvider.notifier).fetch(refresh: refresh);
        break;
      case 1:
        ref.read(waitingCartsProvider.notifier).fetch(refresh: refresh);
        break;
      case 2:
        ref.read(confirmedCartsProvider.notifier).fetch(refresh: refresh);
        break;
      case 3:
        ref.read(cancelledCartsProvider.notifier).fetch(refresh: refresh);
        break;
      case 4:
        ref.read(deliveryCartsProvider.notifier).fetch(refresh: refresh);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(belanjaTabIndexProvider);

    // Watch all cart states for reactivity
    final historyState = ref.watch(historyCartsProvider);
    final waitingState = ref.watch(waitingCartsProvider);
    final confirmedState = ref.watch(confirmedCartsProvider);
    final cancelledState = ref.watch(cancelledCartsProvider);
    final deliveryState = ref.watch(deliveryCartsProvider);

    final currentState = tabIndex == 0
        ? historyState
        : tabIndex == 1
        ? waitingState
        : tabIndex == 2
        ? confirmedState
        : tabIndex == 3
        ? cancelledState
        : deliveryState;

    final currentList = currentState.carts;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTabs(tabIndex),
          ),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (currentState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (currentList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.box,
                            size: 48,
                            color: AppColors.secondaryTextLight.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!currentState.isLoading && currentList.isNotEmpty) ...[
                  if (currentState.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        currentState.error!,
                        style: GoogleFonts.lexendDeca(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ...currentList.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTrackingCard(c),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tabIndex == 0
                        ? 'Riwayat pesanan'
                        : tabIndex == 1
                        ? 'Menunggu konfirmasi admin ...'
                        : tabIndex == 2
                        ? 'Menunggu pembayaran ...'
                        : tabIndex == 3
                        ? 'Pesanan dibatalkan'
                        : 'Status pengantaran',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabs(int tabIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 80, child: _tabButton('History', 0, tabIndex)),
          SizedBox(width: 80, child: _tabButton('Waiting', 1, tabIndex)),
          SizedBox(width: 100, child: _tabButton('Confirmed', 2, tabIndex)),
          SizedBox(width: 100, child: _tabButton('Canceled', 3, tabIndex)),
          SizedBox(width: 90, child: _tabButton('Delivery', 4, tabIndex)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, int currentTab) {
    final bool selected = currentTab == index;
    return InkWell(
      onTap: () {
        ref.read(belanjaTabIndexProvider.notifier).state = index;
        _fetchTab(index, refresh: true);
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
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 28,
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(TrackingCartEntity c) {
    final Color borderColor = const Color(0xFFDDE5ED);
    final Color statusColor = _getStatusColor(c.status);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrackingCartDetailPage(cartId: c.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                          _fmtDate(c.createdAt),
                          style: GoogleFonts.lexendDeca(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                        if (c.estimatedDeliveryAt != null &&
                            c.estimatedDeliveryAt!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Estimasi ${_fmtDate(c.estimatedDeliveryAt!)}',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
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
                      c.status.label,
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
              if (c.status == CartStatus.cancelled && c.remarks != null)
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
              if (c.status == CartStatus.confirmed && c.expiredAt != null) ...[
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
                  if (c.status == CartStatus.waitingAdmin ||
                      c.status == CartStatus.confirmed) ...[
                    InkWell(
                      onTap: () => _onCancelTap(c),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Batalkan',
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
                  if (c.status == CartStatus.confirmed) ...[
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
                  ],
                  if (c.status == CartStatus.onDelivery) ...[
                    InkWell(
                      onTap: () => _onMarkDelivered(c),
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
                          'Pesanan diterima',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(CartStatus status) {
    switch (status) {
      case CartStatus.waitingAdmin:
        return const Color(0xFFF59E0B);
      case CartStatus.confirmed:
        return AppColors.primaryLight;
      case CartStatus.cancelled:
        return const Color(0xFFEF4444);
      case CartStatus.onDelivery:
        return const Color(0xFF3B82F6);
      case CartStatus.completed:
        return const Color(0xFF22C55E);
    }
  }

  Future<void> _onPayTap(TrackingCartEntity c) async {
    final method = await _showPaySheet();
    if (method == null) return;

    final payData = await payCart(
      ref: ref,
      cartId: c.id,
      metodePembayaranId: method,
    );

    if (!mounted) return;

    if (payData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran gagal')),
      );
      return;
    }

    if (method == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil (Tongji)')),
      );
      _fetchCurrentTab(refresh: true);
    } else if (method == 6) {
      final urlStr = payData.redirectUrl ?? '';
      if (urlStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirect URL tidak tersedia')),
        );
        return;
      }
      _snapRedirect[c.id] = urlStr;
      final uri = Uri.parse(urlStr);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentWebViewPage(url: uri)),
      );
      _fetchCurrentTab(refresh: true);
    }
  }

  Future<int?> _showPaySheet() async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pilih Metode Pembayaran',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tongji balance from Riverpod provider
              Consumer(
                builder: (context, ref, _) {
                  final balanceAsync = ref.watch(tongjiBalanceProvider);
                  return balanceAsync.when(
                    data: (balance) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tongji',
                            style: GoogleFonts.lexendDeca(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTextLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Sisa saldo',
                                  style: GoogleFonts.lexendDeca(
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              ),
                              Text(
                                formatRp(balance),
                                style: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context, 3),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tongji',
                          style: GoogleFonts.lexendDeca(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context, 6),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primaryLight,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Midtrans',
                          style: GoogleFonts.lexendDeca(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onMarkDelivered(TrackingCartEntity c) async {
    final ok = await markDelivered(ref: ref, cartId: c.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan ditandai telah diterima')),
      );
      _fetchCurrentTab(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menandai pesanan diterima')),
      );
    }
  }

  String _fmtDate(String iso) {
    DateTime? dt;
    try {
      dt = DateTime.tryParse(iso);
    } catch (_) {}
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$mi';
  }

  Future<void> _onCancelTap(TrackingCartEntity c) async {
    final controller = TextEditingController();
    String? errorText;
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Alasan pembatalan',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tulis alasan pembatalan di sini',
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        setSheetState(() {
                          errorText =
                              v.trim().isEmpty ? 'Alasan tidak boleh kosong' : null;
                        });
                      },
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: GoogleFonts.lexendDeca(
                        color: const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryLight),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.lexendDeca(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (controller.text.trim().isEmpty)
                              ? null
                              : () => Navigator.pop(context, controller.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Kirim',
                            style: GoogleFonts.lexendDeca(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (note == null || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan pembatalan tidak boleh kosong')),
      );
      return;
    }

    final ok = await cancelCart(ref: ref, cartId: c.id, alasan: note);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart berhasil dibatalkan')),
      );
      _fetchCurrentTab(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membatalkan cart')),
      );
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
        color: expired
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
