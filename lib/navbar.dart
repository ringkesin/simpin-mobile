import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/profile/screens/profile.dart';
import 'package:kkba_mobile/feature/shu/screens/shu.dart';
import 'package:kkba_mobile/feature/ticket/screens/ticket_list.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

import 'feature/home/screens/home_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ShuPage(),
    TicketListPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color color =
        isSelected ? AppColors.primaryLight : AppColors.secondaryTextLight;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                // if (label == 'Inbox')
                //   Positioned(
                //     top: -2,
                //     right: 1,
                //     child: Container(
                //       width: 12,
                //       height: 12,
                //       decoration: BoxDecoration(
                //         color: AppColors.errorLight,
                //         shape: BoxShape.circle,
                //         border: Border.all(color: Colors.white, width: 1.5),
                //       ),
                //     ),
                //   ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.textThemeLight.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // GANTI KESELURUHAN BAGIAN bottomNavigationBar DENGAN INI
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          // DIUBAH: Menambahkan sudut melengkung hanya di atas
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          // DIUBAH: Mengganti border dengan boxShadow agar lebih halus
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2), // Shadow hanya ke arah atas
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: LucideIcons.home, label: 'Home', index: 0),
              _buildNavItem(icon: LucideIcons.wallet, label: 'SHU', index: 1),
              _buildNavItem(icon: LucideIcons.bell, label: 'Inbox', index: 2),
              _buildNavItem(icon: LucideIcons.user, label: 'Profil', index: 3),
            ],
          ),
        ),
      ),
    );
  }
}
