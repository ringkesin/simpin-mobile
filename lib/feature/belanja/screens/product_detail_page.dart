import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';
import '../components/product_card.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final int Function(Product) getQty;
  final void Function(Product) onAdd;
  final void Function(Product) onIncrement;
  final void Function(Product) onDecrement;
  final List<Product> related;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.getQty,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.related,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final qty = widget.getQty(p);
    final bool hasDiscount = p.discountPercent > 0;
    final int oldPrice = originalPrice(p.price, p.discountPercent);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            // Header back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                      ),
                      child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),

            // Image placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: Icon(LucideIcons.image, color: Color(0xFF9CA3AF), size: 64)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                p.name,
                style: GoogleFonts.lexendDeca(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
              ),
            ),

            const SizedBox(height: 8),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRp(p.price),
                    style: GoogleFonts.lexendDeca(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryTextLight),
                  ),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        formatRp(oldPrice),
                        style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.grey.shade200),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deskripsi', style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
                  const SizedBox(height: 8),
                  Text(
                    '${p.name} merupakan produk dengan kualitas baik dan harga terjangkau. Deskripsi contoh untuk tampilan detail produk. Susu diperah secara segar dan higienis.\n\nSumber gambar bersifat placeholder.',
                    maxLines: _descExpanded ? null : 3,
                    overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: GoogleFonts.lexendDeca(fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.secondaryTextLight),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _descExpanded = !_descExpanded),
                    child: Text(
                      _descExpanded ? 'Tutup' : 'Selengkapnya',
                      style: GoogleFonts.lexendDeca(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
            ),

            // Similar products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Serupa dan mungkin kamu suka', style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final pr = widget.related[index];
                  return ProductCard(
                    product: pr,
                    quantity: widget.getQty(pr),
                    onAdd: () => widget.onAdd(pr),
                    onIncrement: () => widget.onIncrement(pr),
                    onDecrement: () => widget.onDecrement(pr),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          product: pr,
                          getQty: widget.getQty,
                          onAdd: widget.onAdd,
                          onIncrement: widget.onIncrement,
                          onDecrement: widget.onDecrement,
                          related: widget.related,
                        ),
                      ));
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primaryLight),
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Keranjangmu (${qty})',
                    style: GoogleFonts.lexendDeca(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (qty <= 0) {
                      widget.onAdd(p);
                    } else {
                      widget.onIncrement(p);
                    }
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text('Tambah', style: GoogleFonts.lexendDeca(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}