import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';
import 'product_detail_page.dart';
import 'cart_confirm_page.dart';
import '../components/product_card.dart';
import 'mart_search_page.dart';
import 'belanjaan_page.dart';

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

  // Gambar header (gunakan aset yang tersedia sebagai contoh)
  final List<String> _headerImages = const [
    'assets/images/background_simpin_mobile.png',
    'assets/images/cardbg.png',
    'assets/images/logokkba_header.png',
  ];

  // Dummy categories
  final List<String> _categories = const [
    'Alat Mandi', 'Snack', 'Minuman', 'Obat', 'Bahan Pokok', 'Susu', 'Makanan Instan', 'Buah & Sayuran', 'Roti', 'Air Mineral', 'Deterjen', 'Tisu'
  ];

  // Dummy products
  final List<Product> _flashDeals = const [
    Product(name: 'Ultra Milk Susu UHT Full Cream 1 L', price: 14900, discountPercent: 27),
    Product(name: 'Sunlight Sabun Cuci Piring Jeruk Nipis 1L', price: 6000, discountPercent: 50),
    Product(name: 'Minyak Goreng Pet 2L', price: 35800, discountPercent: 18),
  ];

  final List<Product> _snacks = const [
    Product(name: 'Chitato Keripik Kentang Sapi Panggang', price: 17500, discountPercent: 0),
    Product(name: 'Japota Keripik Kentang Happy', price: 11000, discountPercent: 0),
    Product(name: 'Cheetos Twists Jagung Bakar', price: 6600, discountPercent: 6),
  ];

  // Gabungan produk untuk pencarian sederhana
  late final List<Product> _allProducts = [..._flashDeals, ..._snacks];

  // Minimal cart state for demo
  int _cartCount = 0;
  int _cartTotal = 13900;
  // Kuantitas per produk (key pakai nama produk untuk demo)
  final Map<String, int> _cartQuantities = {};

  int _getQty(Product p) => _cartQuantities[p.name] ?? 0;
  void _increment(Product p) {
    final current = _cartQuantities[p.name] ?? 0;
    _cartQuantities[p.name] = current + 1;
    _cartCount += 1;
    _cartTotal += p.price;
    setState(() {});
  }
  void _decrement(Product p) {
    final current = _cartQuantities[p.name] ?? 0;
    if (current <= 0) return;
    if (current - 1 == 0) {
      _cartQuantities.remove(p.name);
    } else {
      _cartQuantities[p.name] = current - 1;
    }
    _cartCount -= 1;
    _cartTotal -= p.price;
    setState(() {});
  }

  // --- Belanjaan (Orders) state ---
  int _orderTabIndex = 0; // 0: Dalam proses, 1: Riwayat
  final List<Map<String, dynamic>> _ordersInProcess = const [];
  final List<Map<String, dynamic>> _ordersHistory = const [
    {
      'code': 'MT-0459254916',
      'datetime': 'Jun 24, 2025 17:05',
      'summary': '1 Proguard Antibacterial Sabun, 1 Susu Ultra Cokelat, 1 Tolak Angin Madu',
      'items': 3,
      'total': 'Rp84.000',
      'status': 'DIBATALKAN',
      'statusColor': Color(0xFFEF4444),
    },
    {
      'code': 'MT-0459254916',
      'datetime': 'Jun 24, 2025 17:05',
      'summary': '1 Proguard Antibacterial Sabun, 1 Susu Ultra Cokelat, 1 Tolak Angin Madu',
      'items': 3,
      'total': 'Rp84.000',
      'status': 'SUKSES',
      'statusColor': Color(0xFF22C55E),
    },
  ];

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
        builder: (_) => MartSearchPage(
          history: _searchHistory,
          products: _allProducts,
          getQty: _getQty,
          onAdd: _increment,
          onInc: _increment,
          onDec: _decrement,
          onSearched: (q) {
            if (q.trim().isEmpty) return;
            _searchHistory.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
            _searchHistory.insert(0, q);
            setState(() {});
          },
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
    if (_currentTabIndex == 1) {
      // Pencarian tab: fokus ke pencarian dan hasil dummy
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          Text('Hasil Pencarian', style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
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
            child: Text('Kategori', style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
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
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOrderCard(o),
                        ))
                    .toList(),
                const SizedBox(height: 16),
                Text(
                  _orderTabIndex == 1 ? 'Memuat riwayat ...' : 'Memuat dalam proses ...',
                  style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.secondaryTextLight),
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
        SliverToBoxAdapter(child: _buildSectionTitle('Gajian pasti untung s.d 60%')),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: _buildHorizontalProducts(_flashDeals)),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildSectionTitle('Kebutuhan rumah tangga', showSeeAll: false)),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildIconGrid()),
        SliverToBoxAdapter(child: const SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildSectionTitle('Jajanan enak')),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: _buildHorizontalProducts(_snacks)),
        SliverPadding(padding: const EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  // Sliver header yang akan collapse saat di-scroll
  SliverPersistentHeader _buildSliverHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _MartHeaderDelegate(
        images: _headerImages,
        pageController: _headerPageController,
        pageIndex: _headerPageIndex,
        onBack: () => Navigator.of(context).maybePop(),
        onCart: () {
          final items = _allProducts.where((p) => _getQty(p) > 0).toList();
          if (items.isEmpty) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CartConfirmPage(
              items: items,
              getQty: _getQty,
              onIncrement: _increment,
              onDecrement: _decrement,
            ),
          ));
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
                  child: PageView.builder(
                    controller: _headerPageController,
                    itemCount: _headerImages.length,
                    onPageChanged: (i) => setState(() => _headerPageIndex = i),
                    itemBuilder: (context, index) {
                      final path = _headerImages[index];
                      return Image.asset(path, fit: BoxFit.cover);
                    },
                  ),
                ),
                // Overlay atas: tombol kembali, judul, keranjang
                SafeArea(
                  bottom: false,
                  child: Padding(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Inspire Mart',
                            style: GoogleFonts.lexendDeca(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BelanjaanPage()),
                          ),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                            ),
                            child: const Icon(LucideIcons.shoppingCart, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Indikator slider tepat di atas search bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_headerImages.length, (i) {
                          final bool active = i == _headerPageIndex;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 8 : 6,
                            height: active ? 8 : 6,
                            decoration: BoxDecoration(
                              color: active ? AppColors.primaryLight : const Color(0xFFCBD5E1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
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
                              hintStyle: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondaryTextLight),
                            ),
                            style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primaryTextLight),
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1, // tambah tombol "Lihat"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isSeeButton = index == _categories.length;
          if (isSeeButton) {
            return InkWell(
              onTap: () => setState(() => _currentTabIndex = 2),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text('Lihat', style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ],
                ),
              ),
            );
          }

          final label = _categories[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(label, style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTextLight)),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: showSeeAll ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight, height: 1.0),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: () {},
              child: Text('Lihat Semua', style: GoogleFonts.lexendDeca(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductDetailPage(
                  product: p,
                  getQty: _getQty,
                  onAdd: _increment,
                  onIncrement: _increment,
                  onDecrement: _decrement,
                  related: _allProducts.where((e) => e != p).toList(),
                ),
              ));
            },
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    final List<_MiniCategory> items = const [
      _MiniCategory('Bahan Pokok', Icons.rice_bowl, Colors.blueGrey),
      _MiniCategory('Susu', Icons.local_drink, Colors.orange),
      _MiniCategory('Makanan Instan', Icons.fastfood, Colors.teal),
      _MiniCategory('Buah & Sayuran', Icons.eco, Colors.green),
      _MiniCategory('Roti', Icons.bakery_dining, Colors.brown),
      _MiniCategory('Air Mineral', Icons.water_drop, Colors.lightBlue),
      _MiniCategory('Deterjen', Icons.cleaning_services, Colors.indigo),
      _MiniCategory('Tisu', Icons.layers, Colors.deepPurple),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(height: 4),
              Text(item.label, textAlign: TextAlign.center, style: GoogleFonts.lexendDeca(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        height: effectiveHeight,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  final items = _allProducts.where((p) => _getQty(p) > 0).toList();
                  if (items.isEmpty) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CartConfirmPage(
                      items: items,
                      getQty: _getQty,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                    ),
                  ));
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
                    _buildMartNavItem(icon: LucideIcons.compass, label: 'Explor', index: 0),
                    _buildMartNavItem(icon: LucideIcons.search, label: 'Pencarian', index: 1),
                    _buildMartNavItem(icon: Icons.grid_view, label: 'Kategori', index: 2),
                    _buildMartNavItem(icon: LucideIcons.shoppingBag, label: 'Belanjaan', index: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMartNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _currentTabIndex == index;
    final Color color = isSelected ? AppColors.primaryLight : AppColors.secondaryTextLight;
    final media = MediaQuery.of(context);
    final bool isSmallHeight = media.size.height < 700;
    final double fontSize = isSmallHeight ? 10.0 : 11.0;
    final double iconSize = isSmallHeight ? 22.0 : 24.0;
    final double indicatorHeight = isSmallHeight ? 2.0 : 3.0;
    final double indicatorWidth = isSelected ? (isSmallHeight ? 20.0 : 24.0) : 0.0;
    final double gap1 = isSmallHeight ? 4.0 : 6.0;
    final double gap2 = isSmallHeight ? 3.0 : 4.0;

    return InkWell(
      onTap: () {
        if (index == 1) {
          _openSearchPage();
          return;
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BelanjaanPage()),
          );
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
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.lexendDeca(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.primaryTextLight : AppColors.secondaryTextLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final Color borderColor = const Color(0xFFDDE5ED);
    final Color statusColor = o['statusColor'] as Color? ?? AppColors.primaryLight;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
                        style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o['datetime'] as String,
                        style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.secondaryTextLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    o['status'] as String,
                    style: GoogleFonts.lexendDeca(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              o['summary'] as String,
              style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryTextLight),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${o['items']} item | ${o['total']}',
                    style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Mau lagi',
                      style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
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
  final List<String> images;
  final PageController pageController;
  final int pageIndex;
  final VoidCallback onBack;
  final VoidCallback onCart;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;

  _MartHeaderDelegate({
    required this.images,
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsed = t > 0.8;
    return Container(
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!collapsed)
            Positioned.fill(
              child: PageView.builder(
                controller: pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final path = images[index];
                  return Image.asset(path, fit: BoxFit.cover);
                },
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
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.x, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Inspire Mart',
                          style: GoogleFonts.lexendDeca(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      InkWell(
                        onTap: onCart,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.shoppingCart, color: Color(0xFF0F172A)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
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
                                    decoration: InputDecoration.collapsed(
                                      hintText: 'Restock sugar',
                                      hintStyle: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondaryTextLight),
                                    ),
                                    style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primaryTextLight),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(images.length, (i) {
                      final bool active = i == pageIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primaryLight : const Color(0xFFCBD5E1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
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
                              decoration: const InputDecoration.collapsed(hintText: 'Restock sugar'),
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
    return oldDelegate.pageIndex != pageIndex || oldDelegate.images != images;
  }
}

class _MiniCategory {
  final String label;
  final IconData icon;
  final Color color;
  const _MiniCategory(this.label, this.icon, this.color);
}

// Halaman Pencarian telah dipisahkan ke file: lib/feature/belanja/screens/mart_search_page.dart