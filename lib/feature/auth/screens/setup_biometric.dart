import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme.dart';
import '../../../service/biometric_service.dart';
import '../../../service/api_service.dart';
import '../../../model/login_response.dart';

class SetupBiometricScreen extends StatefulWidget {
  const SetupBiometricScreen({super.key});

  @override
  State<SetupBiometricScreen> createState() => _SetupBiometricScreenState();
}

class _SetupBiometricScreenState extends State<SetupBiometricScreen> {
  final BiometricService _biometricService = BiometricService();
  final ApiService _apiService = ApiService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _username;

  // Step 1: Verify Password & Setup PIN, Step 2: Enable Biometric (optional)
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username =
          prefs.getString('last_username') ?? prefs.getString('username');
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password akun wajib diisi')),
      );
      return;
    }

    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN harus 6 digit angka')));
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi PIN tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_username == null || _username!.isEmpty) {
        throw Exception("Username tidak ditemukan. Silakan login ulang.");
      }

      // 1. Verifikasi Password ke Server
      final response = await _apiService.login(
        _username!,
        _passwordController.text,
      );
      final loginResponse = LoginResponse.fromJson(response);

      if (!loginResponse.success) {
        throw Exception(loginResponse.message ?? "Password salah.");
      }

      // 2. Simpan Credentials & PIN secara aman
      await _biometricService.saveCredentials(
        _username!,
        _passwordController.text,
      );
      await _biometricService.savePin(_pinController.text);

      // 3. Cek Biometric
      final canCheckBiometric = await _biometricService.isBiometricAvailable();

      if (canCheckBiometric) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
      } else {
        // If no biometric hardware, finish setup
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN berhasil disimpan')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceFirst("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal setup: $errorMsg'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    try {
      final authenticated =
          await _biometricService.authenticateWithBiometrics();

      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Biometrik diaktifkan')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal verifikasi biometrik')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _skipBiometric() async {
    await _biometricService.setBiometricEnabled(false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 1 ? 'Buat PIN Keamanan' : 'Aktifkan Biometrik',
          style: GoogleFonts.lexendDeca(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _currentStep == 1 ? _buildPinForm() : _buildBiometricSetup(),
        ),
      ),
    );
  }

  Widget _buildPinForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masukkan password akun Anda dan buat PIN 6 digit untuk keamanan tambahan.',
          style: AppTheme.textThemeLight.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Password Field
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password Akun',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed:
                  () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // PIN Field
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !_isPinVisible,
          decoration: InputDecoration(
            labelText: 'PIN Baru',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPinVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _isPinVisible = !_isPinVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm PIN Field
        TextField(
          controller: _confirmPinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !_isConfirmPinVisible,
          decoration: InputDecoration(
            labelText: 'Konfirmasi PIN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPinVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed:
                  () => setState(
                    () => _isConfirmPinVisible = !_isConfirmPinVisible,
                  ),
            ),
          ),
        ),
        const Spacer(),

        ElevatedButton(
          onPressed: _isLoading ? null : _savePin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : const Text(
                    'Simpan PIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildBiometricSetup() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fingerprint, size: 80, color: AppColors.primaryLight),
        const SizedBox(height: 24),
        Text(
          'Aktifkan Login Biometrik?',
          style: AppTheme.textThemeLight.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Gunakan sidik jari atau wajah untuk login lebih cepat dan aman.',
          style: AppTheme.textThemeLight.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _enableBiometric,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aktifkan Sekarang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _skipBiometric,
          child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
