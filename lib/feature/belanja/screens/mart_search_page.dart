import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';
import '../components/product_card.dart';
import 'product_detail_page.dart';

class MartSearchPage extends StatefulWidget {
  final List<String> history;
  final List<Product> products;
  final int Function(Product) getQty;
  final void Function(Product) onAdd;
  final void Function(Product) onInc;
  final void Function(Product) onDec;
  final void Function(String) onSearched;

  const MartSearchPage({
    super.key,
    required this.history,
    required this.products,
    required this.getQty,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
    required this.onSearched,
  });

  @override
  State<MartSearchPage> createState() => _MartSearchPageState();
}

class _MartSearchPageState extends State<MartSearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  List<Product> get _filtered {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  void _doSearch(String q) {
    setState(() => _query = q);
    widget.onSearched(q);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                          ),
                          child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pencarian',
                        style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primaryTextLight),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Mau belanja apa hari ini ?',
                              hintStyle: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondaryTextLight),
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
                    Text('Pernah kamu cari', style: GoogleFonts.lexendDeca(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight)),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.history.take(8).map((h) {
                        return InkWell(
                          onTap: () {
                            _controller.text = h;
                            _controller.selection = TextSelection.collapsed(offset: h.length);
                            _doSearch(h);
                          },
                          borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.clock, size: 14, color: AppColors.primaryTextLight.withOpacity(0.9)),
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
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _query.trim().isEmpty ? 'Hasil pencarian' : 'Hasil pencarian “${_query}”',
                      style: GoogleFonts.lexendDeca(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryTextLight),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: (_query.trim().isEmpty ? widget.products.length : _filtered.length),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final list = _query.trim().isEmpty ? widget.products : _filtered;
                        final p = list[index];
                        return ProductCard(
                          product: p,
                          quantity: widget.getQty(p),
                          onAdd: () => widget.onAdd(p),
                          onIncrement: () => widget.onInc(p),
                          onDecrement: () => widget.onDec(p),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                product: p,
                                getQty: widget.getQty,
                                onAdd: widget.onAdd,
                                onIncrement: widget.onInc,
                                onDecrement: widget.onDec,
                                related: (list.where((e) => e != p).toList()),
                              ),
                            ));
                          },
                        );
                      },
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
      final Color color = isSelected ? AppColors.primaryLight : AppColors.secondaryTextLight;
      final double indicatorWidth = isSelected ? (isSmallHeight ? 20.0 : 24.0) : 0.0;
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
              Text(label, style: GoogleFonts.lexendDeca(fontSize: fontSize, fontWeight: FontWeight.w700, color: color)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
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