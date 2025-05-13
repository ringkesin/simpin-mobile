// feature/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/anggota_profile.dart'; // Pastikan import path benar
import '../../../service/api_service.dart'; // Pastikan ada metode changePassword
import '../../../theme.dart'; // Pastikan AppColors dan AppTheme.textThemeLight ada

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  AnggotaProfile? _anggotaProfile;
  String? _adminNama;
  String? _adminEmail;
  bool _isLoggingOut = false;

  TabController? _tabController;

  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // ... (Implementasi _loadInitialData Anda tetap sama) ...
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString("role");
      _adminNama = prefs.getString("nama");
      _adminEmail = prefs.getString("email");

      if (_userRole == 'mobile_admin') {
        print("User is Admin. Displaying data from SharedPreferences.");
        _photoUrl = prefs.getString("foto_url_admin");
      } else {
        print("User is not Admin. Fetching Anggota Profile from API.");
        // Ganti pemanggilan _apiService.getAnggotaProfile() dengan implementasi Anda
        // Ini contoh jika getAnggotaProfile mengembalikan class dengan success, data, message
        final dynamic profileResponseFromApi =
            await _apiService.getAnggotaProfile();

        // Asumsi profileResponseFromApi adalah Map<String, dynamic> atau objek custom
        // dan Anda punya cara untuk mengecek sukses dan mendapatkan data anggota
        // Misalnya, jika itu adalah Map:
        if (profileResponseFromApi is Map<String, dynamic> &&
            profileResponseFromApi['success'] == true &&
            profileResponseFromApi['data'] != null &&
            profileResponseFromApi['data']['anggota'] != null) {
          _anggotaProfile = AnggotaProfile.fromJson(
            profileResponseFromApi['data']['anggota'] as Map<String, dynamic>,
          );
          _photoUrl =
              'https://kkba-simpin.laravel.cloud/storage/avatar/ZiC7FiPxOetjB2rRds9ZGooAAFvtvzqBj7NKOA1w.png'; // GANTI 'foto' dengan field yang benar
        }
        // Atau jika itu adalah objek custom (misal, ApiResponse yang TIDAK Anda gunakan secara global)
        // else if (profileResponseFromApi.success && profileResponseFromApi.data?.anggota != null) {
        // _anggotaProfile = profileResponseFromApi.data!.anggota!;
        // _photoUrl = _anggotaProfile!.foto;
        // }
        else {
          String message = "Data anggota tidak valid dalam respons.";
          if (profileResponseFromApi is Map<String, dynamic> &&
              profileResponseFromApi['message'] != null) {
            message = profileResponseFromApi['message'];
          }
          // else if (profileResponseFromApi.message != null){
          //   message = profileResponseFromApi.message;
          // }
          throw Exception(message);
        }
      }
    } catch (e) {
      print("Error loading initial profile data: $e");
      _errorMessage =
          e is Exception
              ? e.toString().replaceFirst("Exception: ", "")
              : "Terjadi kesalahan tidak dikenal.";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _displayData(String? data) {
    return data != null && data.isNotEmpty ? data : '-';
  }

  Future<void> _handleLogout() async {
    // ... (Implementasi _handleLogout Anda tetap sama) ...
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningLight),
              const SizedBox(width: 10),
              Text(
                'Konfirmasi Logout',
                style: AppTheme.textThemeLight.titleMedium,
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: AppTheme.textThemeLight.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.secondaryTextLight),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.errorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      if (!mounted) return;
      setState(() => _isLoggingOut = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: ${e.toString()}'),
              backgroundColor: AppColors.errorLight,
            ),
          );
          setState(() => _isLoggingOut = false);
        }
      }
    }
  }

  Future<void> _handleChangePassword() async {
    // ... (Implementasi _handleChangePassword Anda tetap sama) ...
    if (_changePasswordFormKey.currentState?.validate() ?? false) {
      if (!mounted) return;
      setState(() => _isChangingPassword = true);

      try {
        final Map<String, dynamic> responseData = await _apiService
            .changePassword(
              oldPassword: _oldPasswordController.text,
              newPassword: _newPasswordController.text,
              confirmNewPassword: _confirmNewPasswordController.text,
            );

        if (!mounted) return;
        String serverMessage =
            responseData['message'] as String? ?? 'Password berhasil diubah.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverMessage),
            backgroundColor: AppColors.successLight,
          ),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } on Exception catch (e) {
        if (!mounted) return;
        final errorMessage =
            e.toString().startsWith("Exception: ")
                ? e.toString().substring("Exception: ".length)
                : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorLight,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isChangingPassword = false);
        }
      }
    }
  }

  String? _validateNewPassword(String? value) {
    // ... (Implementasi _validateNewPassword Anda tetap sama) ...
    if (value == null || value.isEmpty) {
      return 'Password baru tidak boleh kosong.';
    }
    if (value.length < 8) {
      return 'Minimal 8 karakter.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Minimal 1 huruf besar.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Minimal 1 angka.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'mobile_admin' ? 'Profil Admin' : 'Profil Anggota',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        // TabBar dihapus dari bottom AppBar
      ),
      backgroundColor: AppColors.primaryBackgroundLight,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildProfilePicture(),
        const SizedBox(height: 16),
        _buildMainInfoCard(context), // Kartu Info Utama (Nama, dll.)
        const SizedBox(height: 16),
        TabBar(
          // TabBar sekarang di dalam Column body
          controller: _tabController,
          labelColor: AppColors.primaryLight, // Warna label tab aktif
          unselectedLabelColor:
              AppColors.secondaryTextLight, // Warna label tab tidak aktif
          indicatorColor: AppColors.primaryLight, // Warna indikator tab
          tabs: const [Tab(text: 'Info Profil'), Tab(text: 'Ganti Password')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileInfoTab(context),
              _buildChangePasswordTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    // ... (Implementasi _buildProfilePicture Anda tetap sama) ...
    bool hasValidPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    ImageProvider backgroundImage;
    if (hasValidPhoto) {
      backgroundImage = NetworkImage(_photoUrl!);
    } else {
      backgroundImage = const AssetImage(
        'assets/images/placeholder_transparent.png',
      );
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: hasValidPhoto ? backgroundImage : null,
      onBackgroundImageError:
          hasValidPhoto
              ? (dynamic exception, StackTrace? stackTrace) {
                print('Error loading profile image: $exception');
                if (mounted) {
                  setState(() {
                    _photoUrl = null;
                  });
                }
              }
              : null,
      child:
          !hasValidPhoto
              ? Icon(Icons.person, size: 70, color: Colors.grey[600])
              : null,
    );
  }

  Widget _buildMainInfoCard(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;
    Widget cardContent;

    if (_userRole == 'mobile_admin') {
      cardContent = Column(
        mainAxisSize:
            MainAxisSize.min, // Agar Column tidak mengambil semua tinggi Card
        crossAxisAlignment: CrossAxisAlignment.center, // Rata tengah horizontal
        children: [
          Text(
            _displayData(_adminNama),
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryTextLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // Rata tengah teks
          ),
          const SizedBox(height: 8),
          Text(
            'Email: ${_displayData(_adminEmail)}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryTextLight,
            ),
            textAlign: TextAlign.center, // Rata tengah teks
          ),
          const SizedBox(height: 4),
          Text(
            'Role: Administrator',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryTextLight,
            ),
            textAlign: TextAlign.center, // Rata tengah teks
          ),
        ],
      );
    } else if (_anggotaProfile != null) {
      final profile = _anggotaProfile!;
      cardContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _displayData(profile.nama),
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryTextLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No. Anggota: ${_displayData(profile.nomorAnggota)}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryTextLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'NIK Karyawan: ${_displayData(profile.nik)}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryTextLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      cardContent = const Center(
        child: Text("Data tidak tersedia"),
      ); // Fallback
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color:
          Colors
              .white, // atau AppColors.primaryBackgroundLight jika ingin sama dengan bg screen
      child: Container(
        // Tambahkan Container untuk padding dan alignment
        padding: const EdgeInsets.all(16.0),
        width:
            double
                .infinity, // Pastikan Card mengambil lebar penuh untuk centering
        child: cardContent,
      ),
    );
  }

  Widget _buildProfileInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian detail profil (setelah kartu info utama dipindahkan)
          if (_userRole == 'mobile_admin')
            ..._buildAdminProfileSections(context) // Helper baru
          else if (_anggotaProfile != null)
            ..._buildAnggotaProfileSections(context), // Helper baru

          Padding(
            // Tombol Logout
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: ElevatedButton.icon(
              icon:
                  _isLoggingOut
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              onPressed: _isLoggingOut ? null : _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper baru untuk bagian detail profil Admin (tanpa kartu info utama)
  List<Widget> _buildAdminProfileSections(BuildContext context) {
    return [
      _buildProfileSection(
        context,
        title: "Data Pribadi",
        icon: Icons.person_outline,
        children: [
          _buildInfoRow(
            context,
            label: 'Nama Lengkap',
            value: _displayData(_adminNama),
          ),
          _buildInfoRow(context, label: 'NIK Karyawan', value: '-'),
          _buildInfoRow(context, label: 'No. KTP', value: '-'),
          _buildInfoRow(context, label: 'Tempat Lahir', value: '-'),
          _buildInfoRow(context, label: 'Tanggal Lahir', value: '-'),
          _buildInfoRow(context, label: 'Alamat', value: '-'),
        ],
      ),
      _buildProfileSection(
        context,
        title: "Kontak & Keanggotaan",
        icon: Icons.contact_mail_outlined,
        children: [
          _buildInfoRow(
            context,
            label: 'Email',
            value: _displayData(_adminEmail),
          ),
          _buildInfoRow(context, label: 'No. Telepon', value: '-'),
          _buildInfoRow(context, label: 'Tanggal Masuk', value: '-'),
          _buildInfoRow(context, label: 'No. Anggota', value: '-'),
        ],
      ),
    ];
  }

  // Helper baru untuk bagian detail profil Anggota (tanpa kartu info utama)
  List<Widget> _buildAnggotaProfileSections(BuildContext context) {
    final profile = _anggotaProfile!;
    return [
      _buildProfileSection(
        context,
        title: "Data Pribadi",
        icon: Icons.person_outline,
        children: [
          _buildInfoRow(
            context,
            label: 'Nama Lengkap',
            value: _displayData(profile.nama),
          ),
          _buildInfoRow(
            context,
            label: 'NIK Karyawan',
            value: _displayData(profile.nik),
          ),
          _buildInfoRow(
            context,
            label: 'No. KTP',
            value: _displayData(profile.ktp),
          ),
          _buildInfoRow(
            context,
            label: 'Tempat Lahir',
            value: _displayData(profile.tempatLahir),
          ),
          _buildInfoRow(
            context,
            label: 'Tanggal Lahir',
            value: _formatDate(profile.tglLahir),
          ),
          _buildInfoRow(
            context,
            label: 'Alamat',
            value: _displayData(profile.alamat),
            isMultiline: true,
          ),
        ],
      ),
      _buildProfileSection(
        context,
        title: "Kontak & Keanggotaan",
        icon: Icons.contact_mail_outlined,
        children: [
          _buildInfoRow(
            context,
            label: 'Email',
            value: _displayData(profile.email),
          ),
          _buildInfoRow(
            context,
            label: 'No. Telepon',
            value: _displayData(profile.mobile),
          ),
          _buildInfoRow(
            context,
            label: 'Tanggal Masuk',
            value: _formatDate(profile.tanggalMasuk),
          ),
          _buildInfoRow(
            context,
            label: 'Status Registrasi App',
            value:
                profile.isActuallyRegistered ? 'Terdaftar' : 'Belum Terdaftar',
            valueColor:
                profile.isActuallyRegistered
                    ? AppColors.successLight
                    : AppColors.warningLight,
          ),
        ],
      ),
    ];
  }

  Widget _buildChangePasswordTab(BuildContext context) {
    // ... (Implementasi _buildChangePasswordTab Anda tetap sama) ...
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _changePasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ubah Password Akun Anda',
              style: AppTheme.textThemeLight.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan password baru Anda aman dan mudah diingat.',
              style: AppTheme.textThemeLight.bodySmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOldPassword,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                hintText: 'Masukkan password lama Anda',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOldPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(
                        () => _obscureOldPassword = !_obscureOldPassword,
                      ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator:
                  (value) =>
                      (value?.isEmpty ?? true)
                          ? 'Password lama tidak boleh kosong.'
                          : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                hintText: 'Masukkan password baru',
                prefixIcon: const Icon(Icons.lock_person_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: _validateNewPassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmNewPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                hintText: 'Ketik ulang password baru',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Konfirmasi password tidak boleh kosong.';
                if (value != _newPasswordController.text)
                  return 'Password tidak cocok.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon:
                  _isChangingPassword
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan Password'),
              onPressed: _isChangingPassword ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    // ... (Implementasi _buildErrorState Anda tetap sama) ...
    final textTheme = AppTheme.textThemeLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.errorLight, size: 50),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat profil',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.primaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // ... (Implementasi _buildProfileSection Anda tetap sama, pastikan warna Card sesuai) ...
    final textTheme = AppTheme.textThemeLight;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white, // Warna Card agar kontras
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    // ... (Implementasi _buildInfoRow Anda tetap sama) ...
    final textTheme = AppTheme.textThemeLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120, // Lebar label konsisten
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.primaryTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
