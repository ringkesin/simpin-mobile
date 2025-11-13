import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';

class CartConfirmPage extends StatefulWidget {
  final List<Product> items;
  final int Function(Product) getQty;
  final void Function(Product) onIncrement;
  final void Function(Product) onDecrement;

  const CartConfirmPage({
    super.key,
    required this.items,
    required this.getQty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<CartConfirmPage> createState() => _CartConfirmPageState();
}

class _CartConfirmPageState extends State<CartConfirmPage> {
  int get totalPrice {
    int total = 0;
    for (final p in widget.items) {
      total += widget.getQty(p) * p.price;
    }
    return total;
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
                    // Lokasi pengantaran (non-interaktif untuk sementara)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          // no border for location section as per design
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
                                    'Gedung Kantor Pusat',
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
                              Icons.more_vert,
                              color: Color(0xFF0F172A),
                              size: 20,
                            ),
                          ],
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
                          vertical: 12,
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
                              child: Text(
                                'Catatan untuk pengantar ...',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondaryTextLight,
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
                        children:
                            widget.items.map((p) {
                              final qty = widget.getQty(p);
                              if (qty <= 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
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
                                            formatRp(p.price),
                                            style: GoogleFonts.lexendDeca(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  AppColors.secondaryTextLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _CircleActionButton(
                                          icon: Icons.remove,
                                          onTap: () {
                                            widget.onDecrement(p);
                                            setState(() {});
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
                                          onTap: () {
                                            widget.onIncrement(p);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    _sectionBreak(),
                    const SizedBox(height: 12),
                    // Voucher info (non-interaktif)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Color(0xFFDDE5ED)),
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
                                'Kamu ada 1 voucher nganggur',
                                style: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.secondaryTextLight,
                            ),
                          ],
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
                      child: Divider(thickness: 1, height: 16, color: Color(0xFFDDE5ED)),
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
                          _priceRow(
                            'Potongan Voucher',
                            -5000,
                            labelWeight: FontWeight.w400,
                            valueWeight: FontWeight.w400,
                            valueColor: AppColors.secondaryTextLight,
                            labelSize: 14,
                            valueSize: 12,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(thickness: 1, height: 1, color: Color(0xFFDDE5ED)),
                          ),
                          _priceRow(
                            'Total pembayaran',
                            (totalPrice - 5000),
                            labelWeight: FontWeight.w600,
                            valueWeight: FontWeight.w600,
                            valueColor: AppColors.primaryTextLight,
                            labelSize: 14,
                            valueSize: 12,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(thickness: 1, height: 1, color: Color(0xFFDDE5ED)),
                          ),
                        ],
                      ),
                    ),
                    _sectionBreak(),
                    const SizedBox(height: 16),
                    // Pembayaran via GoPay (non-interaktif)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.wallet,
                              color: Color(0xFF0F172A),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pembayaran via GoPay',
                                style: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                            ),
                            Text(
                              formatRp(totalPrice - 5000),
                              style: GoogleFonts.lexendDeca(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryTextLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.more_vert,
                              color: Color(0xFF0F172A),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _sectionBreak(),
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
                        onTap: () {},
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
                                'Bayar sekarang',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatRp(totalPrice - 5000),
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
