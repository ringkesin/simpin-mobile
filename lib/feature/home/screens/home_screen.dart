// feature/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart'; // Asumsi path benar
import 'package:kkba_mobile/theme.dart'; // Asumsi path benar
import 'package:qr_flutter/qr_flutter.dart'; // <-- Import library QR

// --- Import Baru & Diperlukan ---
import '../../../service/api_service.dart'; // Import ApiService
import 'package:kkba_mobile/model/berita.dart'; // Import model BeritaItem
import '../widgets/home_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Service ---
  final ApiService _apiService = ApiService(); // Instance ApiService

  // --- State untuk Data Pengguna ---
  String? _userName;
  String? _nomorAnggota;

  // --- State untuk Loading & Error Banner ---
  bool _isLoadingBanner = true;
  String? _bannerError;

  // --- State untuk Berita ---
  List<BeritaItem> _beritaList = [];
  bool _isLoadingBerita = true;
  String? _beritaError;
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Memuat data user dan berita
  }

  // Fungsi gabungan untuk load data awal (User & Berita)
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanner = true;
      _isLoadingBerita = true; // Set loading berita juga
      _bannerError = null;
      _beritaError = null; // Reset error berita
      _userName = null;
      _nomorAnggota = null;
      _beritaList = []; // Kosongkan list berita
    });

    try {
      // Jalankan fetch user data dan berita secara paralel
      await Future.wait([
        _loadUserData(),
        _fetchBeritaList(), // Panggil fetch berita
      ]);
      // Loading state spesifik dihandle di dalam fungsi fetch masing-masing
    } catch (e) {
      print("Error during initial load: $e");
      if (mounted) {
        setState(() {
          // Set error umum jika perlu, atau biarkan error spesifik
          _bannerError = _bannerError ?? "Gagal memuat data awal.";
          _beritaError = _beritaError ?? "Gagal memuat berita awal.";
          // Pastikan semua loading berhenti jika ada error fatal
          _isLoadingBanner = false;
          _isLoadingBerita = false;
        });
      }
    }
  }

  // Fungsi load data user (username & nomor anggota)
  Future<void> _loadUserData() async {
    try {
      // Memuat data user
      await Future.wait([_loadUserName(), _loadNomorAnggota()]);
      if (mounted) {
        setState(() {
          _isLoadingBanner = false; // Loading banner selesai
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() {
          _bannerError = "Gagal memuat data pengguna.";
          _isLoadingBanner = false;
        });
      }
      throw Exception("Gagal memuat data pengguna: $e"); // Re-throw
    }
  }

  // Fungsi load username
  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('nama'); // PASTIKAN KEY BENAR
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  // Fungsi load nomor anggota
  Future<void> _loadNomorAnggota() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // GANTI 'nomor_anggota' dengan key yang benar
    final String? nomorFromPrefs = prefs.getString('nomor_anggota');
    if (mounted) {
      setState(() {
        _nomorAnggota = nomorFromPrefs;
      });
    }
  }

  // Fungsi Fetch Berita
  Future<void> _fetchBeritaList() async {
    // Tidak perlu setState loading di sini jika sudah di _loadInitialData
    try {
      final response = await _apiService.getListBerita();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _beritaList = response.data!.content;
          _beritaError = null;
        });
      } else {
        setState(() {
          _beritaList = [];
          _beritaError = response.message;
        });
      }
    } catch (e) {
      print("Error fetching berita list: $e");
      if (!mounted) return;
      setState(() {
        _beritaList = [];
        _beritaError = e.toString().replaceFirst("Exception: ", "");
      });
      throw Exception("Gagal memuat berita: $e"); // Re-throw
    } finally {
      if (mounted) {
        setState(() => _isLoadingBerita = false); // Akhiri loading berita
      }
    }
  }

  // Fungsi handle Generate QR (Tetap sama)
  void _handleGenerateQr() {
    if (_nomorAnggota != null && _nomorAnggota!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Scan Nomor Anggota Anda'),
            content: SizedBox(
              width: 250,
              height: 250,
              child: Center(
                child: QrImageView(
                  data: _nomorAnggota!,
                  version: QrVersions.auto,
                  size: 230.0,
                  gapless: false,
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Tutup'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor Anggota tidak tersedia untuk generate QR Code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Atau Theme.of(context).colorScheme.background
      body: RefreshIndicator(
        onRefresh: _loadInitialData, // Refresh semua data
        color: AppColors.primaryLight,
        child: CustomScrollView(
          slivers: [
            // --- Header ---
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.alternateLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // --- Baris Welcome & Avatar ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
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
                      // --- BannerWidget ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
                        child: BannerWidget(
                          isLoading: _isLoadingBanner,
                          error: _bannerError,
                          username: _userName,
                          nomorAnggota: _nomorAnggota,
                          onGenerateQr: _handleGenerateQr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- Akhir Header ---

            // --- Content Area ---
            SliverToBoxAdapter(
              child: PageWrapper(
                // Atau Padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Menu Utama',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CategoriesWidget(), // Widget Kategori
                    const SizedBox(height: 24),

                    // --- GANTI RecentTransactionsWidget DENGAN _buildBeritaSection ---
                    _buildBeritaSection(), // Memanggil helper untuk menampilkan berita
                    // ---------------------------------------------------------------
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // --- Akhir Content Area ---
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Menampilkan Berita (Loading/Error/List)
  Widget _buildBeritaSection() {
    if (_isLoadingBerita) {
      // Tampilkan indikator loading
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_beritaError != null) {
      // Tampilkan pesan error
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, color: Colors.grey[400], size: 40),
              const SizedBox(height: 16),
              Text(
                "Gagal memuat berita: $_beritaError",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              // Opsional: Tombol coba lagi
              // TextButton.icon(
              //    icon: Icon(Icons.refresh, size: 18),
              //    label: Text("Coba Lagi"),
              //    onPressed: _fetchBeritaList,
              // )
            ],
          ),
        ),
      );
    } else {
      // Tampilkan list berita menggunakan BeritaListWidget
      // Penanganan jika _beritaList kosong ada di dalam BeritaListWidget
      return BeritaListWidget(beritaList: _beritaList);
    }
  }
}
