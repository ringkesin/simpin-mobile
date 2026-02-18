import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';

import '../models/cart_model.dart';
import '../models/voucher_model.dart';
import '../models/delivery_location_model.dart';
import '../service/cart_api_service.dart';
import 'inspire_mart.dart';

class CartConfirmPage extends StatefulWidget {
  final List<Product> items;
  final int Function(Product) getQty;
  final void Function(Product) onIncrement;
  final void Function(Product) onDecrement;
  final CartModel? cart;
  final CartApiService? cartApiService;
  final VoidCallback? onRefresh;

  const CartConfirmPage({
    super.key,
    required this.items,
    required this.getQty,
    required this.onIncrement,
    required this.onDecrement,
    this.cart,
    this.cartApiService,
    this.onRefresh,
  });

  @override
  State<CartConfirmPage> createState() => _CartConfirmPageState();
}

class _CartConfirmPageState extends State<CartConfirmPage> {
  late CartModel? _currentCart;
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isApplyingVoucher = false;
  bool _isCheckingOut = false;
  List<VoucherModel> _availableVouchers = [];
  bool _isLoadingVouchers = false;
  List<DeliveryLocationModel> _deliveryLocations = [];
  bool _isLoadingLocations = false;
  DeliveryLocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _currentCart = widget.cart;
    if (_currentCart?.summary.voucherCode != null) {
      _voucherController.text = _currentCart!.summary.voucherCode!;
    }
    _fetchVouchers();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    if (widget.cartApiService == null) return;
    setState(() => _isLoadingLocations = true);
    final locations = await widget.cartApiService!.getDeliveryLocations();
    if (mounted) {
      setState(() {
        _deliveryLocations = locations;
        _isLoadingLocations = false;
        if (_deliveryLocations.isNotEmpty) {
          _selectedLocation = _deliveryLocations.first;
        }
      });
    }
  }

  Future<void> _fetchVouchers() async {
    if (widget.cartApiService == null) return;
    setState(() => _isLoadingVouchers = true);
    final vouchers = await widget.cartApiService!.getVouchers();
    if (mounted) {
      setState(() {
        _availableVouchers = vouchers;
        _isLoadingVouchers = false;
      });
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  int get totalPrice {
    if (_currentCart != null) {
      return _currentCart!.summary.total;
    }
    // Fallback logic
    int total = 0;
    for (final p in widget.items) {
      total += widget.getQty(p) * p.price;
    }
    return total;
  }

  Future<void> _refreshCart() async {
    if (widget.cartApiService == null) return;
    final cart = await widget.cartApiService!.getCart();
    if (mounted && cart != null) {
      setState(() {
        _currentCart = cart;
        // Update voucher text if server has one
        if (cart.summary.voucherCode != null) {
          _voucherController.text = cart.summary.voucherCode!;
        }
      });
      widget.onRefresh?.call();
    }
  }

  Future<void> _applyVoucher() async {
    if (widget.cartApiService == null || _voucherController.text.isEmpty)
      return;

    setState(() => _isApplyingVoucher = true);
    final success = await widget.cartApiService!.applyVoucher(
      _voucherController.text,
    );

    if (mounted) {
      setState(() => _isApplyingVoucher = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher berhasil dipasang')),
        );
        _refreshCart();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Voucher tidak valid')));
      }
    }
  }

  Future<void> _removeVoucher() async {
    if (widget.cartApiService == null) return;

    setState(() => _isApplyingVoucher = true);
    final success = await widget.cartApiService!.removeVoucher();

    if (mounted) {
      setState(() => _isApplyingVoucher = false);
      if (success) {
        _voucherController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Voucher dihapus')));
        _refreshCart();
      }
    }
  }

  Future<void> _checkout() async {
    if (widget.cartApiService == null) return;

    setState(() => _isCheckingOut = true);
    final success = await widget.cartApiService!.checkout();

    if (mounted) {
      setState(() => _isCheckingOut = false);
      if (success) {
        // Navigate to success page or orders page
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pembelian berhasil!')));
        // Ideally navigate to order detail or history
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal checkout, silakan coba lagi')),
        );
      }
    }
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih Lokasi Pengantaran',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextLight,
                  ),
                ),
              ),
              // List Locations
              Expanded(
                child:
                    _isLoadingLocations
                        ? const Center(child: CircularProgressIndicator())
                        : _deliveryLocations.isEmpty
                        ? Center(
                          child: Text(
                            'Belum ada lokasi tersedia',
                            style: GoogleFonts.lexendDeca(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _deliveryLocations.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final location = _deliveryLocations[index];
                            final isSelected =
                                _selectedLocation?.id == location.id;
                            return InkWell(
                              onTap: () {
                                setState(() => _selectedLocation = location);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primaryLight
                                            : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color:
                                          isSelected
                                              ? AppColors.primaryLight
                                              : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        location.location,
                                        style: GoogleFonts.lexendDeca(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryTextLight,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryLight,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoucherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih Voucher',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextLight,
                  ),
                ),
              ),
              // Input Manual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _voucherController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan kode voucher',
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.lexendDeca(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyVoucher();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Pakai',
                          style: GoogleFonts.lexendDeca(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // List Vouchers
              Expanded(
                child:
                    _isLoadingVouchers
                        ? const Center(child: CircularProgressIndicator())
                        : _availableVouchers.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.ticket,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada voucher tersedia',
                                style: GoogleFonts.lexendDeca(
                                  color: AppColors.secondaryTextLight,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _availableVouchers.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final voucher = _availableVouchers[index];
                            final isSelected =
                                _currentCart?.summary.voucherCode ==
                                voucher.code;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primaryLight
                                          : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voucher.code,
                                          style: GoogleFonts.lexendDeca(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: AppColors.primaryTextLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          voucher.description,
                                          style: GoogleFonts.lexendDeca(
                                            fontSize: 13,
                                            color: AppColors.secondaryTextLight,
                                          ),
                                        ),
                                        if (voucher.minPurchase > 0) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Min. blj ${formatRp(voucher.minPurchase)}',
                                            style: GoogleFonts.lexendDeca(
                                              fontSize: 11,
                                              color: AppColors.primaryLight,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _voucherController.text = voucher.code;
                                      if (isSelected) {
                                        _removeVoucher();
                                      } else {
                                        _applyVoucher();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isSelected
                                              ? Colors.white
                                              : AppColors.primaryLight,
                                      side: BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      isSelected ? 'Lepas' : 'Pakai',
                                      style: GoogleFonts.lexendDeca(
                                        color:
                                            isSelected
                                                ? AppColors.primaryLight
                                                : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isSmallHeight = media.size.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Konfirmasi Belanjaan',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lokasi pengantaran
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: _showLocationSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi Pengantaran',
                                      style: GoogleFonts.lexendDeca(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedLocation?.location ??
                                          'Pilih lokasi pengantaran',
                                      style: GoogleFonts.lexendDeca(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryTextLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF0F172A),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // section break removed here; only below note
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFDDE5ED)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.badgeInfo,
                              color: Color(0xFF0F172A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _remarksController,
                                decoration: const InputDecoration(
                                  hintText: 'Catatan untuk pengantar ...',
                                  border: InputBorder.none,
                                ),
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionBreak(),

                    const SizedBox(height: 16),
                    // Daftar belanja
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar belanja',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTextLight,
                            ),
                          ),
                          Text(
                            '+ Tambah lagi',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: () {
                          final Set<String> _seenIds = {};
                          return widget.items.where((p) => _seenIds.add(p.id)).map((
                            p,
                          ) {
                            final qty = widget.getQty(p);
                            final ci = _currentCart?.items.firstWhere(
                              (it) =>
                                  it.productId == p.id || it.product.id == p.id,
                              orElse:
                                  () => CartItemModel(
                                    id: '',
                                    productId: p.id,
                                    product: p,
                                    quantity: qty,
                                    price: p.price,
                                    totalPrice: p.price * qty,
                                  ),
                            );
                            final displayImageUrl =
                                (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                    ? p.imageUrl
                                    : (ci?.product.imageUrl);
                            final qtyDisplay = ci?.quantity ?? qty;
                            final unitFromItem = (ci?.price ?? 0);
                            final unitFromTotal =
                                ((ci?.totalPrice ?? 0) > 0 && qtyDisplay > 0)
                                    ? ((ci!.totalPrice ~/ qtyDisplay))
                                    : 0;
                            final displayPrice =
                                unitFromItem > 0
                                    ? unitFromItem
                                    : (unitFromTotal > 0
                                        ? unitFromTotal
                                        : p.price);
                            if (qty <= 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        (displayImageUrl != null &&
                                                displayImageUrl.isNotEmpty)
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                displayImageUrl,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                            : const Icon(
                                              LucideIcons.image,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: GoogleFonts.lexendDeca(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryTextLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatRp(displayPrice),
                                          style: GoogleFonts.lexendDeca(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondaryTextLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _CircleActionButton(
                                        icon: Icons.remove,
                                        onTap: () async {
                                          widget.onDecrement(p);
                                          // Wait a bit for parent to update cart, then refresh UI
                                          // Ideally parent's callback updates _cart model
                                          // But parent's onDecrement updates parent state and calls API
                                          // Parent needs to pass updated cart or we need to fetch it?
                                          // Parent passes onRefresh to us.
                                          // Let's call refresh here after a delay to allow API to process
                                          // Optimistic UI is handled by parent's setState (passed via props)
                                          // But for total price calculation, we need updated _cart from server
                                          // or calculate locally.
                                          // For now, rely on parent's setState for item list, and fetch cart for total.
                                          await Future.delayed(
                                            const Duration(milliseconds: 500),
                                          );
                                          _refreshCart();
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$qty',
                                        style: GoogleFonts.lexendDeca(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _CircleActionButton(
                                        icon: Icons.add,
                                        onTap: () async {
                                          widget.onIncrement(p);
                                          await Future.delayed(
                                            const Duration(milliseconds: 500),
                                          );
                                          _refreshCart();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        }(),
                      ),
                    ),
                    _sectionBreak(),
                    const SizedBox(height: 12),
                    // Voucher info (Interaktif)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFDDE5ED)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                _isLoadingVouchers ? null : _showVoucherSheet,
                            borderRadius: BorderRadius.circular(28),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.ticket,
                                    color: Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _currentCart?.summary.voucherCode != null
                                          ? 'Voucher telah dipakai'
                                          : _availableVouchers.isNotEmpty
                                          ? 'Kamu ada ${_availableVouchers.length} voucher nganggur'
                                          : 'Gunakan / masukkan kode voucher',
                                      style: GoogleFonts.lexendDeca(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _currentCart?.summary.voucherCode !=
                                                    null
                                                ? AppColors.primaryLight
                                                : AppColors.primaryTextLight,
                                      ),
                                    ),
                                  ),
                                  if (_currentCart?.summary.voucherCode != null)
                                    InkWell(
                                      onTap: _removeVoucher,
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.secondaryTextLight,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionBreak(),
                    const SizedBox(height: 16),
                    // Detail pembayaran
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Detail pembayaran',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        thickness: 1,
                        height: 16,
                        color: Color(0xFFDDE5ED),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _priceRow(
                            'Harga',
                            totalPrice,
                            labelWeight: FontWeight.w400,
                            valueWeight: FontWeight.w400,
                            valueColor: AppColors.primaryTextLight,
                            labelSize: 14,
                            valueSize: 12,
                          ),
                          if ((_currentCart?.summary.discount ?? 0) > 0)
                            _priceRow(
                              'Potongan Voucher',
                              -(_currentCart?.summary.discount ?? 0),
                              labelWeight: FontWeight.w400,
                              valueWeight: FontWeight.w400,
                              valueColor: AppColors.secondaryTextLight,
                              labelSize: 14,
                              valueSize: 12,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              thickness: 1,
                              height: 1,
                              color: Color(0xFFDDE5ED),
                            ),
                          ),
                          _priceRow(
                            'Total pembayaran',
                            _currentCart?.summary.total ?? totalPrice,
                            labelWeight: FontWeight.w600,
                            valueWeight: FontWeight.w600,
                            valueColor: AppColors.primaryTextLight,
                            labelSize: 14,
                            valueSize: 12,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              thickness: 1,
                              height: 1,
                              color: Color(0xFFDDE5ED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionBreak(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _submitToAdmin,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          height: isSmallHeight ? 46 : 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit ke admin',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatRp(
                                  _currentCart?.summary.total ?? totalPrice,
                                ),
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitToAdmin() async {
    if (widget.cartApiService == null) return;
    final lokasiId = _selectedLocation?.id ?? 2;
    final remarks = _remarksController.text.trim();
    final ok = await widget.cartApiService!.submitCart(
      lokasiDeliveryId: lokasiId,
      deliveryRemarks: remarks,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan berhasil dikirim ke admin')),
      );
      widget.onRefresh?.call();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => const InspireMartScreen(
                initialTabIndex: 3,
                initialOrderTabIndex: 1,
              ),
        ),
      );
    } else {
      final msg =
          widget.cartApiService!.lastErrorMessage ?? 'Gagal submit ke admin';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _priceRow(
    String label,
    int value, {
    FontWeight labelWeight = FontWeight.w600,
    FontWeight valueWeight = FontWeight.w700,
    Color? valueColor,
    double? labelSize,
    double? valueSize,
  }) {
    final bool isNegative = value < 0;
    final String display =
        isNegative
            ? '-${formatRp(value.abs()).replaceFirst('Rp', '')}'
            : formatRp(value);
    final Color effectiveColor =
        valueColor ??
        (isNegative
            ? AppColors.secondaryTextLight
            : AppColors.primaryTextLight);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: labelSize,
                fontWeight: labelWeight,
                color: AppColors.primaryTextLight,
              ),
            ),
          ),
          Text(
            display,
            style: GoogleFonts.lexendDeca(
              fontSize: valueSize,
              fontWeight: valueWeight,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFF22C55E), size: 18),
      ),
    );
  }
}

Widget _sectionBreak() {
  return Container(height: 12, color: Colors.grey.shade100);
}
