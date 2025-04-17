// screens/form_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../../service/api_service.dart';
import '../../../model/jenis_pinjaman.dart';
import '../../../model/keperluan_pinjaman.dart';

class FormWizardScreen extends StatefulWidget {
  const FormWizardScreen({Key? key}) : super(key: key);

  @override
  _FormWizardScreenState createState() => _FormWizardScreenState();
}

class _FormWizardScreenState extends State<FormWizardScreen> {
  // Current step index
  int _currentStep = 0;

  // Form keys for validation
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Form data - Step 1
  int? _selectedJenisPinjaman;
  Map<int, bool> _selectedKeperluan = {};
  final _jenisBarangController = TextEditingController();
  final _merkTypeController = TextEditingController();
  final _hargaController = TextEditingController();
  final _tenorCicilanController = TextEditingController();
  Set<int> _selectedKeperluanIds = {};

  // Form data - Step 2
  final _jenisJaminanController = TextEditingController();
  final _keteranganJaminanController = TextEditingController();
  final _perkiraanNilaiController = TextEditingController();

  // Form data - Step 3
  String? _ktpPemohon;
  String? _ktpPasangan;
  String? _kartuKeluarga;
  String? _idCard;
  String? _slipGaji;

  // API data
  List<JenisPinjamanModel> _jenisPinjamanList = [];
  List<KeperluanPinjamanModel> _keperluanPinjamanList = [];
  bool _isLoading = false;

  // API service
  final ApiService _apiService = ApiService();

  // Page controller for step navigation
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchJenisPinjaman();
  }

  @override
  void dispose() {
    // Clean up controllers
    _jenisBarangController.dispose();
    _merkTypeController.dispose();
    _hargaController.dispose();
    _tenorCicilanController.dispose();
    _jenisJaminanController.dispose();
    _keteranganJaminanController.dispose();
    _perkiraanNilaiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Fetch Jenis Pinjaman from API
  Future<void> _fetchJenisPinjaman() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getMasterJenisPinjaman();
      setState(() {
        _jenisPinjamanList = data;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load jenis pinjaman: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch Keperluan Pinjaman from API
  Future<void> _fetchKeperluanPinjaman() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getMasterKeperluanPinjaman();
      setState(() {
        _keperluanPinjamanList = data;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load keperluan pinjaman: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle jenis pinjaman selection
  void _onJenisPinjamanChanged(int? value) {
    setState(() {
      _selectedJenisPinjaman = value;
      _selectedKeperluan.clear(); // Reset keperluan selections

      // Clear barang fields if switching from pinjaman barang
      if (value != 3) {
        _jenisBarangController.clear();
        _merkTypeController.clear();
      }

      if (value == 1 || value == 2) {
        _fetchKeperluanPinjaman();
      }
    });
  }

  // Pick PDF file helper
  Future<String?> _pickPdfFile(String title) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Pilih $title',
      );

      if (result != null) {
        return result.files.single.path;
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: $e');
    }
    return null;
  }

  // Validate steps and moving between them
  bool _validateStep1() {
    if (_formKeyStep1.currentState?.validate() ?? false) {
      // For pinjaman umum/khusus, check if at least one keperluan is selected
      if ((_selectedJenisPinjaman == 1 || _selectedJenisPinjaman == 2) &&
          !_selectedKeperluan.values.contains(true)) {
        _showErrorSnackBar('Pilih minimal satu keperluan pinjaman');
        return false;
      }
      return true;
    }
    return false;
  }

  bool _validateStep2() {
    return _formKeyStep2.currentState?.validate() ?? false;
  }

  bool _validateStep3() {
    if (_formKeyStep3.currentState?.validate() ?? false) {
      // Check if all required files are selected
      if (_ktpPemohon == null ||
          _kartuKeluarga == null ||
          _idCard == null ||
          _slipGaji == null) {
        _showErrorSnackBar(
          'Semua dokumen wajib dipilih kecuali KTP suami/istri',
        );
        return false;
      }
      return true;
    }
    return false;
  }

  void _nextStep() {
    bool canContinue = false;

    if (_currentStep == 0) {
      canContinue = _validateStep1();
    } else if (_currentStep == 1) {
      canContinue = _validateStep2();
    } else if (_currentStep == 2) {
      canContinue = _validateStep3();
      if (canContinue) {
        _submitForm();
        return;
      }
    }

    if (canContinue && _currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // When submitting the form
  void _submitForm() {
    // Get all selected keperluan IDs
    List<int> selectedKeperluanIds = _selectedKeperluanIds.toList();

    // Create a Map to hold your form data
    Map<String, dynamic> formData = {
      "p_anggota_id": 1276, // Use your actual value
      "p_jenis_pinjaman_id": _selectedJenisPinjaman,
      "tenor": _tenorCicilanController.text,
      "ra_jumlah_pinjaman": _hargaController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      ),
      "jaminan": _jenisJaminanController.text,
      "jaminan_keterangan": _keteranganJaminanController.text,
      "jaminan_perkiraan_nilai": _perkiraanNilaiController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      ),
      // Add other form fields...
    };

    // Add the keperluan IDs with indexed keys
    for (int i = 0; i < selectedKeperluanIds.length; i++) {
      formData["p_pinjaman_keperluan_ids[$i]"] =
          selectedKeperluanIds[i].toString();
    }

    // Now you can send formData to your API
    print("Sending form data: $formData");
    // _apiService.submitForm(formData);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengajuan pinjaman berhasil dikirim'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Form Pengajuan Pinjaman',
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
              currentStep: _currentStep + 1,
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
                children: [
                  _buildStep1Content(),
                  _buildStep2Content(),
                  _buildStep3Content(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Data Pinjaman
  Widget _buildStep1Content() {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pinjaman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Jenis Pinjaman Dropdown
            _buildDropdown(
              value: _selectedJenisPinjaman,
              items:
                  _jenisPinjamanList.map((jenis) {
                    return DropdownMenuItem<int>(
                      value: jenis.id,
                      child: Text(jenis.nama),
                    );
                  }).toList(),
              onChanged: _onJenisPinjamanChanged,
              labelText: 'Jenis Pinjaman',
              hintText: 'Pilih jenis pinjaman',
              icon: Icons.account_balance_wallet,
              validator: (value) {
                if (value == null) {
                  return 'Pilih jenis pinjaman';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Dynamic content based on jenis pinjaman selection
            if (_selectedJenisPinjaman == 1 || _selectedJenisPinjaman == 2)
              _buildKeperluanPinjamanCheckboxes()
            else if (_selectedJenisPinjaman == 3)
              _buildBarangInputs(),

            if (_selectedJenisPinjaman != null) ...[
              const SizedBox(height: 20),

              // Harga input
              _buildTextField(
                controller: _hargaController,
                labelText: 'Harga (Rp)',
                hintText: 'Masukkan harga',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                icon: Icons.monetization_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan harga';
                  }
                  if (int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ==
                      null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tenor cicilan input
              _buildTextField(
                controller: _tenorCicilanController,
                labelText: 'Tenor Cicilan (bulan)',
                hintText: 'Masukkan tenor',
                suffixText: 'bulan',
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan tenor cicilan';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),
              _buildNextButton(),
            ],
          ],
        ),
      ),
    );
  }

  // Keperluan Pinjaman checkboxes for Step 1
  Widget _buildKeperluanPinjamanCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keperluan Pinjaman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          Center(child: CircularProgressIndicator(color: Colors.green))
        else if (_keperluanPinjamanList.isEmpty)
          Text('Tidak ada data keperluan pinjaman'),
        ...List.generate(_keperluanPinjamanList.length, (index) {
          final keperluan = _keperluanPinjamanList[index];
          // Make sure we have a unique ID for each keperluan
          int keperluanId =
              keperluan.id ?? index; // Use index as fallback if id is null

          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                keperluan.nama ?? 'Default Title',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              // Check if THIS SPECIFIC keperluanId is in the set
              value: _selectedKeperluanIds.contains(keperluanId),
              onChanged: (bool? value) {
                // Debug before state change
                print("Before change - selected IDs: $_selectedKeperluanIds");
                print("Toggling ID: $keperluanId to ${value == true}");

                setState(() {
                  if (value == true) {
                    _selectedKeperluanIds.add(keperluanId);
                  } else {
                    _selectedKeperluanIds.remove(keperluanId);
                  }
                });

                // Debug after state change
                print("After change - selected IDs: $_selectedKeperluanIds");
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.green,
              checkColor: Colors.white,
              dense: true,
            ),
          );
        }),
      ],
    );
  }

  // Barang inputs for Step 1
  Widget _buildBarangInputs() {
    return Column(
      children: [
        _buildTextField(
          controller: _jenisBarangController,
          labelText: 'Jenis Barang',
          hintText: 'Masukkan jenis barang',
          icon: Icons.category,
          validator: (value) {
            if (_selectedJenisPinjaman == 3 &&
                (value == null || value.isEmpty)) {
              return 'Masukkan jenis barang';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _merkTypeController,
          labelText: 'Merk/Type',
          hintText: 'Masukkan merk/type',
          icon: Icons.branding_watermark,
          validator: (value) {
            if (_selectedJenisPinjaman == 3 &&
                (value == null || value.isEmpty)) {
              return 'Masukkan merk/type';
            }
            return null;
          },
        ),
      ],
    );
  }

  // STEP 2: Jaminan
  Widget _buildStep2Content() {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Jaminan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Jenis Jaminan input
            _buildTextField(
              controller: _jenisJaminanController,
              labelText: 'Jenis Jaminan',
              hintText: 'Contoh: Sertifikat Rumah, BPKB, dll',
              icon: Icons.security,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jenis jaminan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Keterangan Jaminan input
            _buildTextField(
              controller: _keteranganJaminanController,
              labelText: 'Keterangan Jaminan',
              hintText: 'Detail informasi terkait jaminan',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan keterangan jaminan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Perkiraan Nilai input
            _buildTextField(
              controller: _perkiraanNilaiController,
              labelText: 'Perkiraan Nilai (Rp)',
              hintText: 'Masukkan perkiraan nilai',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              icon: Icons.monetization_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan perkiraan nilai';
                }
                if (int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ==
                    null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),

            SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // STEP 3: Dokumen
  Widget _buildStep3Content() {
    return Form(
      key: _formKeyStep3,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dokumen Pendukung',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload semua dokumen dalam format PDF',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // KTP Pemohon
            _buildDocumentUploadField(
              'KTP Pemohon',
              _ktpPemohon,
              (value) => setState(() => _ktpPemohon = value),
              true,
            ),

            // KTP Suami/Istri
            _buildDocumentUploadField(
              'KTP Suami/Istri',
              _ktpPasangan,
              (value) => setState(() => _ktpPasangan = value),
              false,
            ),

            // Kartu Keluarga
            _buildDocumentUploadField(
              'Kartu Keluarga',
              _kartuKeluarga,
              (value) => setState(() => _kartuKeluarga = value),
              true,
            ),

            // ID Card
            _buildDocumentUploadField(
              'ID Card',
              _idCard,
              (value) => setState(() => _idCard = value),
              true,
            ),

            // Slip Gaji Terakhir
            _buildDocumentUploadField(
              'Slip Gaji Terakhir',
              _slipGaji,
              (value) => setState(() => _slipGaji = value),
              true,
            ),

            SizedBox(height: 24),
            _buildNavigationButtons(isLastStep: true),
          ],
        ),
      ),
    );
  }

  // Document upload field builder - updated with RegisterScreen styling
  Widget _buildDocumentUploadField(
    String label,
    String? value,
    Function(String?) onChanged,
    bool isRequired,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FormField<String>(
        initialValue: value,
        validator: (val) {
          if (isRequired && (val == null || val.isEmpty)) {
            return '$label wajib diupload';
          }
          return null;
        },
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRequired ? '$label *' : label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final path = await _pickPdfFile(label);
                  if (path != null) {
                    onChanged(path);
                    state.didChange(path);
                  }
                },
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
                          value != null ? value.split('/').last : 'Pilih file',
                          style: TextStyle(
                            color:
                                value != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (value != null)
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
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
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (value != null && !state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "File berhasil dipilih",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Common TextField widget with styling from RegisterScreen
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
    String? suffixText,
    IconData? icon,
    int maxLines = 1,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Colors.green;
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: textTheme.labelMedium,
          prefixText: prefixText,
          suffixText: suffixText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        ),
        validator: validator,
      ),
    );
  }

  // Custom dropdown with styling that matches RegisterScreen
  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String labelText,
    String? hintText,
    IconData? icon,
    String? Function(T?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Colors.green;
    final borderColor = Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        icon: SizedBox.shrink(),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  // Next button matching RegisterScreen styling
  Widget _buildNextButton() {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
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

  // Navigation buttons row matching RegisterScreen styling
  Widget _buildNavigationButtons({bool isLastStep = false}) {
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
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isLastStep ? "Submit" : "Next",
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
