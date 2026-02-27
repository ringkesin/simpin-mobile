import 'package:flutter/material.dart';
import '../../../theme.dart'; // Pastikan path import benar
import '../../../service/api_service.dart'; // Pastikan path import benar
import 'package:shared_preferences/shared_preferences.dart';
import 'registrasi.dart'; // Pastikan path import benar jika digunakan
import '../../../model/login_response.dart'; // Pastikan path import benar

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final bool _isDarkMode = false; // Sesuaikan logika dark mode Anda
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadLastUsername();
  }

  Future<void> _loadLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsername = prefs.getString('last_username');
    if (lastUsername != null && mounted) {
      setState(() {
        _usernameController.text = lastUsername;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.errorLight),
                const SizedBox(width: 10),
                Text('Login Gagal', style: AppTheme.textThemeLight.titleMedium),
              ],
            ),
            content: Text(message, style: AppTheme.textThemeLight.bodyMedium),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Coba Lagi',
                  style: TextStyle(color: AppColors.primaryLight),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }

  // --- AWAL FUNGSI HANDLE LOGIN YANG DIPERBAIKI ---
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success && loginResponse.data != null) {
        // ... Logika penyimpanan SharedPreferences Anda sudah benar ...
        // (Saya salin kembali tanpa perubahan)
        final prefs = await SharedPreferences.getInstance();
        // Simpan username terakhir yang berhasil login
        await prefs.setString("last_username", _usernameController.text);

        final data = loginResponse.data!;
        final userData = data.user;
        final anggotaData = data.anggota;
        final String userRole = data.role ?? 'unknown';
        await prefs.setString("token", data.token);
        await prefs.setString("role", userRole);
        if (userRole == 'mobile_admin') {
          await prefs.setString("nama", userData.name ?? '');
          await prefs.setInt("userId", userData.id ?? 0);
          await prefs.setString("email", userData.email ?? '');
          await prefs.remove("p_anggota_id");
          await prefs.remove("nomor_anggota");
        } else {
          if (anggotaData != null) {
            await prefs.setInt("p_anggota_id", anggotaData.pAnggotaId ?? 0);
            await prefs.setInt("userId", userData.id ?? 0);
            await prefs.setString("nama", anggotaData.nama ?? '');
            await prefs.setString(
              "nomor_anggota",
              anggotaData.nomorAnggota ?? '',
            );
            String finalEmail = anggotaData.email ?? userData.email ?? '';
            await prefs.setString("email", finalEmail);
            await prefs.setString(
              "profile_photo_url",
              userData.profilePhotoUrl ?? '',
            );
          } else {
            await prefs.setString("nama", userData.name ?? '');
            await prefs.setString("email", userData.email ?? '');
            await prefs.remove("p_anggota_id");
            await prefs.remove("nomor_anggota");
          }
        }

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        // DIUBAH: Panggil popup jika login gagal dari server
        setState(() => _isLoading = false);
        _showErrorDialog(
          loginResponse.message ?? "Username atau password Anda salah.",
        );
      }
    } catch (e) {
      // DIUBAH: Panggil popup jika terjadi exception (cth: jaringan error)
      setState(() => _isLoading = false);
      _showErrorDialog("Username atau password Anda salah. Silakan coba lagi.");
      print("Login Exception: $e");
    }
  }
  // --- AKHIR FUNGSI HANDLE LOGIN YANG DIPERBAIKI ---

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Kode build method Anda tetap sama) ...
    final theme =
        _isDarkMode ? AppTheme.textThemeDark : AppTheme.textThemeLight;
    final backgroundColor =
        _isDarkMode
            ? AppColors.primaryBackgroundDark
            : AppColors.primaryBackgroundLight;
    final primaryColor =
        _isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final textColor =
        _isDarkMode ? AppColors.primaryTextDark : AppColors.primaryTextLight;

    return Scaffold(
      backgroundColor: backgroundColor, // Contoh: Abu-abu terang

      body: Container(
        // Container ini sekarang HANYA menampilkan gambar pola, tanpa warna latar.
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     image: const AssetImage(
        //       'assets/images/background_simpin_mobile.png',
        //     ), // Ganti dengan path gambar Anda
        //     fit: BoxFit.cover,
        //     opacity: 1,
        //   ),
        // ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logokkba.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),

                        // Headline Text
                        Text(
                          "Welcome Back!",
                          style: theme.headlineMedium?.copyWith(
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Username Field
                        TextField(
                          controller: _usernameController,
                          style: theme.bodyMedium?.copyWith(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Username",
                            labelStyle: theme.bodyMedium?.copyWith(
                              color: textColor.withOpacity(
                                0.7,
                              ), // Sedikit redupkan label
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: primaryColor,
                            ), // Ganti ikon
                            filled: true,
                            fillColor:
                                _isDarkMode
                                    ? AppColors.secondaryBackgroundDark
                                    : AppColors.secondaryBackgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300.withOpacity(0.5),
                                width: 1,
                              ), // Border lebih halus
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ), // Border fokus sedikit tebal
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ), // Sesuaikan padding
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText:
                              !_isPasswordVisible, // Gunakan state untuk obscure
                          style: theme.bodyMedium?.copyWith(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: theme.bodyMedium?.copyWith(
                              color: textColor.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                            ),
                            // BARU: Suffix icon untuk reveal password
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryColor.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor:
                                _isDarkMode
                                    ? AppColors.secondaryBackgroundDark
                                    : AppColors.secondaryBackgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: Text(
                              "Forgot Password?",
                              style: theme.bodyMedium?.copyWith(
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2, // Sedikit shadow
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : Text(
                                      "Login",
                                      style: theme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing:
                                            0.5, // Sedikit spasi antar huruf
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Error Message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ), // Warna error sedikit beda
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: theme.bodySmall?.copyWith(
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ), // Kurangi padding default
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Create Account",
                                style: theme.bodySmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
