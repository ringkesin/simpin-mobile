import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kkba_mobile/theme.dart';

class BelanjaanPage extends StatefulWidget {
  const BelanjaanPage({super.key});

  @override
  State<BelanjaanPage> createState() => _BelanjaanPageState();
}

class _BelanjaanPageState extends State<BelanjaanPage> {
  int _tabIndex = 0; // 0: Dalam proses, 1: Riwayat

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
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
              alignment: Alignment.center,
              child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: Text(
          'Belanjaan',
          style: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextLight,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
        scrolledUnderElevation: 0.5,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabs(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ...(_tabIndex == 0 ? _ordersInProcess : _ordersHistory)
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOrderCard(o),
                        ))
                    .toList(),
                const SizedBox(height: 16),
                Text(
                  _tabIndex == 1 ? 'Memuat riwayat ...' : 'Memuat dalam proses ...',
                  style: GoogleFonts.lexendDeca(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.secondaryTextLight),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE5ED)),
      ),
      child: Row(
        children: [
          _tabButton('Dalam proses', 0),
          _tabButton('Riwayat', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final bool selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
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