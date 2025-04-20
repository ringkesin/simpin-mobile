import 'package:flutter/material.dart';
import '../../../theme.dart'; // Import AppTheme
import '../../../service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registrasi.dart';
import '../../../model/login_response.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isDarkMode = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

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

      // Parse the response using the model
      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = loginResponse.error;
        });
      } else if (loginResponse.success && loginResponse.data != null) {
        // Save important data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", loginResponse.data!.token);
        await prefs.setInt(
          "p_anggota_id",
          loginResponse.data!.anggota.pAnggotaId,
        );
        await prefs.setString("nama", loginResponse.data!.anggota.nama);
        await prefs.setString(
          "nomor_anggota",
          loginResponse.data!.anggota.nomorAnggota,
        );
        await prefs.setString("email", loginResponse.data!.anggota.email);
        await prefs.setString("nik", loginResponse.data!.anggota.nik);

        setState(() {
          _isLoading = false;
        });

        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              loginResponse.message ?? "Login failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  constraints: BoxConstraints(
                    maxWidth:
                        500, // Supaya tidak terlalu lebar di tablet/desktop
                  ),
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
                            color: textColor,
                          ),
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                          filled: true,
                          fillColor:
                              _isDarkMode
                                  ? AppColors.secondaryBackgroundDark
                                  : AppColors.secondaryBackgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: theme.bodyMedium?.copyWith(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: theme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                          filled: true,
                          fillColor:
                              _isDarkMode
                                  ? AppColors.secondaryBackgroundDark
                                  : AppColors.secondaryBackgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
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
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Login",
                                    style: theme.titleLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error Message
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),

                      // const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: theme.bodySmall?.copyWith(color: textColor),
                          ),
                          TextButton(
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
