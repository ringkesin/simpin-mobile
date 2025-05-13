// feature/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart'; // Asumsi path benar
import 'package:kkba_mobile/theme.dart'; // Asumsi path benar
import 'package:qr_flutter/qr_flutter.dart';

import '../../../service/api_service.dart';
import 'package:kkba_mobile/model/berita.dart';
import '../widgets/home_widget.dart'; // Pastikan BannerWidget ada di sini atau diimport terpisah

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String? _userName;
  String? _nomorAnggota;

  // --- State Loading & Error yang Dimodifikasi ---
  bool _isLoadingBanner = true; // Untuk loading keseluruhan data banner
  String? _userNameError; // Error spesifik untuk username
  String? _nomorAnggotaError; // Error spesifik untuk nomor anggota

  List<BeritaItem> _beritaList = [];
  bool _isLoadingBerita = true;
  String? _beritaError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanner = true;
      _isLoadingBerita = true;
      _userNameError = null; // Reset error spesifik
      _nomorAnggotaError = null; // Reset error spesifik
      _beritaError = null;
      _userName = null;
      _nomorAnggota = null;
      _beritaList = [];
    });

    try {
      // Jalankan fetch user data dan berita secara paralel
      // _loadUserData akan menangani _userName, _nomorAnggota, _userNameError, _nomorAnggotaError
      // _fetchBeritaList akan menangani _beritaList, _beritaError
      await Future.wait([_loadUserData(), _fetchBeritaList()]);
    } catch (e) {
      // Catch ini untuk error yang tidak terduga/tidak ditangani oleh fungsi di atas
      print("Critical error during initial load: $e");
      if (mounted) {
        setState(() {
          _userNameError = _userNameError ?? "Gagal memuat data pengguna.";
          _nomorAnggotaError =
              _nomorAnggotaError ?? "Gagal memuat data pengguna.";
          _beritaError = _beritaError ?? "Gagal memuat berita awal.";
        });
      }
    } finally {
      // Pastikan semua state loading utama diatur ke false di sini
      if (mounted) {
        setState(() {
          _isLoadingBanner = false;
          _isLoadingBerita = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    // _loadUserName dan _loadNomorAnggota akan memanggil setState
    // untuk data mereka dan error spesifik mereka masing-masing.
    await Future.wait([_loadUserName(), _loadNomorAnggota()]);
    // _isLoadingBanner akan diatur ke false di blok finally _loadInitialData
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('nama');
      if (!mounted) return;
      setState(() {
        _userName = name;
        if (name == null || name.isEmpty) {
          // Anda bisa memilih untuk menampilkan "Pengguna" di BannerWidget
          // atau menampilkan error spesifik di sini.
          // Untuk konsistensi, jika tidak ada nama, anggap saja "Pengguna".
          // _userNameError = "Nama pengguna tidak ditemukan.";
          _userNameError =
              null; // Jika null/empty dianggap bukan error, tapi state data
        } else {
          _userNameError = null;
        }
      });
    } catch (e) {
      print("Error loading username: $e");
      if (!mounted) return;
      setState(() {
        _userName = null;
        _userNameError = "Gagal memuat nama.";
      });
    }
  }

  Future<void> _loadNomorAnggota() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? nomorFromPrefs = prefs.getString('nomor_anggota');
      if (!mounted) return;
      setState(() {
        _nomorAnggota = nomorFromPrefs;
        if (nomorFromPrefs == null || nomorFromPrefs.isEmpty) {
          // Jika null/empty dianggap bukan error, tapi state data (misal "Tidak Tersedia")
          // yang akan ditangani BannerWidget
          _nomorAnggotaError = null;
          // Jika ingin ini jadi error:
          // _nomorAnggotaError = "No. anggota tidak ditemukan.";
        } else {
          _nomorAnggotaError = null;
        }
      });
    } catch (e) {
      print("Error loading nomor anggota: $e");
      if (!mounted) return;
      setState(() {
        _nomorAnggota = null;
        _nomorAnggotaError = "Gagal memuat no. anggota.";
      });
    }
  }

  Future<void> _fetchBeritaList() async {
    if (!mounted) return;
    // _isLoadingBerita sudah di-set true di _loadInitialData
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
          _beritaError = response.message ?? "Gagal mendapatkan data berita.";
        });
      }
    } catch (e) {
      print("Error fetching berita list: $e");
      if (!mounted) return;
      setState(() {
        _beritaList = [];
        _beritaError = e.toString().replaceFirst("Exception: ", "");
      });
    }
    // _isLoadingBerita akan di-set false di blok finally _loadInitialData
  }

  void _handleGenerateQr() {
    if (_nomorAnggota != null &&
        _nomorAnggota!.isNotEmpty &&
        _nomorAnggotaError == null) {
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
      String message = 'Nomor Anggota tidak tersedia untuk generate QR Code.';
      if (_nomorAnggotaError != null) {
        message = "Tidak bisa generate QR: $_nomorAnggotaError";
      } else if (_nomorAnggota == null || _nomorAnggota!.isEmpty) {
        message = "Nomor Anggota kosong atau tidak valid.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: AppColors.primaryLight,
        child: CustomScrollView(
          slivers: [
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
                              ),
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                // Menampilkan nama dari state, atau "Guest" jika null/kosong dan tidak ada error nama
                                (_userNameError == null &&
                                        (_userName?.isNotEmpty ?? false))
                                    ? 'Welcome, $_userName'
                                    : (_userNameError != null
                                        ? 'Welcome, ...'
                                        : 'Welcome, Guest'),
                                style: AppTheme.textThemeLight.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
                        child: BannerWidget(
                          // Widget dari home_widget.dart
                          isLoading: _isLoadingBanner,
                          username: _userName,
                          nomorAnggota: _nomorAnggota,
                          usernameError: _userNameError, // Prop baru
                          nomorAnggotaError: _nomorAnggotaError, // Prop baru
                          onGenerateQr: _handleGenerateQr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PageWrapper(
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
                    CategoriesWidget(), // Widget dari home_widget.dart
                    const SizedBox(height: 24),
                    _buildBeritaSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeritaSection() {
    if (_isLoadingBerita) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_beritaError != null) {
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
            ],
          ),
        ),
      );
    } else {
      return BeritaListWidget(
        beritaList: _beritaList,
      ); // Widget dari home_widget.dart
    }
  }
}
