import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:kkba_mobile/core/utils/formatters.dart';
import '../service/mart_api_service.dart';
import '../service/cart_api_service.dart';
import '../models/product.dart';

class ProductByIdPage extends StatefulWidget {
  final String productId;
  const ProductByIdPage({super.key, required this.productId});

  @override
  State<ProductByIdPage> createState() => _ProductByIdPageState();
}

class _ProductByIdPageState extends State<ProductByIdPage> {
  final MartApiService _martApi = MartApiService();
  final CartApiService _cartApi = CartApiService();

  bool _loading = true;
  Product? _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = await _martApi.getProductById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = p;
      if (p == null) {
        _error = 'Produk tidak ditemukan atau gagal dimuat';
      }
      _loading = false;
    });
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    final ok = await _cartApi.addToCart(_product!.id, 1);
    final msg = ok
        ? 'Produk ditambahkan ke keranjang'
        : (_cartApi.lastErrorMessage ?? 'Gagal menambahkan ke keranjang');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_error!, style: GoogleFonts.lexendDeca()),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
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
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                                  ],
                                ),
                                child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 220,
                            child: Container(
                              color: Colors.white,
                              child: (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty)
                                  ? Image.network(_product!.imageUrl!, fit: BoxFit.contain)
                                  : const Center(child: Icon(LucideIcons.image, color: Color(0xFF9CA3AF), size: 64)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _product!.name,
                          style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          formatRp(_product!.price),
                          style: GoogleFonts.lexendDeca(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryTextLight),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
      ),
      bottomNavigationBar: _product == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tambah ke keranjang', style: GoogleFonts.lexendDeca(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
    );
  }
}
