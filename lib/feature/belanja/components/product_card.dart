import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onTap;
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = product.discountPercent > 0;
    final int oldPrice = originalPrice(product.price, product.discountPercent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        child:
                            product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Center(
                                            child: Icon(
                                              LucideIcons.image,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                )
                                : const Center(
                                  child: Icon(
                                    LucideIcons.image,
                                    color: Color(0xFF9CA3AF),
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
                    if (quantity <= 0)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: Container(
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
                                  child: Icon(
                                    Icons.remove,
                                    color: Color(0xFF22C55E),
                                  ),
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
                                  child: Icon(
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRp(product.price),
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextLight,
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
