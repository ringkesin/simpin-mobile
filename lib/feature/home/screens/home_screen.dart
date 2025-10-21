import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/berita/screens/semua_berita.dart';
import 'package:kkba_mobile/feature/pencairan/screens/history.dart';
import 'package:kkba_mobile/feature/tabungan/screens/penyertaan_tab_page.dart';
import 'package:kkba_mobile/feature/tagihan/screens/tagihan_screens.dart';
import 'package:kkba_mobile/feature/ticket/screens/ticket_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart';
import 'package:kkba_mobile/theme.dart';
// import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../service/api_service.dart';
import 'package:kkba_mobile/model/berita.dart';
import '../widgets/home_widget.dart'; // BannerWidget and BeritaListWidget are here
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
// --- Import Screens for Navigation ---
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/form_pinjaman/screens/form_pinjaman.dart';
import 'package:kkba_mobile/feature/list_pinjaman/screens/list_pinjaman.dart'; // Assuming this exists for "Riwayat Pinjaman"
// import 'package:kkba_mobile/feature/riwayat_tagihan/screens/riwayat_tagihan.dart'; // Create this screen
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart'; // For "Mutasi Tabungan" / "Info Tabungan"
import 'package:kkba_mobile/feature/pencairan/screens/pencairan.dart'; // For "Form Pencairan Tabungan"
import 'package:barcode_widget/barcode_widget.dart';

// --- BARU: Import halaman Penyertaan ---
import 'package:kkba_mobile/feature/tabungan/screens/penyertaan_list_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String? _userName;
  String? _nomorAnggota;
  String? _profilePhotoUrl;
  bool _isLoadingBanner = true;
  bool _isLoadingProfilePhoto = true;
  String? _userNameError;
  String? _nomorAnggotaError;
  String? _profilePhotoUrlError;
  List<BeritaItem> _beritaList = [];
  bool _isLoadingBerita = true;
  String? _beritaError;
  String? _userRole;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanner = true;
      _isLoadingProfilePhoto = true;
      _isLoadingBerita = true;
      _userNameError = null;
      _nomorAnggotaError = null;
      _profilePhotoUrlError = null;
      _beritaError = null;
      _userName = null;
      _nomorAnggota = null;
      _profilePhotoUrl = null;
      _beritaList = [];
    });

    try {
      await Future.wait([_loadUserData(), _fetchBeritaList()]);
    } catch (e) {
      print("Critical error during initial load: $e");
      if (mounted) {
        setState(() {
          _userNameError = _userNameError ?? "Gagal memuat data pengguna.";
          _nomorAnggotaError =
              _nomorAnggotaError ?? "Gagal memuat data pengguna.";
          _profilePhotoUrlError =
              _profilePhotoUrlError ?? "Gagal memuat foto profil.";
          _beritaError = _beritaError ?? "Gagal memuat berita awal.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBanner = false;
          _isLoadingBerita = false;
          _isLoadingProfilePhoto = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadUserName(),
      _loadNomorAnggota(),
      _loadProfilePhotoUrl(),
      _loadUserRole(),
    ]);
  }

  Future<void> _loadUserRole() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userRole = prefs.getString('role');
        print("User role loaded: $_userRole");
      });
    } catch (e) {
      print("Error loading user role: $e");
    }
  }

  Future<void> _loadProfilePhotoUrl() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? url = prefs.getString('profile_photo_url');
      // DEBUG PRINT 1: Lihat nilai mentah yang didapat dari SharedPreferences
      print("--- [DEBUG FOTO PROFIL] 1. URL dari SharedPreferences: '$url'");

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = url;
        // Tidak set error jika URL kosong, biarkan fallback ke ikon
        _profilePhotoUrlError = null;
      });
    } catch (e) {
      print("Error loading profile photo URL: $e");
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = null;
        _profilePhotoUrlError = "Gagal memuat URL foto profil.";
      });
    }
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('nama');
      if (!mounted) return;
      setState(() {
        _userName = name;
        _userNameError = (name == null || name.isEmpty) ? null : null;
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
        _nomorAnggotaError =
            (nomorFromPrefs == null || nomorFromPrefs.isEmpty) ? null : null;
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
  }

  Future<void> _logoutUser() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // PENERAPAN THEME
          title: Text(
            'Konfirmasi Logout',
            style: AppTheme.textThemeLight.titleMedium,
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: AppTheme.textThemeLight.bodyMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                // PENERAPAN THEME
                style: AppTheme.textThemeLight.labelLarge?.copyWith(
                  color: AppColors.secondaryTextLight,
                  fontWeight: FontWeight.w500, // Dibuat tidak tebal
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Logout',
                // PENERAPAN THEME
                style: AppTheme.textThemeLight.labelLarge?.copyWith(
                  color: AppColors.errorLight,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('nama');
      await prefs.remove('nomor_anggota');
      await prefs.remove('profile_photo_url');
      // await prefs.clear(); // Alternatif jika ingin menghapus semua

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _handleGenerateBarcode() {
    if (_nomorAnggota != null &&
        _nomorAnggota!.isNotEmpty &&
        _nomorAnggotaError == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Scan Barcode Anggota Anda'),
            // DIUBAH: Ukuran content disesuaikan untuk barcode
            content: SizedBox(
              width: 300,
              height:
                  150, // Dibuat lebih pendek karena barcode berbentuk persegi panjang
              child: Center(
                // DIUBAH: Menggunakan BarcodeWidget
                child: BarcodeWidget(
                  barcode:
                      Barcode.code128(), // Jenis barcode, Code128 sangat umum
                  data: _nomorAnggota!, // Data yang akan di-encode
                  width: 280,
                  height: 100,
                  drawText: true, // Menampilkan teks data di bawah barcode
                  style: const TextStyle(
                    letterSpacing: 2.0,
                  ), // Atur jarak huruf jika perlu
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
      String message = 'Nomor Anggota tidak tersedia untuk generate Barcode.';
      if (_nomorAnggotaError != null) {
        message = "Tidak bisa generate Barcode: $_nomorAnggotaError";
      } else if (_nomorAnggota == null || _nomorAnggota!.isEmpty) {
        message = "Nomor Anggota kosong atau tidak valid.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // GANTI FUNGSI LAMA DENGAN YANG INI
  // Di dalam file home_screen.dart

  Widget _buildMenuItem({
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    IconData? icon, // DIUBAH: Menjadi opsional
    String? svgPath, // BARU: Parameter untuk path SVG
    Gradient? iconBackgroundGradient,
    Color iconColor = Colors.white,
    double iconSize = 30.0,
    double backgroundIconSize = 64.0,
    double spacing = 8.0,
  }) {
    // Memastikan salah satu dari icon atau svgPath harus diisi
    assert(
      icon != null || svgPath != null,
      'Either an icon or an svgPath must be provided.',
    );
    final textTheme = AppTheme.textThemeLight;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: backgroundIconSize,
                height: backgroundIconSize,
                decoration: BoxDecoration(
                  gradient: iconBackgroundGradient,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (iconBackgroundGradient as LinearGradient?)
                              ?.colors
                              .first
                              .withOpacity(0.3) ??
                          Colors.grey.withOpacity(0.3),
                      blurRadius: 7,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                // DIUBAH: Logika untuk menampilkan SVG atau Ikon Font
                child:
                    svgPath != null
                        // **** PERBAIKAN UTAMA DI SINI ****
                        // Bungkus SvgPicture dengan Padding untuk mengontrol ukurannya
                        ? Padding(
                          padding: const EdgeInsets.all(
                            20.0,
                          ), // Beri padding di sekeliling SVG
                          child: SvgPicture.asset(
                            svgPath,
                            // width dan height di sini menjadi kurang relevan karena ukuran diatur oleh Padding
                            colorFilter: ColorFilter.mode(
                              iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                        : Icon(
                          // Jika tidak, gunakan Icon seperti biasa
                          icon,
                          size: iconSize,
                          color: iconColor,
                        ),
              ),
              SizedBox(height: spacing),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryTextLight,
                  height: 1.2,
                  fontSize:
                      11.5, // Anda masih bisa override ukuran font jika diperlukan
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPlaceholder(String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasi ke $pageName (Belum diimplementasi)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Ganti fungsi _buildPinjamanMenu yang lama dengan yang ini

  Widget _buildPinjamanMenu(BuildContext context) {
    // DIUBAH: Mendefinisikan Gradient menggunakan Hex Code
    final Gradient simulasiGradient = const LinearGradient(
      colors: [
        Color(0xFFF0FDF4),
        Color(0xFFDCFCE7),
      ], // Contoh: Light Orange -> Deeper Orange
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final Gradient pengajuanGradient = const LinearGradient(
      colors: [
        Color(0xFFEEF2FF),
        Color(0xFFE0E7FF),
      ], // Contoh: Light Blue -> Indigo
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final Gradient riwayatPinjamanGradient = const LinearGradient(
      colors: [
        Color(0xFFFAF5FF),
        Color(0xFFF3E8FF),
      ], // Contoh: Light Purple -> Deeper Purple
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final Gradient riwayatTagihanGradient = const LinearGradient(
      colors: [
        Color(0xFFFEF3C7),
        Color(0xFFFFFBEB),
      ], // Contoh: Light Purple -> Deeper Purple
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    const Color defaultIconColor = const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Pinjaman',
            style: AppTheme.textThemeLight.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextLight, // Pastikan warna sesuai tema
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: LucideIcons.sheet,
              label: "Simulasi",
              context: context,
              iconBackgroundGradient: simulasiGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SimulasiPinjamanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              svgPath: 'assets/icons/clipboard-pen.svg',
              label: "Form Pengajuan",
              context: context,
              iconBackgroundGradient: pengajuanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FormWizardScreen()),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              icon: LucideIcons.clipboardList,
              label: "Riwayat Pinjaman",
              context: context,
              iconBackgroundGradient: riwayatPinjamanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarPinjamanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              icon: LucideIcons.scrollText,
              label: "Riwayat Tagihan",
              context: context,
              iconBackgroundGradient: riwayatTagihanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TagihanScreen()),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  // BARU: Widget untuk membangun menu khusus admin
  Widget _buildAdminMenu(BuildContext context) {
    final Gradient riwayatGradient = const LinearGradient(
      colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Gradient inboxGradient = const LinearGradient(
      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const Color defaultIconColor = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Menu Admin', // Judul untuk menu admin
            style: AppTheme.textThemeLight.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextLight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: LucideIcons.scrollText,
              label: "Riwayat Pinjaman",
              context: context,
              iconBackgroundGradient: riwayatGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarPinjamanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              icon: LucideIcons.inbox,
              label: "Inbox Chat",
              context: context,
              iconBackgroundGradient: inboxGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketListPage()),
                  ),
            ),
            // Sisa 2 kolom kita beri Expanded kosong agar alignment rapi
            Expanded(child: Container()),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  // --- WIDGET YANG DIMODIFIKASI ---
  Widget _buildTabunganMenu(BuildContext context) {
    final Gradient mutasiGradient = const LinearGradient(
      colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final Gradient pencairanGradient = const LinearGradient(
      colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    final Gradient riwayatPencairanGradient = const LinearGradient(
      colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    // BARU: Gradient untuk menu Penyertaan
    final Gradient penyertaanGradient = const LinearGradient(
      colors: [
        Color(0xFFF5F3FF), // Light Violet
        Color(0xFFEDE9FE), // Deeper Violet
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    const Color defaultIconColor = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Tabungan',
            style: AppTheme.textThemeLight.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextLight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: LucideIcons.arrowRightLeft,
              label: "Mutasi Tabungan",
              context: context,
              iconBackgroundGradient: mutasiGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TabunganPage()),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              svgPath: 'assets/icons/banknote-arrow-down.svg',
              label: "Form Pencairan",
              context: context,
              iconBackgroundGradient: pencairanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PencairanTabunganScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            _buildMenuItem(
              svgPath: 'assets/icons/hand-coins.svg',
              label: "Riwayat Pencairan",
              context: context,
              iconBackgroundGradient: riwayatPencairanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryPengajuanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16), // Jarak antar item
            // --- MENU BARU DITAMBAHKAN DI SINI ---
            _buildMenuItem(
              icon: LucideIcons.coins, // Gunakan SVG icon yang sesuai
              label: "Penyertaan",
              context: context,
              iconBackgroundGradient: penyertaanGradient,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PenyertaanTabPage(),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeritaSectionTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0), // Padding judul section
          child: Text(
            'Berita Terbaru',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SemuaBeritaScreen(),
              ),
            );
          },
          child: Text(
            'Lihat Semua',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Tinggi perkiraan BannerWidget (harus konsisten dengan yang di BannerWidget)
    final double bannerHeight = screenWidth * 0.35; //
    // Seberapa banyak banner akan "turun" dari header
    final double bannerOverlap =
        bannerHeight / 2.2; // Sekitar sepertiga tinggi banner

    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: AppColors.primaryLight,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                // Tinggi total area header termasuk bagian yang tertutup overlap banner
                height:
                    (screenWidth * 0.3) +
                    (bannerHeight - bannerOverlap) +
                    MediaQuery.of(context)
                        .padding
                        .top, // Perkiraan tinggi header + bagian banner yg terlihat
                child: Stack(
                  children: [
                    // Lapisan 1: Background Gradasi Header
                    Positioned.fill(
                      bottom:
                          bannerOverlap, // Gradasi berhenti sebelum banner sepenuhnya "turun"
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF), // Atas: Putih
                              Color(0xFFE2E8F0), // Bawah: #E2E8F0
                            ],
                            begin:
                                Alignment
                                    .topCenter, // Gradasi dari atas ke bawah
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          ),
                        ),
                      ),
                    ),

                    // Lapisan 2: Konten Header (Logo, Profile, dll.)
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          // --- MODIFIKASI MARGIN HEADER ---
                          padding: const EdgeInsets.only(
                            left: 24.0, // Diubah dari 16.0 ke 24.0
                            right: 24.0, // Diubah dari 16.0 ke 24.0
                            top: 12.0,
                          ),
                          // --- END MODIFIKASI MARGIN HEADER ---
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween, // Mendorong item ke ujung
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // Membuat item sejajar di tengah sebagai dasar
                            children: [
                              // Item Kiri: Logo
                              Image.asset(
                                'assets/images/logokkba_header.png',
                                height: 34,
                              ),

                              // Item Kanan: Grup Ikon
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .center, // Sejajarkan item di grup ini
                                children: [
                                  // Foto Profil (tidak berubah)
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[200],
                                    child:
                                        _isLoadingProfilePhoto
                                            ? const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                              ),
                                            )
                                            : (_profilePhotoUrl != null &&
                                                _profilePhotoUrl!.isNotEmpty)
                                            ? ClipOval(
                                              child: Image.network(
                                                _profilePhotoUrl!,
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  ctx,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons.person_outline,
                                                    size: 22,
                                                    color: Colors.grey[600],
                                                  );
                                                },
                                              ),
                                            )
                                            : Icon(
                                              Icons.person_outline,
                                              size: 22,
                                              color: Colors.grey[600],
                                            ),
                                  ),
                                  const SizedBox(width: 8),

                                  // **** PERUBAHAN DI SINI ****
                                  // Ikon Logout dibungkus dengan Padding untuk diturunkan sedikit
                                  InkWell(
                                    onTap: _logoutUser,
                                    customBorder:
                                        const CircleBorder(), // Membuat efek ripple menjadi lingkaran
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        8.0,
                                      ), // Jarak antara ikon dan tepi lingkaran
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        shape:
                                            BoxShape
                                                .circle, // Membuat bentuknya menjadi lingkaran
                                      ),
                                      child: const Icon(
                                        Icons.logout_outlined,
                                        color:
                                            AppColors
                                                .errorLight, // Warna ikon logout
                                        size:
                                            20, // Ukuran ikon di dalam lingkaran
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Lapisan 3: BannerWidget yang overlap
                    Positioned(
                      // --- MODIFIKASI POSISI BANNERWIDGET ---
                      left: 24.0, // Diubah dari 16.0 ke 24.0
                      right: 24.0, // Diubah dari 16.0 ke 24.0
                      // --- END MODIFIKASI POSISI BANNERWIDGET ---
                      bottom: 0,
                      height: bannerHeight,
                      child: BannerWidget(
                        isLoading: _isLoadingBanner,
                        username: _userName,
                        nomorAnggota: _nomorAnggota,
                        usernameError: _userNameError,
                        nomorAnggotaError: _nomorAnggotaError,
                        onGenerateQr: _handleGenerateBarcode,
                        // onKeanggotaanTap: () {
                        //   _navigateToPlaceholder("Halaman Keanggotaan");
                        // },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Spacer untuk memberi ruang setelah banner yang overlap
            SliverToBoxAdapter(child: SizedBox(height: 24)),

            // SliverToBoxAdapter untuk menu dan berita
            SliverToBoxAdapter(
              child: Padding(
                // Diganti dari PageWrapper ke Padding biasa
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // **** PERUBAHAN UTAMA DI SINI ****
                    // Tampilkan menu berdasarkan role pengguna
                    _isLoadingBanner // Tampilkan loader jika data user belum siap
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 240.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                        : _userRole == 'mobile_admin'
                        ? _buildAdminMenu(context) // Tampilkan menu admin
                        : Column(
                          // Tampilkan menu biasa untuk non-admin
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPinjamanMenu(context),
                            const SizedBox(height: 18),
                            _buildTabunganMenu(context),
                          ],
                        ),

                    // **** AKHIR PERUBAHAN UTAMA ****
                    const SizedBox(height: 18),
                    _buildBeritaSectionTitle(context),
                    const SizedBox(height: 12),
                    _buildBeritaSectionContent(),
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

  Widget _buildBeritaSectionContent() {
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
        //
        beritaList: _beritaList,
      );
    }
  }
}
