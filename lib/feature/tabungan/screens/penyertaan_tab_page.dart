// lib/feature/penyertaan/screens/penyertaan_tab_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT BARU
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

  // --- TAMBAHAN BARU: Variabel untuk Role Checking ---
  bool _isAdmin = false;
  bool _isRoleLoading = true;
  // ---------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole(); // Panggil fungsi cek role saat inisialisasi
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- TAMBAHAN BARU: Fungsi untuk memuat peran pengguna ---
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Asumsi: Peran admin disimpan sebagai 'MOBILE_ADMIN'
    final role = prefs.getString('role');

    if (mounted) {
      setState(() {
        _isAdmin = role == 'mobile_admin';
        _isRoleLoading = false;
      });
    }
  }
  // --------------------------------------------------------

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

      // --- PERUBAHAN UTAMA DI SINI ---
      // Tombol hanya ditampilkan jika TIDAK Admin dan loading sudah selesai.
      floatingActionButton:
          _isRoleLoading
              ? null // Sembunyikan saat role masih dimuat
              : _isAdmin
              ? null // Sembunyikan jika role adalah Admin
              : FloatingActionButton(
                onPressed: _handleFabPress,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Buat Pengajuan Baru',
              ),
      // -------------------------------
    );
  }
}
