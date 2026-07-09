import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import 'package:kkba_mobile/core/widgets/kkba_loading_indicator.dart';
import '../models/product.dart';
import '../service/mart_api_service.dart';
import 'product_detail_page.dart';
import '../presentation/providers/belanja_providers.dart';

class MartSearchPage extends ConsumerStatefulWidget {
  final List<String> history;
  final List<Product> products;
  final void Function(String) onSearched;
  final MartApiService? martApiService;

  const MartSearchPage({
    super.key,
    required this.history,
    required this.products,
    required this.onSearched,
    this.martApiService,
  });

  @override
  ConsumerState<MartSearchPage> createState() => _MartSearchPageState();
}

class _MartSearchPageState extends ConsumerState<MartSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  bool _loading = false;
  bool _loadingMore = false;
  List<Product> _serverResults = [];
  String _activeSearchQuery = '';
  int _page = 1;
  int _lastPage = 1;
  int _totalFound = 0;

  bool get _isServerMode => widget.martApiService != null;

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

  void _addProduct(Product product) {
    ref.read(cartProvider.notifier).addItem(productId: product.id, quantity: 1);
  }

  void _incrementProduct(Product product) {
    ref.read(cartProvider.notifier).addItem(productId: product.id, quantity: 1);
  }

  void _decrementProduct(Product product) {
    final currentQty = _getQty(product);
    if (currentQty <= 0) return;

    if (currentQty == 1) {
      ref.read(cartProvider.notifier).removeItem(productId: product.id);
    } else {
      ref
          .read(cartProvider.notifier)
          .updateQuantity(productId: product.id, quantity: currentQty - 1);
    }
  }

  List<Product> get _filtered {
    if (_query.trim().isEmpty) return [];
    if (_isServerMode) return _serverResults;
    final q = _query.toLowerCase();
    return widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  List<Product> get _displayedProducts =>
      _query.trim().isEmpty ? widget.products : _filtered;

  void _doSearch(String q) {
    setState(() => _query = q);
    widget.onSearched(q);
    if (_isServerMode) {
      _searchServer(q);
    }
  }

  Future<void> _searchServer(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _serverResults = [];
        _activeSearchQuery = '';
        _page = 1;
        _lastPage = 1;
        _totalFound = 0;
        _loading = false;
        _loadingMore = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadingMore = false;
      _activeSearchQuery = q.trim();
      _page = 1;
      _lastPage = 1;
      _totalFound = 0;
    });
    final res = await widget.martApiService!.searchProducts(
      keywords: q.trim(),
      page: 1,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      _serverResults = res.items;
      _page = res.currentPage;
      _lastPage = res.lastPage;
      _totalFound = res.total;
      _loading = false;
    });
  }

  Future<void> _loadMoreSearchResults() async {
    if (!_isServerMode) return;
    if (_loading || _loadingMore) return;
    if (_activeSearchQuery.isEmpty) return;
    if (_page >= _lastPage) return;

    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final res = await widget.martApiService!.searchProducts(
      keywords: _activeSearchQuery,
      page: nextPage,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      _serverResults = [..._serverResults, ...res.items];
      _page = res.currentPage;
      _lastPage = res.lastPage;
      _totalFound = res.total;
      _loadingMore = false;
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMoreSearchResults();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      Text(
                        'Pencarian',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF0F172A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            style: GoogleFonts.lexendDeca(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryTextLight,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Mau belanja apa hari ini ?',
                              hintStyle: GoogleFonts.lexendDeca(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextLight,
                              ),
                            ),
                            onSubmitted: _doSearch,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade200),
                ],
              ),
            ),

            if (widget.history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pernah kamu cari',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.history.take(8).map((h) {
                            return InkWell(
                              onTap: () {
                                _controller.text = h;
                                _controller.selection = TextSelection.collapsed(
                                  offset: h.length,
                                );
                                _doSearch(h);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      size: 14,
                                      color: AppColors.primaryTextLight
                                          .withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      h,
                                      style: GoogleFonts.lexendDeca(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryTextLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Hasil pencarian'
                          : 'Hasil pencarian “$_query”',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: KkbaLoadingIndicator()),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_query.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '${_isServerMode ? _totalFound : _displayedProducts.length} Produk ditemukan',
                                style: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTextLight,
                                ),
                              ),
                            ),
                          if (_displayedProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  _query.trim().isEmpty
                                      ? 'Silakan cari produk terlebih dahulu'
                                      : 'Produk tidak ditemukan',
                                  style: GoogleFonts.lexendDeca(
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              ),
                            )
                          else
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
                              itemCount: _displayedProducts.length,
                              itemBuilder: (context, index) {
                                final p = _displayedProducts[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProductDetailPage(
                                              product: p,
                                              related:
                                                  _displayedProducts
                                                      .where((e) => e != p)
                                                      .toList(),
                                            ),
                                      ),
                                    );
                                  },
                                  child: _GridProductCard(
                                    product: p,
                                    quantity: _getQty(p),
                                    onAdd: () => _addProduct(p),
                                    onIncrement: () => _incrementProduct(p),
                                    onDecrement: () => _decrementProduct(p),
                                  ),
                                );
                              },
                            ),
                          if (_loadingMore)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Center(
                                child: KkbaLoadingIndicator(size: 44),
                              ),
                            )
                          else if (_isServerMode &&
                              _activeSearchQuery.isNotEmpty &&
                              _page < _lastPage)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Center(
                                child: Text(
                                  'Scroll untuk memuat produk berikutnya',
                                  style: GoogleFonts.lexendDeca(
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return; // stay on search
          Navigator.of(context).pop(i);
        },
      ),
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
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSmallHeight = MediaQuery.of(context).size.height < 700;
    final double fontSize = isSmallHeight ? 10.0 : 11.0;
    final double iconSize = isSmallHeight ? 22.0 : 24.0;
    final double indicatorHeight = isSmallHeight ? 2.0 : 3.0;

    Widget item(IconData icon, String label, int index) {
      final bool isSelected = currentIndex == index;
      final Color color =
          isSelected ? AppColors.primaryLight : AppColors.secondaryTextLight;
      final double indicatorWidth =
          isSelected ? (isSmallHeight ? 20.0 : 24.0) : 0.0;
      final double gap1 = isSmallHeight ? 4.0 : 6.0;
      final double gap2 = isSmallHeight ? 3.0 : 4.0;

      return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: indicatorHeight,
                width: indicatorWidth,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: gap1),
              Icon(icon, size: iconSize, color: color),
              SizedBox(height: gap2),
              Text(
                label,
                style: GoogleFonts.lexendDeca(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            item(LucideIcons.compass, 'Explor', 0),
            item(LucideIcons.search, 'Pencarian', 1),
            item(Icons.grid_view, 'Kategori', 2),
            item(LucideIcons.shoppingBag, 'Belanjaan', 3),
          ],
        ),
      ),
    );
  }
}
