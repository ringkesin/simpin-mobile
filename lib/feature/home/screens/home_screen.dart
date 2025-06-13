// feature/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/pencairan/screens/history.dart';
import 'package:kkba_mobile/feature/tagihan/screens/tagihan_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart';
import 'package:kkba_mobile/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../service/api_service.dart';
import 'package:kkba_mobile/model/berita.dart';
import '../widgets/home_widget.dart'; // BannerWidget and BeritaListWidget are here

// --- Import Screens for Navigation ---
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/form_pinjaman/screens/form_pinjaman.dart';
import 'package:kkba_mobile/feature/list_pinjaman/screens/list_pinjaman.dart'; // Assuming this exists for "Riwayat Pinjaman"
// import 'package:kkba_mobile/feature/riwayat_tagihan/screens/riwayat_tagihan.dart'; // Create this screen
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart'; // For "Mutasi Tabungan" / "Info Tabungan"
import 'package:kkba_mobile/feature/pencairan/screens/pencairan.dart'; // For "Form Pencairan Tabungan"
// import 'package:kkba_mobile/feature/riwayat_pencairan/screens/riwayat_pencairan.dart'; // Create this screen

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
    ]);
  }

  Future<void> _loadProfilePhotoUrl() async {
    if (!mounted) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? url = prefs.getString('profile_photo_url');
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
          title: Text(
            'Konfirmasi Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: AppColors.secondaryTextLight),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: AppColors.errorLight,
                  fontWeight: FontWeight.bold,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    Color? iconBackgroundColor,
    Color iconColor = Colors.white,
    double iconSize = 30.0,
    double backgroundIconSize = 70.0,
    double spacing = 8.0,
    double fontSize = 11.5,
  }) {
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
                  color:
                      iconBackgroundColor ??
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
              SizedBox(height: spacing),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.secondaryTextLight,
                  height: 1.2,
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

  Widget _buildPinjamanMenu(BuildContext context) {
    final Color simulasiBgColor = Colors.orange.shade50;
    final Color pengajuanBgColor = Colors.blue.shade50;
    final Color riwayatPinjamanBgColor = Colors.green.shade50;
    final Color riwayatTagihanBgColor = Colors.purple.shade50;
    final Color defaultIconColor = Colors.black.withOpacity(0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4.0,
          ), // Padding judul menu, relatif terhadap margin utama
          child: Text(
            'Pinjaman',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: Icons.calculate_outlined,
              label: "Simulasi",
              context: context,
              iconBackgroundColor: simulasiBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SimulasiPinjamanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16), // Gutter 16px
            _buildMenuItem(
              icon: Icons.description_outlined,
              label: "Form Pengajuan",
              context: context,
              iconBackgroundColor: pengajuanBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FormWizardScreen()),
                  ),
            ),
            const SizedBox(width: 16), // Gutter 16px
            _buildMenuItem(
              icon: Icons.history_edu_outlined,
              label: "Riwayat Pinjaman",
              context: context,
              iconBackgroundColor: riwayatPinjamanBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarPinjamanScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16), // Gutter 16px
            _buildMenuItem(
              icon: Icons.payment_outlined,
              label: "Riwayat Tagihan",
              context: context,
              iconBackgroundColor: riwayatTagihanBgColor,
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

  Widget _buildTabunganMenu(BuildContext context) {
    final Color mutasiBgColor = Colors.teal.shade50;
    final Color pencairanBgColor = Colors.red.shade50;
    final Color riwayatPencairanBgColor = Colors.indigo.shade50;
    final Color defaultIconColor = Colors.black.withOpacity(0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0), // Padding judul menu
          child: Text(
            'Tabungan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              icon: Icons.swap_horiz_outlined,
              label: "Mutasi Tabungan",
              context: context,
              iconBackgroundColor: mutasiBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TabunganPage()),
                  ),
            ),
            const SizedBox(width: 16), // Gutter 16px
            _buildMenuItem(
              icon: Icons.savings_outlined,
              label: "Form Pencairan",
              context: context,
              iconBackgroundColor: pencairanBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PencairanTabunganScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16), // Gutter 16px
            _buildMenuItem(
              icon: Icons.manage_history_outlined,
              label: "Riwayat Pencairan",
              context: context,
              iconBackgroundColor: riwayatPencairanBgColor,
              iconColor: defaultIconColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryPengajuanScreen(),
                    ),
                  ),
            ),
            // Kolom ke-4 kosong, Expanded akan mengambil sisa ruang
            Expanded(child: Container()),
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
            _navigateToPlaceholder("Semua Berita");
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
    final double bannerHeight = screenWidth * 0.52; //
    // Seberapa banyak banner akan "turun" dari header
    final double bannerOverlap =
        bannerHeight / 3.5; // Sekitar sepertiga tinggi banner

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
                                                width: 36,
                                                height: 36,
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
                                  const SizedBox(width: 12),

                                  // **** PERUBAHAN DI SINI ****
                                  // Ikon Logout dibungkus dengan Padding untuk diturunkan sedikit
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                    ), // Beri sedikit padding atas
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.logout_outlined,
                                        color: AppColors.errorLight,
                                      ),
                                      iconSize: 26,
                                      tooltip: 'Logout',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _logoutUser,
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
                        onGenerateQr: _handleGenerateQr,
                        onKeanggotaanTap: () {
                          _navigateToPlaceholder("Halaman Keanggotaan");
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Spacer untuk memberi ruang setelah banner yang overlap
            SliverToBoxAdapter(
              child: SizedBox(height: 24 + bannerOverlap * 0.5),
            ),

            // SliverToBoxAdapter untuk menu dan berita
            SliverToBoxAdapter(
              child: PageWrapper(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                  ), // Margin 24px untuk konten utama
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPinjamanMenu(context),
                      const SizedBox(height: 28),
                      _buildTabunganMenu(context),
                      const SizedBox(height: 28),
                      _buildBeritaSectionTitle(context),
                      const SizedBox(height: 12),
                      _buildBeritaSectionContent(),
                      const SizedBox(height: 20),
                    ],
                  ),
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
