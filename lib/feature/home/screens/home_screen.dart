// feature/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl jika belum ada
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart'; // Asumsi path benar
import 'package:kkba_mobile/theme.dart'; // Asumsi path benar

// --- Import yang Diperlukan ---
import '../../../service/api_service.dart'; // Import ApiService
import '../../../model/tabungan_tahunan_response.dart'; // Import model tahunan
import '../widgets/home_widget.dart'; // Import BannerWidget, CategoriesWidget, dll.
// ----------------------------

class HomeScreen extends StatefulWidget {
  // Hapus const jika initState/state ada
  // const HomeScreen({super.key}); // <-- Hapus const jika stateful

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- State untuk Nama User ---
  String _userName = 'Loading...';

  // --- State untuk Banner Data ---
  final ApiService _apiService = ApiService(); // Instance ApiService
  bool _isLoadingBanner = true;
  String? _bannerError;
  TabunganTahunanResponse? _tahunanResponse;
  bool _isBalanceVisible = true; // Default saldo terlihat
  // ---------------------------

  @override
  void initState() {
    super.initState();
    // Panggil kedua fungsi fetch saat init
    _loadUserName();
    _fetchBannerData();
  }

  // Fungsi load username (tetap sama)
  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('nama');
    if (mounted) {
      // Cek mounted
      setState(() {
        _userName = name ?? 'User'; // Beri default 'User' jika null
      });
    }
  }

  // --- Fungsi BARU untuk fetch data banner ---
  Future<void> _fetchBannerData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanner = true;
      _bannerError = null;
    });
    try {
      final tahun = '2024';
      // Ambil pAnggotaId jika diperlukan oleh API Anda, jika tidak, bisa null
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final pAnggotaId = prefs.getInt('p_anggota_id');

      final result = await _apiService.getTabunganTahunan(
        tahun: tahun,
        pAnggotaId: pAnggotaId, // Kirim jika perlu
      );

      if (mounted) {
        // Cek lagi setelah await
        setState(() {
          if (result.success) {
            _tahunanResponse = result;
            _bannerError = null;
          } else {
            _tahunanResponse = null;
            _bannerError = result.message ?? "Gagal mengambil data saldo.";
          }
          _isLoadingBanner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerError = e.toString().replaceFirst("Exception: ", "");
          _isLoadingBanner = false;
          _tahunanResponse = null;
        });
      }
    }
  }
  // --- Akhir fungsi fetch data banner ---

  // --- Fungsi untuk toggle visibilitas saldo ---
  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }
  // --- Akhir fungsi toggle ---

  @override
  Widget build(BuildContext context) {
    // Ambil theme jika perlu styling spesifik di sini
    // final theme = Theme.of(context);
    // final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white, // Background utama putih
      body: RefreshIndicator(
        // Tambahkan RefreshIndicator
        onRefresh: () async {
          // Panggil kedua fetch saat refresh
          await _loadUserName();
          await _fetchBannerData();
        },
        color: AppColors.primaryLight, // Warna indikator refresh
        child: CustomScrollView(
          slivers: [
            // --- Header dengan background hijau ---
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.alternateLight, // Warna hijau header
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                ),
                child: SafeArea(
                  bottom: false, // Tidak perlu padding bawah SafeArea di sini
                  child: Column(
                    children: [
                      // --- Baris Welcome & Avatar ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ), // Sesuaikan padding
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundImage: AssetImage(
                                'assets/images/profile.jpg',
                              ), // Pastikan path benar
                              radius: 20, // Sedikit lebih besar?
                            ),
                            const SizedBox(width: 12),
                            // Gunakan Expanded agar teks tidak overflow jika nama panjang
                            Expanded(
                              child: Text(
                                'Welcome, $_userName', // Nama dari state
                                style: AppTheme.textThemeLight.titleMedium
                                    ?.copyWith(
                                      // Gunakan style dari theme
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow:
                                    TextOverflow
                                        .ellipsis, // Handle nama panjang
                              ),
                            ),
                            // Tambahkan ikon notifikasi atau lainnya jika perlu
                            // IconButton(onPressed: (){}, icon: Icon(Icons.notifications_none, color: Colors.white))
                          ],
                        ),
                      ),
                      // --- BannerWidget dengan data dinamis ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          0,
                          16.0,
                          20.0,
                        ), // Padding banner
                        child: BannerWidget(
                          isLoading: _isLoadingBanner, // Dari state
                          error: _bannerError, // Dari state
                          totalSaldo:
                              _tahunanResponse
                                  ?.data
                                  ?.totalSaldoSd, // Dari state API response
                          isBalanceVisible: _isBalanceVisible, // Dari state
                          onToggleVisibility:
                              _toggleBalanceVisibility, // Kirim callback
                          // points: ... // Kirim points jika dinamis
                        ),
                      ),
                      // --- Akhir BannerWidget ---
                    ],
                  ),
                ),
              ),
            ),
            // --- Akhir Header ---

            // --- Content Area (Categories & Transactions) ---
            SliverToBoxAdapter(
              child: PageWrapper(
                // Pastikan PageWrapper memberi padding yang benar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24), // Jarak dari header ke kategori
                    Text(
                      'Menu Utama', // Ganti judul?
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), // Lebih besar?
                    ),
                    const SizedBox(height: 16),
                    CategoriesWidget(), // Widget kategori Anda
                    const SizedBox(height: 24), // Jarak ke transaksi
                    RecentTransactionsWidget(), // Widget transaksi Anda
                    const SizedBox(height: 20), // Jarak di bagian bawah
                  ],
                ),
              ),
            ),
            // --- Akhir Content Area ---
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigationBarWidget(), // Aktifkan jika perlu
    );
  }
}
