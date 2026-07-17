import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import '../models/product.dart';
import '../presentation/providers/belanja_providers.dart';
import '../service/cart_api_service.dart';
import 'cart_confirm_page.dart';
import 'product_detail_page.dart';

class SectionProductsPage extends ConsumerStatefulWidget {
  final String title;
  final List<Product> products;
  final List<Product> allProducts;

  const SectionProductsPage({
    super.key,
    required this.title,
    required this.products,
    required this.allProducts,
  });

  @override
  ConsumerState<SectionProductsPage> createState() => _SectionProductsPageState();
}

class _SectionProductsPageState extends ConsumerState<SectionProductsPage> {
  final CartApiService _cartApiService = CartApiService();

  int get _cartCount =>
      ref
          .watch(cartProvider)
          .cart
          ?.items
          .fold<int>(0, (sum, item) => sum + item.quantity) ??
      0;

  String get _cartTotal => formatRp(
    ref.watch(cartProvider).cart?.summary.total ?? 0,
  ).replaceAll('Rp', '');

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

  Future<void> _onAdd(Product product) async {
    await ref
        .read(cartProvider.notifier)
        .addItem(productId: product.id, quantity: 1);
  }

  Future<void> _onIncrement(Product product) async {
    final currentQty = _getQty(product);
    if (currentQty <= 0) {
      await _onAdd(product);
      return;
    }
    await ref
        .read(cartProvider.notifier)
        .updateQuantity(productId: product.id, quantity: currentQty + 1);
  }

  Future<void> _onDecrement(Product product) async {
    final currentQty = _getQty(product);
    if (currentQty <= 0) return;
    if (currentQty == 1) {
      await ref.read(cartProvider.notifier).removeItem(productId: product.id);
      return;
    }
    await ref
        .read(cartProvider.notifier)
        .updateQuantity(productId: product.id, quantity: currentQty - 1);
  }

  Future<void> _refreshCart() async {
    await ref.read(cartProvider.notifier).fetchCart();
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
        .then((_) => _refreshCart());
  }

  Widget _buildCartBar([double? barHeight]) {
    final double effectiveHeight = barHeight ?? 58.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        height: effectiveHeight,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openCart,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: effectiveHeight - 8,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_cartCount item',
                              style: GoogleFonts.lexendDeca(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Harga yang tertera merupakan esti...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexendDeca(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp$_cartTotal',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isSmallHeight = media.size.height < 700;
    final double cartHeight = isSmallHeight ? 50.0 : 56.0;
    final bool hasCartItems = _cartCount > 0;

    ref.listen<CartState>(cartProvider, (previous, next) {
      final err = next.error;
      if (err != null && err.isNotEmpty && err != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          ref.read(cartProvider.notifier).clearError();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexendDeca(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.46,
                ),
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final p = widget.products[index];
                  final qty = _getQty(p);
                  return _SectionGridProductCard(
                    product: p,
                    quantity: qty,
                    onAdd: () => _onAdd(p),
                    onIncrement: () => _onIncrement(p),
                    onDecrement: () => _onDecrement(p),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailPage(
                                product: p,
                                related:
                                    widget.allProducts
                                        .where((e) => e.id != p.id)
                                        .toList(),
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          hasCartItems
              ? SafeArea(top: false, child: _buildCartBar(cartHeight))
              : null,
    );
  }
}

class _SectionGridProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTap;

  const _SectionGridProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = product.discountPercent > 0;
    final int oldPrice = originalPrice(product.price, product.discountPercent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child:
                              product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.contain,
                                  )
                                  : const Center(
                                    child: Icon(
                                      LucideIcons.image,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${product.discountPercent}%',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRp(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexendDeca(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexendDeca(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryTextLight,
                ),
              ),
              const Spacer(),
              if (quantity <= 0)
                OutlinedButton(
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tambah',
                      maxLines: 1,
                      style: GoogleFonts.lexendDeca(
                        color: const Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: onDecrement,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.remove, color: Color(0xFF22C55E)),
                        ),
                      ),
                      Text(
                        '$quantity',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add, color: Color(0xFF22C55E)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
