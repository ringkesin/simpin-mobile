// feature/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/anggota_profile.dart'; // Pastikan import path benar
import '../../../service/api_service.dart';
import '../../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ... (State variables: _isLoading, _errorMessage, etc. tetap sama) ...
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  AnggotaProfile? _anggotaProfile;
  String? _adminNama;
  String? _adminEmail;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // ... (kode _loadInitialData tetap sama) ...
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
        setState(() {
          _isLoading = false;
        });
      } else {
        print("User is not Admin. Fetching Anggota Profile from API.");
        final profileResponse = await _apiService.getAnggotaProfile();
        if (profileResponse.success && profileResponse.data?.anggota != null) {
          _anggotaProfile = profileResponse.data!.anggota!;
          setState(() {
            _isLoading = false;
          });
        } else {
          throw Exception(
            profileResponse.message ??
                "Data anggota tidak valid dalam respons.",
          );
        }
      }
    } catch (e) {
      print("Error loading initial profile data: $e");
      setState(() {
        _isLoading = false;
        if (e is Exception) {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        } else {
          _errorMessage = "Terjadi kesalahan tidak dikenal.";
        }
      });
    }
  }

  String _formatDate(String? dateString) {
    // ... (kode _formatDate tetap sama) ...
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _displayData(String? data) {
    // ... (kode _displayData tetap sama) ...
    return data != null && data.isNotEmpty ? data : '-';
  }

  Future<void> _handleLogout() async {
    // ... (kode _handleLogout tetap sama) ...
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User harus memilih tombol
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningLight),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Logout',
                style: AppTheme.textThemeLight.titleMedium,
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: AppTheme.textThemeLight.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.secondaryTextLight),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Kembalikan false
              },
            ),
            TextButton(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.errorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Kembalikan true
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      setState(() {
        _isLoggingOut = true;
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print("SharedPreferences cleared.");

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/', // Pastikan ini route login Anda
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        print("Error during logout: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal melakukan logout: ${e.toString()}'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
        setState(() {
          _isLoggingOut = false;
        });
      }
      // No need to set _isLoggingOut = false on success, as we navigate away
    }
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
      ),
      // Atur warna background scaffold di sini jika ingin putih semua
      // backgroundColor: AppColors.primaryBackgroundLight,
      backgroundColor: AppColors.primaryBackgroundLight, // Atau biarkan abu-abu
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    } else if (_errorMessage != null) {
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
                'Error: $_errorMessage',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Coba Lagi'),
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
    } else {
      // --- PERBAIKAN STRUKTUR ---
      // Gunakan SingleChildScrollView untuk seluruh konten body
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding di luar Column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- KONTEN KONDISIONAL (Admin atau Anggota) ---

            // Jika Admin
            if (_userRole == 'mobile_admin') ...[
              Card(
                // Card Info Admin
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.primaryBackgroundLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayData(_adminNama),
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.primaryTextLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.secondaryTextLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Email: ${_displayData(_adminEmail)}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 18,
                            color: AppColors.secondaryTextLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Role: Administrator',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildProfileSection(
                // Section Data Pribadi Admin
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
                // Section Kontak Admin
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
            ]
            // Jika Anggota Biasa
            else if (_anggotaProfile != null) ...[
              // --- PINDAHKAN DEKLARASI SEBELUM WIDGET MENGGUNAKANNYA ---
              // (Sebenarnya tidak perlu deklarasi ulang jika hanya dipakai di blok ini,
              // tapi untuk kejelasan bisa ditaruh di sini atau akses langsung _anggotaProfile)
              // final profile = _anggotaProfile!; // <-- Tidak perlu deklarasi ulang di sini
              Card(
                // Card Info Anggota
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.primaryBackgroundLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayData(_anggotaProfile!.nama), // Akses langsung
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.primaryTextLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: AppColors.secondaryTextLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No. Anggota: ${_displayData(_anggotaProfile!.nomorAnggota)}', // Akses langsung
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin_outlined,
                            size: 18,
                            color: AppColors.secondaryTextLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NIK Karyawan: ${_displayData(_anggotaProfile!.nik)}', // Akses langsung
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildProfileSection(
                // Section Data Pribadi Anggota
                context,
                title: "Data Pribadi",
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow(
                    context,
                    label: 'Nama Lengkap',
                    value: _displayData(_anggotaProfile!.nama),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'NIK Karyawan',
                    value: _displayData(_anggotaProfile!.nik),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'No. KTP',
                    value: _displayData(_anggotaProfile!.ktp),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'Tempat Lahir',
                    value: _displayData(_anggotaProfile!.tempatLahir),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'Tanggal Lahir',
                    value: _formatDate(_anggotaProfile!.tglLahir),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'Alamat',
                    value: _displayData(
                      _anggotaProfile!.alamat,
                    ), // Akses langsung
                    isMultiline: true,
                  ),
                ],
              ),
              _buildProfileSection(
                // Section Kontak Anggota
                context,
                title: "Kontak & Keanggotaan",
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildInfoRow(
                    context,
                    label: 'Email',
                    value: _displayData(_anggotaProfile!.email),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'No. Telepon',
                    value: _displayData(_anggotaProfile!.mobile),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'Tanggal Masuk',
                    value: _formatDate(_anggotaProfile!.tanggalMasuk),
                  ), // Akses langsung
                  _buildInfoRow(
                    context,
                    label: 'Status Registrasi App',
                    value:
                        _anggotaProfile!.isActuallyRegistered
                            ? 'Terdaftar'
                            : 'Belum Terdaftar',
                    valueColor:
                        _anggotaProfile!.isActuallyRegistered
                            ? AppColors.successLight
                            : AppColors.warningLight,
                  ),
                ],
              ),
            ], // Akhir dari else if (_anggotaProfile != null)
            // --- TOMBOL LOGOUT (Bagian dari Column utama) ---
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
              child: ElevatedButton.icon(
                icon:
                    _isLoggingOut
                        ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(Icons.logout, size: 18),
                label: Text('Logout'),
                onPressed: _isLoggingOut ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // --- AKHIR TOMBOL LOGOUT ---
          ],
        ),
      );
    }
  }

  // Helper Widget _buildProfileSection (tetap sama)
  Widget _buildProfileSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // ... (kode _buildProfileSection Anda tetap sama) ...
    final textTheme = AppTheme.textThemeLight;
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: AppColors.primaryBackgroundLight,
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

  // Helper Widget _buildInfoRow (tetap sama)
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    // ... (kode _buildInfoRow Anda tetap sama) ...
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
