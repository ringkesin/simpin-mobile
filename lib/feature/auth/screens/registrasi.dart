import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../../service/api_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:file_selector/file_selector.dart';
import '../../../theme.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart'; // Tambahkan ini
import 'camera_screen.dart'; // Tambahkan ini (sesuaikan path jika perlu)

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  List<Map<String, dynamic>> _units = [];
  List<CameraDescription> _cameras = []; // Untuk menyimpan list kamera
  String? _selectedUnit;

  // Controller for date of birth text field
  final TextEditingController _dobController = TextEditingController();
  // Controller for department field
  final TextEditingController _departmentController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
    _initializeCameras(); // Panggil fungsi inisialisasi kamera
  }

  // Fungsi baru untuk inisialisasi kamera
  Future<void> _initializeCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding siap
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Error initializing cameras: ${e.code}, ${e.description}');
      // Handle error, mungkin tampilkan pesan ke user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat mengakses kamera: ${e.description}'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _departmentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Method to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(
            Duration(days: 365 * 18),
          ), // Default 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, // Button text color
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

  void _pickDocument(Function(XFile?) callback, {int maxSizeInMB = 2}) async {
    final typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'doc', 'docx'],
      uniformTypeIdentifiers: [
        'com.adobe.pdf', // PDF
        'com.microsoft.word.doc', // DOC
        'org.openxmlformats.wordprocessingml.document', // DOCX
      ],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      // Cek ukuran file
      final fileSize =
          await file.length(); // Mendapatkan ukuran file dalam bytes
      final fileSizeInMB = fileSize / (1024 * 1024); // Konversi ke MB

      if (fileSizeInMB <= maxSizeInMB) {
        // File ukurannya valid, lanjutkan
        callback(file);
      } else {
        // File terlalu besar, tampilkan pesan error
        callback(null); // Reset file yang dipilih (opsional)

        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ukuran file melebihi $maxSizeInMB MB. Silakan pilih file yang lebih kecil.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getUnitNameById(String? id) {
    if (id == null || id.isEmpty) return "";

    final unit = _units.firstWhere(
      (unit) => unit['id'].toString() == id,
      orElse: () => {'unit_name': ''},
    );

    return unit['unit_name'].toString();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    }
  }

  Future<void> _fetchUnits() async {
    List<Map<String, dynamic>> units = await ApiService.getUnit();
    print("Fetched units: $units"); // Debugging
    setState(() {
      _units = units;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
        ),
        title: Text(
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
              selectedColor: Colors.green,
              unselectedColor: Colors.grey[300]!,
              roundedEdges: Radius.circular(10),
            ),
            SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [_stepOne(), _stepTwo(), _stepThree()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required XFile? file,
    required VoidCallback onPick,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Colors.green, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.name : 'Pilih file',
                    style: TextStyle(
                      color: file != null ? Colors.black87 : Colors.grey[600],
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 2),
          child: Text(
            "Maks. ukuran file 2MB",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "File berhasil dipilih",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        SizedBox(height: 16),
      ],
    );
  }

  XFile? _ktpImageFile; // Ganti dengan ini
  XFile? _idCardImageFile; // Ganti nama variabel kedua juga agar konsisten

  Widget _stepOne() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildTextField("Full Name"),
          _buildTextField(
            "Email Address",
            keyboardType: TextInputType.emailAddress,
          ),
          _buildTextField("Phone Number", keyboardType: TextInputType.phone),

          // Date of Birth field
          _buildDatePicker(
            "Date of Birth",
            _dobController,
            onTap: () => _selectDate(context),
          ),

          SizedBox(height: 24),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _stepTwo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Employee Information",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildTextField("Employee ID"),
          SizedBox(height: 8),
          _buildDepartmentSelect(),
          SizedBox(height: 8),
          _buildTextField(
            "Nomor KTP",
            keyboardType: TextInputType.number,
          ), // Gunakan number
          SizedBox(height: 8),

          // --- Ganti File Picker KTP dengan Camera Input ---
          _buildCameraInput(
            label: "Ambil Foto KTP",
            iconData: Icons.camera_alt, // Icon kamera
            file: _ktpImageFile,
            onPick: () async {
              if (_cameras.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kamera tidak tersedia atau izin ditolak.'),
                  ),
                );
                return;
              }
              // Navigasi ke CameraScreen dan tunggu hasilnya (XFile)
              final result = await Navigator.push<XFile?>(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(cameras: _cameras),
                ),
              );

              // Jika user mengambil gambar (result tidak null)
              if (result != null) {
                setState(() {
                  _ktpImageFile = result;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Foto KTP berhasil diambil: ${result.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),

          // --- Akhir Ganti File Picker KTP ---
          SizedBox(height: 8),

          // --- Tetap Gunakan File Picker untuk ID Card ---
          // (Atau ubah menjadi _buildCameraInput jika ID Card juga pakai kamera)
          _buildFilePicker(
            label: "Upload Foto ID Card",
            file: _idCardImageFile, // Pastikan nama variabel ini benar
            onPick: () {
              _pickDocument((file) {
                setState(() {
                  _idCardImageFile = file; // Update state untuk ID Card
                });
              }, maxSizeInMB: 2);
            },
          ),

          // --- Akhir File Picker ID Card ---
          SizedBox(height: 24), // Beri jarak sebelum tombol navigasi
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // Department selection with matching styling
  Widget _buildDepartmentSelect() {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Colors.grey[300];

    // Update department controller when selected unit changes
    if (_selectedUnit != null) {
      _departmentController.text = _getUnitNameById(_selectedUnit);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TypeAheadFormField<Map<String, dynamic>>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _departmentController,
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Select Department',
            labelStyle: textTheme.labelMedium,
            hintText: 'Search or select department',
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
              borderSide: BorderSide(color: borderColor!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            prefixIcon: Icon(Icons.business, size: 20),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
        ),
        suggestionsCallback: (pattern) {
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              suggestion['unit_name'].toString(),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(Icons.domain, color: Colors.green),
            ),
          );
        },
        onSuggestionSelected: (suggestion) {
          setState(() {
            _selectedUnit = suggestion['id'].toString();
            _departmentController.text = suggestion['unit_name'].toString();
          });
        },
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          borderRadius: BorderRadius.circular(8),
          elevation: 8.0,
          shadowColor: Colors.black26,
          constraints: BoxConstraints(maxHeight: 300),
        ),
        hideSuggestionsOnKeyboardHide: false,
        noItemsFoundBuilder:
            (context) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'No departments found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        loadingBuilder:
            (context) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading departments...'),
                ],
              ),
            ),
      ),
    );
  }

  Widget _stepThree() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 80),
        SizedBox(height: 16),
        Text(
          "Registration Completed!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Aksi setelah registrasi selesai
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Finish",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Date picker widget
  Widget _buildDatePicker(
    String label,
    TextEditingController controller, {
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
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
            borderSide: BorderSide(color: borderColor!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          prefixIcon: Icon(Icons.calendar_today, size: 20),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor =
        Colors.grey[300]; // Sama dengan warna di _buildFilePicker

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        keyboardType: keyboardType,
        style: textTheme.bodyMedium,
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
            borderSide: BorderSide(color: borderColor!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
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
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Next",
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(iconData, color: Colors.green, size: 22), // Icon Kamera
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.name : 'Ambil Foto', // Teks tombol
                    style: TextStyle(
                      color: file != null ? Colors.black87 : Colors.grey[600],
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  Icon(
                    // Ganti IconButton dengan Icon saja
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        // Hapus info ukuran file, karena kamera biasanya mengompres
        // Padding( ... ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              "Foto berhasil diambil",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        SizedBox(height: 16),
      ],
    );
  }
}
