import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/core/widgets/kkba_loading_indicator.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import '../service/mart_api_service.dart';
import '../service/cart_api_service.dart';
import '../presentation/providers/belanja_providers.dart';
import 'cart_confirm_page.dart';
import 'product_detail_page.dart';

class CategoryProductsPage extends ConsumerStatefulWidget {
  final int? kategoriId;
  final String? kategoriName;
  final String? kategoriImageUrl;
  final int? brandId;
  final String? brandName;

  const CategoryProductsPage({
    super.key,
    required int kategoriId,
    required String kategoriName,
    String? kategoriImageUrl,
  }) : kategoriId = kategoriId,
       kategoriName = kategoriName,
       kategoriImageUrl = kategoriImageUrl,
       brandId = null,
       brandName = null;

  const CategoryProductsPage.brand({
    super.key,
    required int brandId,
    required String brandName,
  }) : brandId = brandId,
       brandName = brandName,
       kategoriId = null,
       kategoriName = null,
       kategoriImageUrl = null;

  @override
  ConsumerState<CategoryProductsPage> createState() =>
      _CategoryProductsPageState();
}

class _CategoryProductsPageState extends ConsumerState<CategoryProductsPage> {
  final MartApiService _martApi = MartApiService();
  final CartApiService _cartApiService = CartApiService();
  final List<Product> _items = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  final int _perPage = 20;
  String _sortField = 'harga_setelah_diskon_mobile';
  String _sortDirection = 'desc';
  int _totalFound = 0;

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
  bool get _hasCategoryImage =>
      (widget.kategoriImageUrl ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fetch(page: 1);
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  Future<void> _refreshCart() async {
    await ref.read(cartProvider.notifier).fetchCart();
  }

  void _scheduleCartRefresh() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _refreshCart();
    });
  }

  int _getQty(Product p) {
    final cart = ref.read(cartProvider).cart;
    if (cart == null) return 0;
    final item = cart.items.where((i) => i.productId == p.id).firstOrNull;
    return item?.quantity ?? 0;
  }

  void _onAdd(Product p) async {
    await ref.read(cartProvider.notifier).addItem(productId: p.id, quantity: 1);
  }

  void _onIncrement(Product p) async {
    await ref
        .read(cartProvider.notifier)
        .updateQuantity(productId: p.id, quantity: _getQty(p) + 1);
  }

  void _onDecrement(Product p) async {
    final currentQty = _getQty(p);
    if (currentQty > 1) {
      await ref
          .read(cartProvider.notifier)
          .updateQuantity(productId: p.id, quantity: currentQty - 1);
    } else if (currentQty == 1) {
      await ref.read(cartProvider.notifier).removeItem(productId: p.id);
    }
  }

  void _openCart() async {
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
            color: Colors.black.withOpacity(0.05),
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
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp${_cartTotal}',
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
                        child: Icon(
                          Icons.arrow_forward,
                          color: const Color(0xFF22C55E),
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

  Future<void> _fetch({required int page}) async {
    if (page == 1) setState(() => _loading = true);
    final brandId = widget.brandId;
    final kategoriId = widget.kategoriId;
    final res =
        _query.trim().isEmpty
            ? (brandId != null
                ? await _martApi.getProductsByBrand(
                  brandId.toString(),
                  page: page,
                  perPage: _perPage,
                  sortField: _sortField,
                  sortDirection: _sortDirection,
                )
                : await _martApi.getProductsByCategory(
                  kategoriId.toString(),
                  page: page,
                  perPage: _perPage,
                  sortField: _sortField,
                  sortDirection: _sortDirection,
                ))
            : await _martApi.searchProducts(
              keywords: _query.trim(),
              brandId: brandId,
              kategoriId: kategoriId,
              page: page,
              perPage: _perPage,
              sortField: _sortField,
              sortDirection: _sortDirection,
            );
    if (!mounted) return;
    setState(() {
      if (page == 1) _items.clear();
      _items.addAll(res.items);
      _items.sort((a, b) {
        final cmp = a.price.compareTo(b.price);
        return _sortDirection == 'asc' ? cmp : -cmp;
      });
      _page = res.currentPage;
      _lastPage = res.lastPage;
      _totalFound = res.total;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    await _fetch(page: _page + 1);
  }

  void _onSearchSubmitted(String q) {
    setState(() {
      _query = q;
    });
    _fetch(page: 1);
  }

  void _toggleSort() {
    setState(() {
      _sortDirection = _sortDirection == 'asc' ? 'desc' : 'asc';
    });
    _fetch(page: 1);
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
        child:
            _loading && _items.isEmpty
                ? const Center(child: KkbaLoadingIndicator())
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                                    color: Colors.black.withOpacity(0.08),
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
                          const SizedBox(width: 8),
                          if (_hasCategoryImage)
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.kategoriImageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.image_not_supported,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 44,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semua Produk',
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTextLight,
                                  ),
                                ),
                                Text(
                                  'di ${widget.brandName ?? widget.kategoriName ?? ''}',
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF0F172A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF0F172A)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _onSearchSubmitted,
                                decoration: const InputDecoration.collapsed(
                                  hintText: 'Mau belanja apa hari ini ?',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _fetch(page: 1),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _toggleSort,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFDDE5ED),
                                        ),
                                      ),
                                      child: Text(
                                        'Urutkan : Harga ${_sortDirection == 'asc' ? 'terendah' : 'tertinggi'}',
                                        style: GoogleFonts.lexendDeca(
                                          color: AppColors.primaryTextLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_totalFound} Produk ditemukan',
                              style: GoogleFonts.lexendDeca(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTextLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.46,
                                  ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final p = _items[index];
                                final qty = _getQty(p);
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ProductDetailPage(
                                                  product: p,
                                                  related:
                                                      _items
                                                          .where((e) => e != p)
                                                          .toList(),
                                                ),
                                          ),
                                        )
                                        .then((_) {
                                          if (mounted) setState(() {});
                                        });
                                  },
                                  child: _GridProductCard(
                                    product: p,
                                    quantity: qty,
                                    onAdd: () {
                                      _onAdd(p);
                                      _scheduleCartRefresh();
                                    },
                                    onIncrement: () {
                                      _onIncrement(p);
                                      _scheduleCartRefresh();
                                    },
                                    onDecrement: () {
                                      _onDecrement(p);
                                      _scheduleCartRefresh();
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_loadingMore)
                              const Center(
                                child: KkbaLoadingIndicator(size: 44),
                              )
                            else if (_page < _lastPage)
                              Center(
                                child: Text(
                                  'Memuat produk ...',
                                  style: GoogleFonts.lexendDeca(
                                    color: AppColors.secondaryTextLight,
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
      bottomNavigationBar:
          hasCartItems
              ? SafeArea(top: false, child: _buildCartBar(cartHeight))
              : null,
    );
  }
}

class _GridProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _GridProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = product.discountPercent > 0;
    final int oldPrice = originalPrice(product.price, product.discountPercent);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            const SizedBox(height: 8),
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
                      color: Colors.black.withOpacity(0.08),
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
    );
  }
}
