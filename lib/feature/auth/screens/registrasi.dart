// feature/register/screens/register_screen.dart

import 'dart:io'; // Tidak secara langsung digunakan di sini, tapi CameraScreen mungkin membutuhkannya
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Meskipun tidak digunakan langsung di sini, ApiService mungkin butuh
import 'package:image_picker/image_picker.dart'; // Untuk XFile dari CameraScreen

// !! PENTING: GANTI PATH DAN NAMA FILE IMPORT INI !!
// Pastikan path ini benar dan file model berisi:
// ProfileResponseComplex, ProfileUser, ProfileAnggota (jika respons registrasi mengembalikannya)
// Jika model registrasi berbeda, buat dan impor model yang sesuai.
// Untuk contoh ini, kita asumsikan ApiService.registerUser mengembalikan Map<String, dynamic>
// dan tidak langsung menggunakan ProfileResponseComplex untuk registrasi.
// import '../../../model/profile_complex_model.dart'; // Jika respons registrasi menggunakan model ini

import '../../../service/api_service.dart';
import '../../../theme.dart'; // Pastikan AppColors dan AppTheme.textThemeLight ada
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart'; // Pastikan path ini benar
import 'package:permission_handler/permission_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  List<Map<String, dynamic>> _units = [];
  List<CameraDescription> _cameras = [];
  String? _selectedUnitId; // Menyimpan ID unit sebagai String

  // --- Controllers untuk Step 1 ---
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _tempatLahirController =
      TextEditingController(); // BARU

  // --- Controllers dan State untuk Step 2 ---
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _nomorKtpController = TextEditingController();
  final TextEditingController _alamatController =
      TextEditingController(); // BARU

  XFile? _ktpImageFile;
  XFile? _kartuPegawaiImageFile;

  // --- State untuk proses registrasi ---
  bool _isRegistering = false;

  final GlobalKey<FormState> _formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyStep2 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUnits();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Error initializing cameras: ${e.code}, ${e.description}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat mengakses kamera: ${e.description}'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _dobController.dispose();
    _tempatLahirController.dispose(); // BARU
    _employeeIdController.dispose();
    _departmentController.dispose();
    _nomorKtpController.dispose();
    _alamatController.dispose(); // BARU
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  String _getUnitNameById(String? id) {
    if (id == null || id.isEmpty || _units.isEmpty) return "";
    final unit = _units.firstWhere(
      (unit) => unit['id'].toString() == id,
      orElse: () => {'unit_name': ''},
    );
    return unit['unit_name'].toString();
  }

  void _proceedToNextStepPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _nextStepAction() {
    if (_currentStep == 1) {
      if (_formKeyStep1.currentState?.validate() ?? false) {
        _proceedToNextStepPage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Harap lengkapi semua field yang wajib diisi di Langkah 1.',
            ),
          ),
        );
      }
    } else if (_currentStep == 2) {
      if (_formKeyStep2.currentState?.validate() ?? false) {
        if (_ktpImageFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto KTP wajib diunggah.')),
          );
          return;
        }
        if (_kartuPegawaiImageFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto Kartu Pegawai wajib diunggah.')),
          );
          return;
        }
        _handleRegister();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Harap lengkapi semua field yang wajib diisi di Langkah 2.',
            ),
          ),
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUnits() async {
    try {
      List<Map<String, dynamic>> units = await ApiService.getUnit();
      print("Fetched units: $units");
      if (mounted) {
        setState(() {
          _units = units;
        });
      }
    } catch (e) {
      print("Error fetching units: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data unit: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    // Validasi ulang form untuk langkah saat ini (Langkah 2)
    if (!(_formKeyStep2.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data di Langkah 2 dengan benar.'),
        ),
      );
      return;
    }
    // Validasi file sudah ada (sebenarnya sudah divalidasi di _nextStepAction)
    if (_ktpImageFile == null || _kartuPegawaiImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto KTP dan Kartu Pegawai wajib diunggah.'),
        ),
      );
      return;
    }
    if (_selectedUnitId == null || _selectedUnitId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departemen wajib dipilih.')),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      String formattedDob = "";
      if (_selectedDate != null) {
        formattedDob = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      } else {
        throw Exception(
          "Tanggal lahir wajib diisi.",
        ); // Seharusnya sudah dicegah validator
      }

      int? unitId = int.tryParse(_selectedUnitId!);
      if (unitId == null) {
        throw Exception(
          "ID Unit tidak valid.",
        ); // Seharusnya sudah dicegah validator
      }

      final Map<String, dynamic> response = await ApiService.registerUser(
        nama: _fullNameController.text,
        alamatEmail: _emailController.text,
        nomorHp: _phoneNumberController.text,
        nomorPegawai: _employeeIdController.text,
        nomorKtp: _nomorKtpController.text,
        tanggalLahir: formattedDob,
        pUnitId: unitId,
        tempatLahir:
            _tempatLahirController.text.isNotEmpty
                ? _tempatLahirController.text
                : null,
        alamat:
            _alamatController.text.isNotEmpty ? _alamatController.text : null,
        attachmentKtpFile: _ktpImageFile,
        attachmentKartuPegawaiFile: _kartuPegawaiImageFile,
        // Jika ada password, tambahkan di sini
        // password: _passwordController.text,
        // passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Registrasi berhasil! Silakan login.',
              ),
              backgroundColor: AppColors.successLight,
            ),
          );
          _proceedToNextStepPage(); // Lanjut ke halaman konfirmasi (Step 3)
        } else {
          // Menampilkan pesan error dari server jika ada, atau pesan default
          String errorMessage = response['message'] ?? 'Registrasi gagal.';
          if (response['data'] != null && response['data']['error'] is Map) {
            // Jika ada detail error per field
            Map<String, dynamic> errors = response['data']['error'];
            String details = errors.entries
                .map(
                  (entry) =>
                      '${entry.key}: ${(entry.value as List).join(', ')}',
                )
                .join('\n');
            errorMessage += '\nDetail:\n$details';
          }
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Exception
                  ? e.toString().replaceFirst("Exception: ", "")
                  : 'Terjadi kesalahan saat registrasi.',
            ),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
        ),
        title: const Text(
          "Register",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            StepProgressIndicator(
              totalSteps: 3,
              currentStep: _currentStep,
              size: 6,
              selectedColor: AppColors.primaryLight,
              unselectedColor: Colors.grey[300]!,
              roundedEdges: const Radius.circular(10),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_stepOne(), _stepTwo(), _stepThree()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepOne() {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informasi Pribadi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: "Nama Lengkap",
              controller: _fullNameController,
              validator:
                  (value) =>
                      (value?.isEmpty ?? true)
                          ? 'Nama lengkap tidak boleh kosong.'
                          : null,
            ),
            _buildTextField(
              label: "Alamat Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Alamat email tidak boleh kosong.';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!))
                  return 'Format email tidak valid.';
                return null;
              },
            ),
            _buildTextField(
              label: "Nomor HP",
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              validator:
                  (value) =>
                      (value?.isEmpty ?? true)
                          ? 'Nomor HP tidak boleh kosong.'
                          : null,
            ),
            _buildTextField(
              // BARU: Tempat Lahir
              label: "Tempat Lahir (Opsional)",
              controller: _tempatLahirController,
            ),
            _buildDatePicker(
              label: "Tanggal Lahir",
              controller: _dobController,
              onTap: () => _selectDate(context),
              validator:
                  (value) =>
                      (value?.isEmpty ?? true)
                          ? 'Tanggal lahir tidak boleh kosong.'
                          : null,
            ),
            const SizedBox(height: 24),
            _buildNextButton(onPressed: _nextStepAction),
          ],
        ),
      ),
    );
  }

  Widget _stepTwo() {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informasi Kepegawaian & Dokumen",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: "Nomor Pegawai",
              controller: _employeeIdController,
              validator:
                  (value) =>
                      (value?.isEmpty ?? true)
                          ? 'Nomor Pegawai tidak boleh kosong.'
                          : null,
            ),
            _buildDepartmentSelect(
              validator:
                  (value) =>
                      (_selectedUnitId == null || _selectedUnitId!.isEmpty)
                          ? 'Departemen wajib dipilih.'
                          : null,
            ),
            _buildTextField(
              // BARU: Alamat
              label: "Alamat Lengkap (Opsional)",
              controller: _alamatController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
            _buildTextField(
              label: "Nomor KTP",
              controller: _nomorKtpController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Nomor KTP tidak boleh kosong.';
                if (value!.length != 16) return 'Nomor KTP harus 16 digit.';
                return null;
              },
            ),
            _buildCameraInput(
              label: "Foto KTP",
              iconData: Icons.credit_card_outlined,
              file: _ktpImageFile,
              onPick: () async {
                PermissionStatus status = await Permission.camera.status;
                if (!status.isGranted && !status.isPermanentlyDenied) {
                  status = await Permission.camera.request();
                }
                if (!status.isGranted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        status.isPermanentlyDenied
                            ? 'Izin kamera ditolak permanen. Aktifkan di Pengaturan.'
                            : 'Izin kamera dibutuhkan.',
                      ),
                    ),
                  );
                  if (status.isPermanentlyDenied) openAppSettings();
                  return;
                }
                if (_cameras.isEmpty) {
                  await _initializeCameras();
                  if (_cameras.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamera tidak tersedia.')),
                    );
                    return;
                  }
                }
                final result = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(cameras: _cameras),
                  ),
                );
                if (result != null) setState(() => _ktpImageFile = result);
              },
            ),
            _buildCameraInput(
              label: "Foto Kartu Pegawai",
              iconData: Icons.badge_outlined,
              file: _kartuPegawaiImageFile,
              onPick: () async {
                PermissionStatus status = await Permission.camera.status;
                if (!status.isGranted && !status.isPermanentlyDenied) {
                  status = await Permission.camera.request();
                }
                if (!status.isGranted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        status.isPermanentlyDenied
                            ? 'Izin kamera ditolak permanen. Aktifkan di Pengaturan.'
                            : 'Izin kamera dibutuhkan.',
                      ),
                    ),
                  );
                  if (status.isPermanentlyDenied) openAppSettings();
                  return;
                }
                if (_cameras.isEmpty) {
                  await _initializeCameras();
                  if (_cameras.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamera tidak tersedia.')),
                    );
                    return;
                  }
                }
                final result = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(cameras: _cameras),
                  ),
                );
                if (result != null)
                  setState(() => _kartuPegawaiImageFile = result);
              },
            ),
            const SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSelect({String? Function(String?)? validator}) {
    // Validator diubah ke String?
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = AppColors.primaryLight; // Menggunakan AppColors
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TypeAheadFormField<Map<String, dynamic>>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _departmentController,
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Pilih Departemen/Unit',
            labelStyle: textTheme.labelMedium,
            hintText: 'Ketik untuk mencari departemen',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            prefixIcon: const Icon(Icons.business, size: 20),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
        ),
        suggestionsCallback: (pattern) {
          if (_units.isEmpty && pattern.isNotEmpty)
            return Future.value([]); // Hindari error jika _units kosong
          return _units
              .where(
                (unit) => unit['unit_name'].toString().toLowerCase().contains(
                  pattern.toLowerCase(),
                ),
              )
              .toList();
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              suggestion['unit_name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.domain, color: primaryColor),
            ),
          );
        },
        onSuggestionSelected: (suggestion) {
          setState(() {
            _selectedUnitId = suggestion['id'].toString(); // Simpan ID unit
            _departmentController.text = suggestion['unit_name'].toString();
          });
        },
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          borderRadius: BorderRadius.circular(8),
          elevation: 4.0, // Mengurangi elevation
          shadowColor: Colors.black12, // Mengurangi shadow
          constraints: const BoxConstraints(
            maxHeight: 250,
          ), // Mengurangi maxHeight
        ),
        hideSuggestionsOnKeyboardHide: true, // Diubah ke true
        noItemsFoundBuilder:
            (context) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Departemen tidak ditemukan.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        loadingBuilder:
            (context) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Memuat...'),
                ],
              ),
            ),
        validator: validator, // Menggunakan validator dari parameter
      ),
    );
  }

  Widget _stepThree() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: AppColors.successLight, size: 80),
        const SizedBox(height: 16),
        const Text(
          "Registrasi Selesai!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Akun Anda telah berhasil dibuat. Silakan login.",
          textAlign: TextAlign.center,
          style: AppTheme.textThemeLight.bodyMedium,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (Route<dynamic> route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Kembali ke Login",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = AppColors.primaryLight;
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        // Diubah menjadi TextFormField untuk validasi
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.labelMedium,
          hintText: "DD-MM-YYYY",
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        validator: validator, // Menggunakan validator dari parameter
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = AppColors.primaryLight;
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        // Diubah menjadi TextFormField untuk validasi
        controller: controller,
        keyboardType: keyboardType,
        style: textTheme.bodyMedium,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.labelMedium,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: validator, // Menggunakan validator dari parameter
      ),
    );
  }

  Widget _buildNextButton({required VoidCallback onPressed}) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Next",
          style: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _prevStep,
          child: Text(
            "Back",
            style: textTheme.titleSmall?.copyWith(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _isRegistering ? null : _nextStepAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isRegistering
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    _currentStep == 2 ? "Register" : "Next",
                    style: textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
        ),
      ],
    );
  }

  Widget _buildCameraInput({
    required XFile? file,
    required VoidCallback onPick,
    required String label,
    required IconData iconData,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(iconData, color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.name : 'Ambil Foto',
                    style: TextStyle(
                      color: file != null ? Colors.black87 : Colors.grey[600],
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.successLight,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              "Foto berhasil diambil",
              style: TextStyle(fontSize: 12, color: AppColors.successLight),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
