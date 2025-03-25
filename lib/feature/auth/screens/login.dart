import 'package:flutter/material.dart';
import '../../../theme.dart'; // Import AppTheme
import '../../../service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registrasi.dart';

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

    final response = await _apiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (response.containsKey("error")) {
      setState(() {
        _isLoading = false;
        _errorMessage = response["error"];
      });
    } else if (response["success"] == true) {
      // Simpan token ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", response["data"]["token"]);

      setState(() {
        _isLoading = false;
      });

      // Navigasi ke halaman utama
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Login failed. Please try again.";
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  labelStyle: theme.bodyMedium?.copyWith(color: textColor),
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
                  labelStyle: theme.bodyMedium?.copyWith(color: textColor),
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
                    style: theme.bodyMedium?.copyWith(color: primaryColor),
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
                          ? const CircularProgressIndicator(color: Colors.white)
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
              const SizedBox(height: 16),

              // Create Account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: theme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ), // Ganti dengan halaman registrasi kamu
                      );
                    },
                    child: Text(
                      "Create Account",
                      style: theme.bodyMedium?.copyWith(color: primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
