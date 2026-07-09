import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import '../models/product.dart';
import '../components/product_card.dart';
import '../presentation/providers/belanja_providers.dart';
import '../service/cart_api_service.dart';
import 'cart_confirm_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;
  final List<Product> related;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.related,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  bool _descExpanded = false;
  final CartApiService _cartApiService = CartApiService();

  int get _cartCount =>
      ref
          .watch(cartProvider)
          .cart
          ?.items
          .fold<int>(0, (sum, item) => sum + item.quantity) ??
      0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  int _getQty(Product product) {
    final cartState = ref.watch(cartProvider);
    if (cartState.cart == null) return 0;
    for (final item in cartState.cart!.items) {
      if (item.productId == product.id) {
        return item.quantity;
      }
    }
    return 0;
  }

  Future<void> _addProduct(Product product) async {
    await ref
        .read(cartProvider.notifier)
        .addItem(productId: product.id, quantity: 1);
  }

  Future<void> _incrementProduct(Product product) async {
    final currentQty = _getQty(product);
    if (currentQty <= 0) {
      await _addProduct(product);
      return;
    }

    await ref
        .read(cartProvider.notifier)
        .updateQuantity(productId: product.id, quantity: currentQty + 1);
  }

  Future<void> _decrementProduct(Product product) async {
    final currentQty = _getQty(product);
    if (currentQty <= 0) return;

    if (currentQty == 1) {
      await ref.read(cartProvider.notifier).removeItem(productId: product.id);
    } else {
      await ref
          .read(cartProvider.notifier)
          .updateQuantity(productId: product.id, quantity: currentQty - 1);
    }
  }

  void _openCart() {
    final cartState = ref.read(cartProvider);
    final cartEntity = cartState.cart;
    if (cartEntity == null || cartEntity.items.isEmpty) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CartConfirmPage(cartApiService: _cartApiService),
          ),
        )
        .then((_) {
          if (!mounted) return;
          ref.read(cartProvider.notifier).fetchCart();
        });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final qty = _getQty(p);
    final bool hasDiscount = p.discountPercent > 0;
    final int oldPrice = originalPrice(p.price, p.discountPercent);
    final bool hasCartItems = _cartCount > 0;

    ref.listen<CartState>(cartProvider, (previous, next) {
      final err = next.error;
      if (err != null && err.isNotEmpty && err != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
          ref.read(cartProvider.notifier).clearError();
        });
      }
    });

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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Image from API (fallback to placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: Container(
                    color: Colors.white,
                    child:
                        (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                            ? Image.network(
                              p.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      LucideIcons.image,
                                      color: Color(0xFF9CA3AF),
                                      size: 64,
                                    ),
                                  ),
                            )
                            : const Center(
                              child: Icon(
                                LucideIcons.image,
                                color: Color(0xFF9CA3AF),
                                size: 64,
                              ),
                            ),
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
                style: GoogleFonts.lexendDeca(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextLight,
                ),
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
                    style: GoogleFonts.lexendDeca(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        formatRp(oldPrice),
                        style: GoogleFonts.lexendDeca(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough,
                        ),
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
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${p.name} merupakan produk dengan kualitas baik dan harga terjangkau. Deskripsi contoh untuk tampilan detail produk. Susu diperah secara segar dan higienis.\n\nSumber gambar bersifat placeholder.',
                    maxLines: _descExpanded ? null : 3,
                    overflow:
                        _descExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _descExpanded = !_descExpanded),
                    child: Text(
                      _descExpanded ? 'Tutup' : 'Selengkapnya',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Similar products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Serupa dan mungkin kamu suka',
                style: GoogleFonts.lexendDeca(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextLight,
                ),
              ),
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
                    quantity: _getQty(pr),
                    onAdd: () => _addProduct(pr),
                    onIncrement: () => _incrementProduct(pr),
                    onDecrement: () => _decrementProduct(pr),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailPage(
                                product: pr,
                                related: widget.related,
                              ),
                        ),
                      );
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: hasCartItems ? _openCart : null,
                  borderRadius: BorderRadius.circular(100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color:
                          hasCartItems
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF0FDF4),
                      border: Border.all(
                        color:
                            hasCartItems
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                hasCartItems
                                    ? Colors.white
                                    : const Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.shoppingCart,
                            size: 16,
                            color:
                                hasCartItems
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasCartItems
                                ? 'Keranjangmu ($_cartCount)'
                                : 'Keranjangmu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lexendDeca(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  hasCartItems
                                      ? Colors.white
                                      : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color:
                              hasCartItems
                                  ? Colors.white
                                  : const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: qty > 0 ? () => _decrementProduct(p) : null,
                          borderRadius: BorderRadius.circular(100),
                          child: Icon(
                            Icons.remove,
                            color:
                                qty > 0
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFBBF7D0),
                          ),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        alignment: Alignment.center,
                        child: Text(
                          '$qty',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (qty <= 0) {
                              _addProduct(p);
                            } else {
                              _incrementProduct(p);
                            }
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF22C55E),
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
      ),
    );
  }
}
