// feature/profile/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
// !! PENTING: PASTIKAN PATH DAN NAMA FILE MODEL INI BENAR !!
import '../../../model/anggota_profile.dart';
import '../../../service/api_service.dart';
import '../../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // Instance ApiService
  final ApiService _apiService = ApiService();

  // State untuk data profil
  bool _isLoading = true;
  String? _errorMessage;
  ProfileAnggota? _anggotaProfile;
  ProfileUser? _profileUser;
  String? _photoUrl;

  // State untuk UI & Proses
  bool _isLoggingOut = false;
  bool _isUploadingPhoto = false;
  TabController? _tabController;

  // State & Controller untuk Ganti Password
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;

  // State & Controller untuk Edit Profil
  final GlobalKey<FormState> _editProfileFormKey = GlobalKey<FormState>();
  bool _isEditingProfile = false; // Toggle mode edit
  bool _isSavingProfile = false; // Loading saat menyimpan
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  DateTime? _selectedDate; // Untuk menyimpan tanggal lahir yang dipilih

  // State untuk upload dokumen
  final _docFormKey = GlobalKey<FormState>();
  bool _isUpdatingDocs = false;
  final _noKtpController = TextEditingController();
  final _noKartuPegawaiController = TextEditingController();
  final _noKartuKeluargaController = TextEditingController();
  final _noNpwpController = TextEditingController();
  XFile? _fileKtp;
  XFile? _fileKartuPegawai;
  XFile? _fileKartuKeluarga;
  XFile? _fileNpwp;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_anggotaProfile != null) {
      _noKtpController.text = _anggotaProfile!.ktp ?? '';
      _noKartuPegawaiController.text = _anggotaProfile!.nik ?? '';
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _nomorHpController.dispose();
    _tglLahirController.dispose();
    _noKtpController.dispose();
    _noKartuPegawaiController.dispose();
    _noKartuKeluargaController.dispose();
    _noNpwpController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ProfileResponseComplex profileResponse =
          await ApiService.getProfile();
      if (!mounted) return;

      if (profileResponse.success && profileResponse.data != null) {
        setState(() {
          _profileUser = profileResponse.data!.profileUser;
          _anggotaProfile = profileResponse.data!.profileAnggota;
          if (_profileUser == null && _anggotaProfile == null) {
            _errorMessage = "Data profil tidak lengkap dari API.";
          }
          _photoUrl = _profileUser?.profilePhotoUrl;
        });
      } else {
        throw Exception(
          profileResponse.message.isNotEmpty
              ? profileResponse.message
              : "Gagal memuat profil.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Error loading initial profile data: $e");
      setState(() {
        _errorMessage =
            e is Exception
                ? e.toString().replaceFirst("Exception: ", "")
                : "Kesalahan tidak dikenal.";
      });
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
            // Tidak perlu loadInitialData() penuh, cukup update URL
          }
        } else {
          throw Exception(
            uploadResponse['message'] ??
                'Gagal memperbarui foto profil dari server.',
          );
        }
      }
    } catch (e) {
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
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (_isEditingProfile && _anggotaProfile != null) {
        _alamatController.text = _anggotaProfile!.alamat ?? '';
        _emailController.text = _anggotaProfile!.email ?? '';
        _nomorHpController.text = _anggotaProfile!.mobile ?? '';

        if (_anggotaProfile!.tglLahir != null &&
            _anggotaProfile!.tglLahir!.isNotEmpty) {
          try {
            _selectedDate = DateTime.parse(_anggotaProfile!.tglLahir!);
            _tglLahirController.text = DateFormat(
              'dd MMMM yyyy',
              'id_ID',
            ).format(_selectedDate!);
          } catch (e) {
            _tglLahirController.text = _anggotaProfile!.tglLahir!;
            _selectedDate = null;
          }
        } else {
          _tglLahirController.clear();
          _selectedDate = null;
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tglLahirController.text = DateFormat(
          'dd MMMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!(_editProfileFormKey.currentState?.validate() ?? false)) return;

    if (_anggotaProfile?.pAnggotaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: ID Anggota tidak ditemukan.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await _apiService.updateProfileAnggota(
        pAnggotaId: _anggotaProfile!.pAnggotaId!,
        tglLahir: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        alamat:
            _alamatController.text.isNotEmpty ? _alamatController.text : null,
        alamatEmail:
            _emailController.text.isNotEmpty ? _emailController.text : null,
        nomorHp:
            _nomorHpController.text.isNotEmpty ? _nomorHpController.text : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil berhasil diperbarui.'),
          backgroundColor: AppColors.successLight,
        ),
      );

      setState(() {
        _isEditingProfile = false;
        _isSavingProfile = false;
      });
      await _loadInitialData();
    } on Exception catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (mounted && _isSavingProfile) setState(() => _isSavingProfile = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final DateTime? date = DateTime.tryParse(dateString);
      if (date != null) {
        return DateFormat('dd MMMM yyyy', 'id_ID').format(date.toLocal());
      } else {
        return dateString;
      }
    } catch (e) {
      return dateString;
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
        await prefs
            .clear(); // Cara lebih aman untuk membersihkan semua data sesi
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
        FocusScope.of(context).unfocus();
      } on Exception catch (e) {
        if (!mounted) return;
        final errorMessage = e.toString().replaceFirst("Exception: ", "");
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

  Future<XFile?> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return XFile(result.files.single.path!);
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<XFile?> _pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      return null;
    }
  }

  Future<void> _handleUpdateDocuments() async {
    if (!(_docFormKey.currentState?.validate() ?? false)) return;

    if (_fileKtp == null &&
        _fileKartuPegawai == null &&
        _fileKartuKeluarga == null &&
        _fileNpwp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu file dokumen untuk diunggah.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdatingDocs = true);

    try {
      final response = await _apiService.updateUserDocuments(
        attachmentKtp: _fileKtp,
        noKtp: _noKtpController.text,
        attachmentKartuPegawai: _fileKartuPegawai,
        noKartuPegawai: _noKartuPegawaiController.text,
        attachmentKartuKeluarga: _fileKartuKeluarga,
        noKartuKeluarga: _noKartuKeluargaController.text,
        attachmentNpwp: _fileNpwp,
        noNpwp: _noNpwpController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Dokumen berhasil diperbarui.'),
          backgroundColor: AppColors.successLight,
        ),
      );

      setState(() {
        _fileKtp = null;
        _fileKartuPegawai = null;
        _fileKartuKeluarga = null;
        _fileNpwp = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingDocs = false);
    }
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
        "Data profil tidak dapat dimuat. Silakan coba lagi.",
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
          tabs: const [
            Tab(text: 'Info Profil'),
            Tab(text: 'Dokumen'), // Tab baru
            Tab(text: 'Ganti Password'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileInfoTab(context),
              _buildDocumentTab(context), // View baru untuk tab dokumen
              _buildChangePasswordTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _docFormKey,
        child: Column(
          children: [
            _buildDocumentSection(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUpdatingDocs ? null : _handleUpdateDocuments,
              icon:
                  _isUpdatingDocs
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Simpan Perubahan Dokumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
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

  // BARU: Widget untuk membangun keseluruhan seksi dokumen
  Widget _buildDocumentSection(BuildContext context) {
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
                Icon(
                  Icons.folder_copy_outlined,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Dokumen Keanggotaan",
                  style: AppTheme.textThemeLight.titleMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            _buildDocumentUploader(
              label: 'Nomor KTP',
              controller: _noKtpController,
              file: _fileKtp,
              onPickFile: () async {
                final file = await _pickPdfFile(); // DIUBAH
                if (file != null) setState(() => _fileKtp = file);
              },
            ),
            const SizedBox(height: 20),
            _buildDocumentUploader(
              label: 'Nomor Kartu Pegawai',
              controller: _noKartuPegawaiController,
              file: _fileKartuPegawai,
              onPickFile: () async {
                final file = await _pickPdfFile(); // DIUBAH
                if (file != null) setState(() => _fileKartuPegawai = file);
              },
            ),
            const SizedBox(height: 20),
            _buildDocumentUploader(
              label: 'Nomor Kartu Keluarga',
              controller: _noKartuKeluargaController,
              file: _fileKartuKeluarga,
              onPickFile: () async {
                final file = await _pickPdfFile(); // DIUBAH
                if (file != null) setState(() => _fileKartuKeluarga = file);
              },
            ),
            const SizedBox(height: 20),
            _buildDocumentUploader(
              label: 'Nomor NPWP',
              controller: _noNpwpController,
              file: _fileNpwp,
              onPickFile: () async {
                final file = await _pickPdfFile(); // DIUBAH
                if (file != null) setState(() => _fileNpwp = file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploader({
    required String label,
    required TextEditingController controller,
    required XFile? file,
    required VoidCallback onPickFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (file != null && (value == null || value.isEmpty)) {
              return 'Nomor tidak boleh kosong jika file diunggah';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickFile,
          icon: Icon(
            Icons.attach_file_rounded,
            size: 16,
            color: AppColors.secondaryTextLight,
          ),
          label: Expanded(
            child: Text(
              file?.name ?? 'Pilih file PDF...', // DIUBAH
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    file != null
                        ? AppColors.primaryTextLight
                        : AppColors.secondaryTextLight,
                fontWeight: file != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: networkImageProvider,
          onBackgroundImageError:
              hasValidPhoto && networkImageProvider != null
                  ? (dynamic exception, StackTrace? stackTrace) {
                    if (mounted) setState(() => _photoUrl = null);
                  }
                  : null,
          child:
              networkImageProvider == null
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
                (_anggotaProfile?.nik != null || _anggotaProfile == null)) ...[
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
                "Informasi profil tidak dapat ditampilkan.",
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
          actionWidget:
              _isEditingProfile
                  ? null
                  : IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 22,
                      color: AppColors.primaryLight,
                    ),
                    tooltip: 'Edit Profil',
                    onPressed: _toggleEditMode,
                  ),
          children: [
            _isEditingProfile
                ? _buildEditProfileForm(context)
                : _buildAnggotaInfoView(context, anggota),
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

  Widget _buildAnggotaInfoView(BuildContext context, ProfileAnggota anggota) {
    return Column(
      children: [
        if (_profileUser == null ||
            (_profileUser!.name != anggota.nama &&
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
    );
  }

  Widget _buildEditProfileForm(BuildContext context) {
    return Form(
      key: _editProfileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _alamatController,
            decoration: const InputDecoration(labelText: 'Alamat'),
            maxLines: 3,
            minLines: 1,
            validator: null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email Kontak'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Masukkan format email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomorHpController,
            decoration: const InputDecoration(labelText: 'Nomor HP Kontak'),
            keyboardType: TextInputType.phone,
            validator: null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tglLahirController,
            decoration: const InputDecoration(
              labelText: 'Tanggal Lahir (Wajib)',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
            validator:
                (value) =>
                    (value?.isEmpty ?? true)
                        ? 'Tanggal lahir wajib dipilih'
                        : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSavingProfile ? null : _toggleEditMode,
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSavingProfile ? null : _handleSaveProfile,
                icon:
                    _isSavingProfile
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    Widget? actionWidget,
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
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (actionWidget != null) actionWidget,
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
