import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../service/mart_api_service.dart';
import '../models/section_model.dart';
import '../models/product.dart';
import '../models/cart_model.dart';
import '../service/cart_api_service.dart';
import 'product_detail_page.dart';
import 'cart_confirm_page.dart';
import '../components/product_card.dart';
import 'mart_search_page.dart';
import 'belanjaan_page.dart';
import 'category_products_page.dart';

class InspireMartScreen extends StatefulWidget {
  const InspireMartScreen({super.key});

  @override
  State<InspireMartScreen> createState() => _InspireMartScreenState();
}

class _InspireMartScreenState extends State<InspireMartScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0; // 0: Explor, 1: Pencarian, 2: Kategori, 3: Belanja
  final PageController _headerPageController = PageController();
  int _headerPageIndex = 0;
  // Riwayat pencarian sederhana (in-memory)
  final List<String> _searchHistory = [];

  // Categories
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  // Sections
  List<SectionModel> _sections = [];
  bool _isLoadingSections = true;

  bool get _isGlobalLoading => _isLoadingBanners || _isLoadingCategories || _isLoadingSections;

  // Dummy products (deprecated)
  final List<Product> _flashDeals = const [];
  final List<Product> _snacks = const [];

  // Gabungan produk untuk pencarian sederhana
  List<Product> _allProducts = [];

  // Real cart state
  final CartApiService _cartApiService = CartApiService();
  CartModel? _cart;
  bool _isLoadingCart = false;

  // Mapping product ID to quantity for fast UI updates
  final Map<String, int> _cartProductQuantities = {};

  int _getQty(Product p) => _cartProductQuantities[p.id] ?? 0;

  // Helpers for Cart
  int get _cartCount => _cart?.totalItems ?? 0;
  String get _cartTotal =>
      formatRp(_cart?.summary.total ?? 0).replaceAll('Rp', '');

  Future<void> _fetchCart() async {
    // Silent update if not initial load
    final cart = await _cartApiService.getCart();
    if (mounted && cart != null) {
      setState(() {
        _cart = cart;
        _cartProductQuantities.clear();
        for (var item in cart.items) {
          // Use productId from item wrapper, not the nested product which might have empty ID
          _cartProductQuantities[item.productId] =
              (_cartProductQuantities[item.productId] ?? 0) + item.quantity;
        }
      });
    }
  }

  // Debounce helper
  Map<String, DateTime> _lastUpdate = {};

  void _increment(Product p) {
    // Optimistic update
    final currentQty = _cartProductQuantities[p.id] ?? 0;
    final newQty = currentQty + 1;

    setState(() {
      _cartProductQuantities[p.id] = newQty;
    });

    // Call API
    _updateCartApi(p.id, newQty);
  }

  void _decrement(Product p) {
    final currentQty = _cartProductQuantities[p.id] ?? 0;
    if (currentQty <= 0) return;

    final newQty = currentQty - 1;
    setState(() {
      if (newQty == 0) {
        _cartProductQuantities.remove(p.id);
      } else {
        _cartProductQuantities[p.id] = newQty;
      }
    });

    // Call API (If 0, it should ideally call remove, but backend update(0) might handle it)
    // If newQty is 0, let's call remove if we have cart item id, or just update(0) and let backend handle
    // Since we only have product ID here easily, let's assume addToCart handles update logic or we use addToCart for positive changes
    // Wait, addToCart is usually for adding. updateQuantity needs cart_item_id.
    // We need to know if we are updating or adding.
    // Simplified logic: Always use addToCart for increment if not in cart? No, that creates duplicates usually.
    // Better: _updateCartApi handles the logic.
    _updateCartApi(p.id, newQty);
  }

  Future<void> _updateCartApi(String productId, int quantity) async {
    // Debounce: Wait 500ms before sending request
    /* 
       Note: A proper debounce would cancel previous timer. 
       For simplicity in this file without external rx libs:
       We will just fire the request. For production, use a Debouncer class.
    */

    // Check if item exists in _cart
    bool inCart = false;
    if (_cart != null) {
      for (var item in _cart!.items) {
        if (item.productId == productId) {
          inCart = true;
          break;
        }
      }
    }

    bool success = false;
    if (inCart) {
      if (quantity == 0) {
        success = await _cartApiService.removeItem(productId);
      } else {
        success = await _cartApiService.updateQuantity(productId, quantity);
      }
    } else {
      if (quantity > 0) {
        success = await _cartApiService.addToCart(productId, quantity);
      }
    }

    if (success) {
      // Sync cart from server to get correct totals and ids
      _fetchCart();
    } else {
      // Revert optimistic update
      final prevQty = _cart?.items
              .where((it) => it.productId == productId)
              .map((it) => it.quantity)
              .fold<int>(0, (a, b) => a + b) ??
          0;
      setState(() {
        if (prevQty == 0) {
          _cartProductQuantities.remove(productId);
        } else {
          _cartProductQuantities[productId] = prevQty;
        }
      });
      final msg = _cartApiService.lastErrorMessage ?? 'Gagal memperbarui keranjang (422)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  // --- Belanjaan (Orders) state ---
  int _orderTabIndex = 0; // 0: Dalam proses, 1: Riwayat
  final List<Map<String, dynamic>> _ordersInProcess = const [];
  final List<Map<String, dynamic>> _ordersHistory = const [
    {
      'code': 'MT-0459254916',
      'datetime': 'Jun 24, 2025 17:05',
      'summary':
          '1 Proguard Antibacterial Sabun, 1 Susu Ultra Cokelat, 1 Tolak Angin Madu',
      'items': 3,
      'total': 'Rp84.000',
      'status': 'DIBATALKAN',
      'statusColor': Color(0xFFEF4444),
    },
    {
      'code': 'MT-0459254916',
      'datetime': 'Jun 24, 2025 17:05',
      'summary':
          '1 Proguard Antibacterial Sabun, 1 Susu Ultra Cokelat, 1 Tolak Angin Madu',
      'items': 3,
      'total': 'Rp84.000',
      'status': 'SUKSES',
      'statusColor': Color(0xFF22C55E),
    },
  ];

  // Banners state
  List<BannerModel> _banners = [];
  bool _isLoadingBanners = true;
  final MartApiService _martApiService = MartApiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingBanners = true;
      _isLoadingCategories = true;
      _isLoadingSections = true;
    });

    // Run in parallel
    final results = await Future.wait([
      _martApiService.getBanners(),
      _martApiService.getCategories(),
      _martApiService.getSections(),
      _cartApiService.getCart(),
    ]);

    if (mounted) {
      setState(() {
        _banners = results[0] as List<BannerModel>;
        _categories = results[1] as List<CategoryModel>;
        _sections = results[2] as List<SectionModel>;

        final cart = results[3] as CartModel?;
        if (cart != null) {
          _cart = cart;
          _cartProductQuantities.clear();
          for (var item in cart.items) {
            _cartProductQuantities[item.productId] =
                (_cartProductQuantities[item.productId] ?? 0) + item.quantity;
          }
        }
        // Collect products for search/cart logic
        _allProducts =
            _sections
                .expand((section) => section.items)
                .where((item) => item.product != null)
                .map((item) => item.product!)
                .toList();
        _isLoadingBanners = false;
        _isLoadingCategories = false;
        _isLoadingSections = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerPageController.dispose();
    super.dispose();
  }

  void _openSearchPage() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => MartSearchPage(
              history: _searchHistory,
              products: _allProducts,
              getQty: _getQty,
              onAdd: _increment,
              onInc: _increment,
              onDec: _decrement,
              onSearched: (q) {
                if (q.trim().isEmpty) return;
                _searchHistory.removeWhere(
                  (e) => e.toLowerCase() == q.toLowerCase(),
                );
                _searchHistory.insert(0, q);
                setState(() {});
              },
              martApiService: _martApiService,
            ),
      ),
    );
    if (result is int) {
      setState(() => _currentTabIndex = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar dihilangkan, kontrol ada di header
      body: _buildBodyByTab(),
      bottomNavigationBar: _buildBottomArea(),
    );
  }

  Widget _buildBodyByTab() {
    if (_currentTabIndex == 0 && _isGlobalLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentTabIndex == 1) {
      // Pencarian tab: fokus ke pencarian dan hasil dummy
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          Text(
            'Hasil Pencarian',
            style: GoogleFonts.lexendDeca(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextLight,
            ),
          ),
          const SizedBox(height: 8),
          _buildHorizontalProducts(_flashDeals),
          const SizedBox(height: 12),
          _buildHorizontalProducts(_snacks),
          const SizedBox(height: 100),
        ],
      );
    }
    if (_currentTabIndex == 2) {
      // Kategori tab: tampilkan grid kategori
      return ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kategori',
              style: GoogleFonts.lexendDeca(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildIconGrid(),
          const SizedBox(height: 100),
        ],
      );
    }
    if (_currentTabIndex == 3) {
      // Belanjaan tab: hanya daftar pesanan (tanpa header/search bar)
      return ListView(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Belanjaan',
              style: GoogleFonts.lexendDeca(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTextLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOrdersTabs(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ...(_orderTabIndex == 0 ? _ordersInProcess : _ordersHistory)
                    .map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOrderCard(o),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 16),
                Text(
                  _orderTabIndex == 1
                      ? 'Memuat riwayat ...'
                      : 'Memuat dalam proses ...',
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
      );
    }
    // Explor tab (default)
    return CustomScrollView(
      slivers: [
        _buildSliverHeader(),
        SliverToBoxAdapter(child: const SizedBox(height: 50)),
        SliverToBoxAdapter(child: _buildCategoryChips()),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),

        // Dynamic sections from API
        if (_isLoadingSections)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_sections.isEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = _sections[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(section.title, showSeeAll: true),
                  const SizedBox(height: 8),
                  if (section.displayType == 'produk')
                    _buildSectionProducts(section.items)
                  else if (section.displayType == 'kategori')
                    _buildSectionCategories(section.items)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 16),
                ],
              );
            }, childCount: _sections.length),
          ),

        SliverPadding(padding: const EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildSectionProducts(List<SectionItemModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Map SectionItemModel to Product for compatibility
    // Note: SectionItemModel should contain Product data
    final products =
        items.where((i) => i.product != null).map((i) => i.product!).toList();

    return SizedBox(
      height: 250, // Height for product cards
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final qty = _getQty(product);
          return SizedBox(
            width: 150,
            child: ProductCard(
              product: product,
              quantity: qty,
              onAdd: () => _increment(product),
              onIncrement: () => _increment(product),
              onDecrement: () => _decrement(product),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      product: product,
                      getQty: _getQty,
                      onAdd: _increment,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                      related:
                          _allProducts.where((e) => e.id != product.id).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCategories(List<SectionItemModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final categories =
        items.where((i) => i.category != null).map((i) => i.category!).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryProductsPage(
                  kategoriId: cat.id,
                  kategoriName: cat.kategori,
                  getQty: _getQty,
                  onAdd: _increment,
                  onIncrement: _increment,
                  onDecrement: _decrement,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    cat.gambarKategoriUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat.kategori,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexendDeca(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryTextLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sliver header yang akan collapse saat di-scroll
  SliverPersistentHeader _buildSliverHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _MartHeaderDelegate(
        banners: _banners,
        pageController: _headerPageController,
        pageIndex: _headerPageIndex,
        onBack: () => Navigator.of(context).maybePop(),
        onCart: () {
          // Use real cart data for validation, but for UI we might need to pass products details if they are not fully in _cart
          // _cart only has minimal product data usually? CartItemModel has full Product model in our definition.

          // If _cart is null or empty, don't open
          if (_cart == null || _cart!.items.isEmpty) return;

          // Map CartItemModel back to Product list using enriched data from _allProducts (ensures imageUrl loaded)
          final uniqueProductIds = <String>{};
          final items = <Product>[];
          for (var item in _cart!.items) {
            if (!uniqueProductIds.add(item.productId)) continue;
            // Try find enriched product from sections
            final enriched = _allProducts.where((p) => p.id == item.productId).cast<Product?>().firstWhere(
                  (p) => p != null,
                  orElse: () => null,
                );
            if (enriched != null) {
              items.add(enriched);
              continue;
            }
            // Fallback to product from cart (may have limited fields)
            final base = item.product;
            if (base.id.isEmpty) {
              items.add(
                Product(
                  id: item.productId,
                  name: base.name,
                  price: base.price,
                  discountPercent: base.discountPercent,
                  imageUrl: base.imageUrl,
                  isStockAvailable: base.isStockAvailable,
                ),
              );
            } else {
              items.add(base);
            }
          }

          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder:
                      (_) => CartConfirmPage(
                        items: items,
                        getQty: _getQty,
                        onIncrement: _increment,
                        onDecrement: _decrement,
                        cart: _cart, // Pass full cart model
                        cartApiService:
                            _cartApiService, // Pass service for checkout/voucher
                        onRefresh:
                            _fetchCart, // Callback to refresh when returning
                      ),
                ),
              )
              .then((_) => _fetchCart()); // Refresh on return
        },
        searchController: _searchController,
        onSearchTap: _openSearchPage,
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Slider gambar penuh
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      _isLoadingBanners
                          ? const Center(child: CircularProgressIndicator())
                          : PageView.builder(
                            controller: _headerPageController,
                            itemCount: _banners.isEmpty ? 1 : _banners.length,
                            onPageChanged:
                                (i) => setState(() => _headerPageIndex = i),
                            itemBuilder: (context, index) {
                              if (_banners.isEmpty) {
                                return Image.asset(
                                  'assets/images/background_simpin_mobile.png',
                                  fit: BoxFit.cover,
                                );
                              }
                              final banner = _banners[index];
                              return Image.network(
                                banner.image,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Image.asset(
                                      'assets/images/background_simpin_mobile.png',
                                      fit: BoxFit.cover,
                                    ),
                              );
                            },
                          ),
                ),
                // Overlay atas: tombol kembali, judul, keranjang
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Inspire Mart',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BelanjaanPage(),
                                ),
                              ),
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
                              LucideIcons.shoppingCart,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Indikator slider tepat di atas search bar
                if (!_isLoadingBanners && _banners.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_banners.length, (i) {
                            final bool active = i == _headerPageIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 8 : 6,
                              height: active ? 8 : 6,
                              decoration: BoxDecoration(
                                color:
                                    active
                                        ? AppColors.primaryLight
                                        : const Color(0xFFCBD5E1),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Search bar besar di bawah header (full width) + tombol filter
          Positioned(
            left: 16,
            right: 16,
            bottom: -28,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF0F172A)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            readOnly: true,
                            onTap: _openSearchPage,
                            decoration: InputDecoration.collapsed(
                              hintText: 'Pepsodent Pasta Gigi',
                              hintStyle: GoogleFonts.lexendDeca(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextLight,
                              ),
                            ),
                            style: GoogleFonts.lexendDeca(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryTextLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Ambil maksimal 8 kategori
    final displayCategories = _categories.take(8).toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCategories.length + 1, // tambah tombol "Lihat"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isSeeButton = index == displayCategories.length;
          if (isSeeButton) {
            return InkWell(
              onTap: () => setState(() => _currentTabIndex = 2),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Lihat',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            );
          }

          final cat = displayCategories[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryProductsPage(
                    kategoriId: cat.id,
                    kategoriName: cat.kategori,
                    getQty: _getQty,
                    onAdd: _increment,
                    onIncrement: _increment,
                    onDecrement: _decrement,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                cat.kategori,
                style: GoogleFonts.lexendDeca(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment:
            showSeeAll
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexendDeca(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextLight,
              height: 1.0,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: () {},
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.lexendDeca(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProducts(List<Product> products) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = products[index];
          return ProductCard(
            product: p,
            quantity: _getQty(p),
            onAdd: () => _increment(p),
            onIncrement: () => _increment(p),
            onDecrement: () => _decrement(p),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => ProductDetailPage(
                        product: p,
                        getQty: _getQty,
                        onAdd: _increment,
                        onIncrement: _increment,
                        onDecrement: _decrement,
                        related: _allProducts.where((e) => e != p).toList(),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryProductsPage(
                    kategoriId: cat.id,
                    kategoriName: cat.kategori,
                    getQty: _getQty,
                    onAdd: _increment,
                    onIncrement: _increment,
                    onDecrement: _decrement,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      cat.gambarKategoriUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.kategori,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryTextLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                onTap: () {
                  // Deduplicate by product id and prefer entries with imageUrl
                  final Map<String, Product> unique = {};
                  for (final p in _allProducts) {
                    final qty = _getQty(p);
                    if (qty <= 0) continue;
                    final prev = unique[p.id];
                    if (prev == null) {
                      unique[p.id] = p;
                    } else {
                      final prevHasImg = prev.imageUrl != null && prev.imageUrl!.isNotEmpty;
                      final newHasImg = p.imageUrl != null && p.imageUrl!.isNotEmpty;
                      if (!prevHasImg && newHasImg) unique[p.id] = p;
                    }
                  }
                  final items = unique.values.toList();
                  if (items.isEmpty) return;
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (_) => CartConfirmPage(
                                items: items,
                                getQty: _getQty,
                                onIncrement: _increment,
                                onDecrement: _decrement,
                                cart: _cart,
                                cartApiService: _cartApiService,
                                onRefresh: _fetchCart,
                              ),
                        ),
                      )
                      .then((_) => _fetchCart());
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: effectiveHeight - 8,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // Hijau utama
                    borderRadius: BorderRadius.circular(100), // Bentuk pill
                  ),
                  child: Row(
                    children: [
                      // Kiri: judul dan subtitel
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

                      // Harga di kanan
                      Text(
                        'Rp${_cartTotal}',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol panah bundar
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

  Widget _buildBottomArea() {
    final media = MediaQuery.of(context);
    final bool isSmallHeight = media.size.height < 700;
    final double navHeight = isSmallHeight ? 54.0 : 62.0;
    final double cartHeight = isSmallHeight ? 50.0 : 56.0;
    final bool hasCartItems = _cartCount > 0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCartItems) _buildCartBar(cartHeight),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: navHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMartNavItem(
                      icon: LucideIcons.compass,
                      label: 'Explor',
                      index: 0,
                    ),
                    _buildMartNavItem(
                      icon: LucideIcons.search,
                      label: 'Pencarian',
                      index: 1,
                    ),
                    _buildMartNavItem(
                      icon: Icons.grid_view,
                      label: 'Kategori',
                      index: 2,
                    ),
                    _buildMartNavItem(
                      icon: LucideIcons.shoppingBag,
                      label: 'Belanjaan',
                      index: 3,
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

  Widget _buildMartNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _currentTabIndex == index;
    final Color color =
        isSelected ? AppColors.primaryLight : AppColors.secondaryTextLight;
    final media = MediaQuery.of(context);
    final bool isSmallHeight = media.size.height < 700;
    final double fontSize = isSmallHeight ? 10.0 : 11.0;
    final double iconSize = isSmallHeight ? 22.0 : 24.0;
    final double indicatorHeight = isSmallHeight ? 2.0 : 3.0;
    final double indicatorWidth =
        isSelected ? (isSmallHeight ? 20.0 : 24.0) : 0.0;
    final double gap1 = isSmallHeight ? 4.0 : 6.0;
    final double gap2 = isSmallHeight ? 3.0 : 4.0;

    return InkWell(
      onTap: () {
        if (index == 1) {
          _openSearchPage();
          return;
        }
        if (index == 3) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BelanjaanPage()));
          return;
        }
        setState(() => _currentTabIndex = index);
      },
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
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: gap2),
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Belanjaan helpers ---
extension on _InspireMartScreenState {
  Widget _buildOrdersTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE5ED)),
      ),
      child: Row(
        children: [
          _ordersTabButton('Dalam proses', 0),
          _ordersTabButton('Riwayat', 1),
        ],
      ),
    );
  }

  Widget _ordersTabButton(String label, int index) {
    final bool selected = _orderTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _orderTabIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.lexendDeca(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color:
                  selected
                      ? AppColors.primaryTextLight
                      : AppColors.secondaryTextLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final Color borderColor = const Color(0xFFDDE5ED);
    final Color statusColor =
        o['statusColor'] as Color? ?? AppColors.primaryLight;
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
                        o['code'] as String,
                        style: GoogleFonts.lexendDeca(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o['datetime'] as String,
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
                    o['status'] as String,
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
            Text(
              o['summary'] as String,
              style: GoogleFonts.lexendDeca(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryTextLight,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${o['items']} item | ${o['total']}',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                ),
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
                      'Mau lagi',
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
}

class _MartHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<BannerModel> banners;
  final PageController pageController;
  final int pageIndex;
  final VoidCallback onBack;
  final VoidCallback onCart;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;

  _MartHeaderDelegate({
    required this.banners,
    required this.pageController,
    required this.pageIndex,
    required this.onBack,
    required this.onCart,
    required this.searchController,
    required this.onSearchTap,
  });

  @override
  double get minExtent => 193;

  @override
  double get maxExtent => 340;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsed = t > 0.8;
    return Container(
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: (1.0 - t).clamp(0.0, 1.0),
              child: PageView.builder(
                controller: pageController,
                itemCount: banners.isEmpty ? 1 : banners.length,
                itemBuilder: (context, index) {
                  if (banners.isEmpty) {
                    return Image.asset(
                      'assets/images/background_simpin_mobile.png',
                      fit: BoxFit.cover,
                    );
                  }
                  final banner = banners[index];
                  return Image.network(
                    banner.image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Image.asset(
                          'assets/images/background_simpin_mobile.png',
                          fit: BoxFit.cover,
                        ),
                  );
                },
              ),
            ),
          ),

          // Overlay controls (berbeda saat collapsed)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Inspire Mart',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onCart,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.shoppingCart,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Search bar: expanded => melayang di bawah; collapsed => di bawah row
                  if (collapsed)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    readOnly: true,
                                    onTap: onSearchTap,
                                    decoration: InputDecoration.collapsed(
                                      hintText: 'Restock sugar',
                                      hintStyle: GoogleFonts.lexendDeca(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextLight,
                                      ),
                                    ),
                                    style: GoogleFonts.lexendDeca(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primaryTextLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Expanded indicators & floating search (hanya saat belum collapsed)
          if (!collapsed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(banners.length, (i) {
                      final bool active = i == pageIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        decoration: BoxDecoration(
                          color:
                              active
                                  ? AppColors.primaryLight
                                  : const Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          if (!collapsed)
            Positioned(
              left: 16,
              right: 16,
              bottom: -28,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF0F172A)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              readOnly: true,
                              onTap: onSearchTap,
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Restock sugar',
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
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MartHeaderDelegate oldDelegate) {
    return oldDelegate.pageIndex != pageIndex || oldDelegate.banners != banners;
  }
}

// Halaman Pencarian telah dipisahkan ke file: lib/feature/belanja/screens/mart_search_page.dart
