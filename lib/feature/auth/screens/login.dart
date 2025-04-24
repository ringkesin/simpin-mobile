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
  bool _isDarkMode = false; // Sesuaikan logika dark mode Anda
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  // --- AWAL FUNGSI HANDLE LOGIN YANG DIPERBAIKI ---
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      final loginResponse = LoginResponse.fromJson(response);
      print('Parsed Response Error: ${loginResponse.error}');
      print('Parsed Response Success: ${loginResponse.success}');
      print('Parsed Response Message: ${loginResponse.message}');

      if (loginResponse.error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = loginResponse.error;
        });
      } else if (loginResponse.success && loginResponse.data != null) {
        // User check dihilangkan sementara krn tidak dipakai langsung di role check
        // Login sukses dan data ada

        final prefs = await SharedPreferences.getInstance();
        final data = loginResponse.data!; // Akses data (sudah dicek not null)
        // User data hanya diambil jika perlu, tidak untuk role check
        final userData =
            data.user; // Bisa null jika User tidak required di LoginData
        final anggotaData = data.anggota; // Akses anggota (bisa null)

        // --- PERBAIKAN: Ambil role dari 'data', bukan 'userData' ---
        final String userRole = data.role ?? 'unknown';
        await prefs.setString("token", data.token);
        await prefs.setString(
          "role",
          userRole,
        ); // Simpan role yang sudah diambil
        print("Role terdeteksi: $userRole");

        // --- PERBAIKAN: Gunakan 'userRole' (dari data.role) untuk pengecekan ---
        if (userRole == 'mobile_admin') {
          print("Login sebagai Admin: Menyimpan data user.");
          // Pastikan userData tidak null sebelum mengakses fieldnya
          if (userData != null) {
            await prefs.setString("nama", userData.name ?? '');
            await prefs.setString("email", userData.email ?? '');
            print(
              "Data admin disimpan: Nama=${userData.name}, Email=${userData.email}",
            );
          } else {
            print("WARNING: Data user null untuk admin.");
            // Mungkin set nama/email default atau biarkan kosong
            await prefs.setString("nama", 'Admin'); // Contoh default
            await prefs.setString("email", '');
          }
          // Hapus data anggota dari SharedPreferences jika login sebagai admin
          await prefs.remove("p_anggota_id");
          await prefs.remove("nomor_anggota");
          await prefs.remove("nik");
        } else {
          // Asumsikan role lain adalah anggota biasa
          print("Login sebagai Anggota: Mencoba menyimpan data anggota.");
          if (anggotaData != null) {
            await prefs.setInt("p_anggota_id", anggotaData.pAnggotaId ?? 0);
            await prefs.setString("nama", anggotaData.nama ?? '');
            await prefs.setString(
              "nomor_anggota",
              anggotaData.nomorAnggota ?? '',
            );
            // Cek email anggota dulu, fallback ke email user jika ada, baru default
            String finalEmail = anggotaData.email ?? userData?.email ?? '';
            await prefs.setString("email", finalEmail);
            await prefs.setString("nik", anggotaData.nik ?? '');
            print(
              "Data anggota disimpan: ID=${anggotaData.pAnggotaId}, Nama=${anggotaData.nama}",
            );
          } else {
            // Fallback jika user BUKAN admin TAPI data anggota null
            print(
              "WARNING: Data anggota null untuk user non-admin. Menyimpan data user jika ada.",
            );
            if (userData != null) {
              await prefs.setString("nama", userData.name ?? '');
              await prefs.setString("email", userData.email ?? '');
            } else {
              print("WARNING: Data user juga null untuk non-admin.");
              await prefs.setString("nama", 'Anggota'); // Contoh default
              await prefs.setString("email", '');
            }
            // Hapus data anggota lainnya untuk konsistensi
            await prefs.remove("p_anggota_id");
            await prefs.remove("nomor_anggota");
            await prefs.remove("nik");
          }
        }
        // --- Akhir Logika Pengecekan Role ---

        setState(() {
          _isLoading = false;
        });

        print("Navigasi ke /home");
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        // Handle kasus login gagal atau response tidak sesuai format
        setState(() {
          _isLoading = false;
          _errorMessage =
              loginResponse.message != null && loginResponse.message!.isNotEmpty
                  ? loginResponse.message
                  : "Login failed. Please check credentials or response format.";
          print(
            "Login Gagal atau Response Tidak Valid: Pesan = ${_errorMessage}",
          );
        });
      }
    } catch (e, stacktrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred: ${e.toString()}";
      });
      print("Login Exception: $e");
      print("Stacktrace: $stacktrace");
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
      backgroundColor: backgroundColor,
      body: SafeArea(
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
                        style: theme.headlineMedium?.copyWith(color: textColor),
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
                            color: textColor?.withOpacity(
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
                        obscureText: true, // Pastikan obscureText true
                        style: theme.bodyMedium?.copyWith(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: theme.bodyMedium?.copyWith(
                            color: textColor?.withOpacity(0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
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
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
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
                              color: textColor?.withOpacity(0.8),
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
    );
  }
}
