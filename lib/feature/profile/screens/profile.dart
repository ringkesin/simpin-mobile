// feature/profile/screens/profile_screen.dart

import 'dart:io'; // Untuk File, jika Anda perlu menampilkannya langsung
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// !! PENTING: GANTI PATH DAN NAMA FILE IMPORT INI !!
// Pastikan path ini benar dan file model berisi:
// ProfileResponseComplex, ProfileUser, ProfileAnggota
import '../../../model/anggota_profile.dart'; // CONTOH: GANTI DENGAN NAMA FILE MODEL ANDA
import '../../../service/api_service.dart';
import '../../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // Instance ApiService untuk metode non-statis seperti changePassword
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  ProfileAnggota? _anggotaProfile;
  ProfileUser? _profileUser;
  bool _isLoggingOut = false;
  bool _isUploadingPhoto = false; // State untuk loading upload foto

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

  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print(
        "DEBUG ProfileScreen: Mengambil profil dari API (token diambil oleh ApiService).",
      );
      // ApiService.getProfile() sekarang mengambil token secara internal
      final ProfileResponseComplex profileResponse =
          await ApiService.getProfile();
      if (profileResponse.success && profileResponse.data != null) {
        _profileUser = profileResponse.data!.profileUser;
        _anggotaProfile = profileResponse.data!.profileAnggota;
        if (_profileUser == null && _anggotaProfile == null) {
          throw Exception("Data profil tidak lengkap dari API.");
        }
        _photoUrl = _profileUser?.profilePhotoUrl;
      } else {
        throw Exception(
          profileResponse.message.isNotEmpty
              ? profileResponse.message
              : "Gagal memuat profil.",
        );
      }
    } catch (e) {
      print("Error loading initial profile data: $e");
      _errorMessage =
          e is Exception
              ? e.toString().replaceFirst("Exception: ", "")
              : "Kesalahan tidak dikenal.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() => _isUploadingPhoto = true);

        // ApiService.updateProfilePhoto mengambil token secara internal
        final Map<String, dynamic> uploadResponse =
            await ApiService.updateProfilePhoto(pickedFile);

        if (uploadResponse['success'] == true) {
          String? newPhotoUrl;
          if (uploadResponse['data'] != null &&
              uploadResponse['data']['profile_photo_url'] != null) {
            newPhotoUrl = uploadResponse['data']['profile_photo_url'] as String;
          } else if (uploadResponse['data'] != null &&
              uploadResponse['data']['user'] != null &&
              uploadResponse['data']['user']['profile_photo_url'] != null) {
            newPhotoUrl =
                uploadResponse['data']['user']['profile_photo_url'] as String;
          } else if (uploadResponse['profile_photo_url'] != null) {
            newPhotoUrl = uploadResponse['profile_photo_url'] as String;
          }

          if (mounted) {
            setState(() {
              if (newPhotoUrl != null) {
                _photoUrl = newPhotoUrl;
              }
              _isUploadingPhoto = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadResponse['message'] ??
                      'Foto profil berhasil diperbarui.',
                ),
                backgroundColor: AppColors.successLight,
              ),
            );
            // Pertimbangkan memanggil _loadInitialData() untuk sinkronisasi penuh
            // await _loadInitialData();
          }
        } else {
          throw Exception(
            uploadResponse['message'] ??
                'Gagal memperbarui foto profil dari server.',
          );
        }
      } else {
        print('DEBUG ProfileScreen: Tidak ada gambar yang dipilih.');
      }
    } catch (e) {
      print('Error saat memilih atau mengunggah gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Exception
                  ? e.toString().replaceFirst("Exception: ", "")
                  : 'Gagal memproses gambar.',
            ),
            backgroundColor: AppColors.errorLight,
          ),
        );
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }
    try {
      // Gunakan DateTime.tryParse untuk mem-parsing string menjadi DateTime
      final DateTime? date = DateTime.tryParse(dateString);

      if (date != null) {
        // Jika parsing berhasil, format DateTime menggunakan DateFormat
        return DateFormat(
          'dd MMMM yyyy',
          'id_ID',
        ).format(date.toLocal()); // Perbaikan: yyyy bukan yyyy
      } else {
        // Jika DateTime.tryParse gagal (mengembalikan null)
        print(
          "Tidak dapat mem-parsing string tanggal dengan DateTime.tryParse: $dateString",
        );
        return dateString; // Kembalikan string asli
      }
    } catch (e) {
      // Menangkap error tak terduga lainnya selama proses
      print("Error dalam _formatDate untuk string '$dateString': $e");
      return dateString; // Fallback ke string asli
    }
  }

  String _displayData(String? data) {
    return data != null && data.isNotEmpty ? data : '-';
  }

  Future<void> _handleLogout() async {
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
        await prefs.remove("AUTH_TOKEN");
        await prefs.remove("role");
        await prefs.remove("nama");
        await prefs.remove("email");
        await prefs.remove("foto_url_admin");
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
    if (_changePasswordFormKey.currentState?.validate() ?? false) {
      if (!mounted) return;
      setState(() => _isChangingPassword = true);
      try {
        // --- PERBAIKAN DI SINI ---
        // Panggil metode changePassword melalui instance _apiService
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
    if (value == null || value.isEmpty)
      return 'Password baru tidak boleh kosong.';
    if (value.length < 8) return 'Minimal 8 karakter.';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Minimal 1 huruf besar.';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Minimal 1 angka.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;
    final appBarTitle =
        _isLoading
            ? 'Memuat Profil...'
            : (_profileUser?.name ??
                _anggotaProfile?.nama ??
                'Profil Pengguna');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
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
    if (_profileUser == null && _anggotaProfile == null) {
      return _buildErrorStateWithMessage(
        "Data profil tidak dapat dimuat. Silakan coba lagi atau hubungi dukungan.",
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildProfilePicture(),
        const SizedBox(height: 16),
        _buildMainInfoCard(context),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.secondaryTextLight,
          indicatorColor: AppColors.primaryLight,
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
    bool hasValidPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    ImageProvider? networkImageProvider;
    if (hasValidPhoto && _photoUrl!.startsWith('http')) {
      networkImageProvider = NetworkImage(_photoUrl!);
    } else if (hasValidPhoto) {
      hasValidPhoto = false;
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: hasValidPhoto ? networkImageProvider : null,
          onBackgroundImageError:
              hasValidPhoto && networkImageProvider != null
                  ? (dynamic exception, StackTrace? stackTrace) {
                    print('Error loading profile image: $exception');
                    if (mounted) setState(() => _photoUrl = null);
                  }
                  : null,
          child:
              (!hasValidPhoto || networkImageProvider == null)
                  ? Icon(Icons.person, size: 70, color: Colors.grey[600])
                  : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: AppColors.primaryLight,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              onTap: _isUploadingPhoto ? null : _pickAndUploadImage,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    _isUploadingPhoto
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfoCard(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    final String displayName =
        _profileUser?.name ?? _anggotaProfile?.nama ?? "Pengguna";
    String secondaryInfoLine1 =
        "No. Anggota: ${_displayData(_anggotaProfile?.nomorAnggota)}";
    String secondaryInfoLine2 =
        "NIK Karyawan: ${_displayData(_anggotaProfile?.nik)}";

    if (_anggotaProfile == null && _profileUser != null) {
      secondaryInfoLine1 = "Email: ${_displayData(_profileUser!.email)}";
      secondaryInfoLine2 = "Username: ${_displayData(_profileUser!.username)}";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryTextLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              secondaryInfoLine1,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (secondaryInfoLine2.isNotEmpty &&
                (_anggotaProfile?.nik != null &&
                        _anggotaProfile!.nik!.isNotEmpty ||
                    _anggotaProfile == null &&
                        _profileUser?.username != null &&
                        _profileUser!.username!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Text(
                secondaryInfoLine2,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_profileUser != null || _anggotaProfile != null)
            ..._buildUnifiedProfileSections(context)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "Informasi profil tidak dapat ditampilkan saat ini.",
                textAlign: TextAlign.center,
                style: AppTheme.textThemeLight.bodyMedium?.copyWith(
                  color: AppColors.secondaryTextLight,
                ),
              ),
            ),
          Padding(
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

  List<Widget> _buildUnifiedProfileSections(BuildContext context) {
    final user = _profileUser;
    final anggota = _anggotaProfile;
    List<Widget> sections = [];

    if (user != null) {
      sections.add(
        _buildProfileSection(
          context,
          title: "Informasi Akun",
          icon: Icons.account_circle_outlined,
          children: [
            _buildInfoRow(
              context,
              label: 'Nama Akun',
              value: _displayData(user.name),
            ),
            _buildInfoRow(
              context,
              label: 'Username',
              value: _displayData(user.username),
            ),
            _buildInfoRow(
              context,
              label: 'Email Akun',
              value: _displayData(user.email),
            ),
            _buildInfoRow(
              context,
              label: 'No. Telepon Akun',
              value: _displayData(user.mobile),
            ),
            _buildInfoRow(
              context,
              label: 'Akun Valid Sejak',
              value: _formatDate(user.validFrom?.toIso8601String()),
            ),
            if (user.emailVerifiedAt != null)
              _buildInfoRow(
                context,
                label: 'Email Terverifikasi',
                value: _formatDate(user.emailVerifiedAt?.toIso8601String()),
              ),
          ],
        ),
      );
    }

    if (anggota != null) {
      sections.add(
        _buildProfileSection(
          context,
          title: "Informasi Keanggotaan",
          icon: Icons.card_membership_outlined,
          children: [
            if (user == null ||
                (user.name != anggota.nama &&
                    anggota.nama != null &&
                    anggota.nama!.isNotEmpty))
              _buildInfoRow(
                context,
                label: 'Nama Anggota',
                value: _displayData(anggota.nama),
              ),
            _buildInfoRow(
              context,
              label: 'No. Anggota',
              value: _displayData(anggota.nomorAnggota),
            ),
            _buildInfoRow(
              context,
              label: 'NIK Karyawan',
              value: _displayData(anggota.nik),
            ),
            _buildInfoRow(
              context,
              label: 'No. KTP',
              value: _displayData(anggota.ktp),
            ),
            _buildInfoRow(
              context,
              label: 'Tempat Lahir',
              value: _displayData(anggota.tempatLahir),
            ),
            _buildInfoRow(
              context,
              label: 'Tanggal Lahir',
              value: _formatDate(anggota.tglLahir),
            ),
            _buildInfoRow(
              context,
              label: 'Alamat',
              value: _displayData(anggota.alamat),
              isMultiline: true,
            ),
            _buildInfoRow(
              context,
              label: 'Email Kontak',
              value: _displayData(anggota.email),
            ),
            _buildInfoRow(
              context,
              label: 'No. Telepon Kontak',
              value: _displayData(anggota.mobile),
            ),
            _buildInfoRow(
              context,
              label: 'Tgl. Masuk Anggota',
              value: _formatDate(anggota.tanggalMasuk),
            ),
            _buildInfoRow(
              context,
              label: 'Status Registrasi',
              value: anggota.isRegistered ? 'Terdaftar' : 'Belum Terdaftar',
              valueColor:
                  anggota.isRegistered
                      ? AppColors.successLight
                      : AppColors.warningLight,
            ),
          ],
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Tidak ada data profil rinci untuk ditampilkan.",
            textAlign: TextAlign.center,
            style: AppTheme.textThemeLight.bodyMedium,
          ),
        ),
      );
    }
    return sections;
  }

  Widget _buildChangePasswordTab(BuildContext context) {
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

  Widget _buildErrorStateWithMessage(String message) {
    final textTheme = AppTheme.textThemeLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.warningLight, size: 50),
            const SizedBox(height: 16),
            Text(
              'Informasi',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.primaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang'),
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
    final textTheme = AppTheme.textThemeLight;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
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
    final textTheme = AppTheme.textThemeLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
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
