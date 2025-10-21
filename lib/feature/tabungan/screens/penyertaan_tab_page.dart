// lib/feature/penyertaan/screens/penyertaan_tab_page.dart

import 'package:flutter/material.dart';
import 'penyertaan_universal_form.dart';
import 'penyertaan_list_view.dart';
import 'perubahan_penyertaan_list_view.dart';
import 'package:kkba_mobile/theme.dart';

class PenyertaanTabPage extends StatefulWidget {
  const PenyertaanTabPage({Key? key}) : super(key: key);

  @override
  _PenyertaanTabPageState createState() => _PenyertaanTabPageState();
}

class _PenyertaanTabPageState extends State<PenyertaanTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<PenyertaanListViewState> _penyertaanListKey =
      GlobalKey<PenyertaanListViewState>();
  final GlobalKey<PerubahanPenyertaanListViewState> _perubahanListKey =
      GlobalKey<PerubahanPenyertaanListViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleFabPress() async {
    // Selalu navigasi ke form universal yang baru
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PenyertaanUniversalFormPage(),
      ),
    );

    // Setelah form ditutup, refresh kedua list untuk menampilkan data terbaru
    if (result == true) {
      _penyertaanListKey.currentState?.refreshData();
      _perubahanListKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Penyertaan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: AppColors.primaryBackgroundLight,
        elevation: 0,
        foregroundColor: AppColors.primaryTextLight,
        scrolledUnderElevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTheme.textThemeLight.labelLarge,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.secondaryTextLight,
          indicatorColor: AppColors.primaryLight,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Penyertaan Awal'), Tab(text: 'Perubahan')],
        ),
      ),
      backgroundColor: AppColors.secondaryBackgroundLight,
      body: TabBarView(
        controller: _tabController,
        children: [
          PenyertaanListView(key: _penyertaanListKey),
          PerubahanPenyertaanListView(key: _perubahanListKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPress,
        backgroundColor: AppColors.primaryLight,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Buat Pengajuan Baru',
      ),
    );
  }
}
