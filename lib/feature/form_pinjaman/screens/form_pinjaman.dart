// screens/form_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  void _submitForm() {
    // Here you would implement the API call to submit the form data
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengajuan pinjaman berhasil dikirim'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );

    // Optional: Navigate back or to a confirmation screen
    // Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Pengajuan Pinjaman')),
      body:
          _isLoading && _jenisPinjamanList.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  bool isLastStep = _currentStep == 2;

                  if (isLastStep) {
                    if (_validateStep3()) {
                      _submitForm();
                    }
                  } else {
                    bool canContinue = false;

                    if (_currentStep == 0) {
                      canContinue = _validateStep1();
                    } else if (_currentStep == 1) {
                      canContinue = _validateStep2();
                    }

                    if (canContinue) {
                      setState(() {
                        _currentStep += 1;
                      });
                    }
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep -= 1;
                    });
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(_currentStep == 2 ? 'Submit' : 'Lanjut'),
                        ),
                        if (_currentStep > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: TextButton(
                              onPressed: details.onStepCancel,
                              child: Text('Kembali'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: Text('Data Pinjaman'),
                    content: _buildStep1Content(),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: Text('Jaminan'),
                    content: _buildStep2Content(),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: Text('Dokumen'),
                    content: _buildStep3Content(),
                    isActive: _currentStep >= 2,
                  ),
                ],
              ),
    );
  }

  // STEP 1: Data Pinjaman
  Widget _buildStep1Content() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pinjaman',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Jenis Pinjaman Dropdown
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Jenis Pinjaman',
              border: OutlineInputBorder(),
            ),
            value: _selectedJenisPinjaman,
            items:
                _jenisPinjamanList.map((jenis) {
                  return DropdownMenuItem<int>(
                    value: jenis.id,
                    child: Text(jenis.nama),
                  );
                }).toList(),
            onChanged: _onJenisPinjamanChanged,
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
            TextFormField(
              controller: _hargaController,
              decoration: InputDecoration(
                labelText: 'Harga (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
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
            TextFormField(
              controller: _tenorCicilanController,
              decoration: InputDecoration(
                labelText: 'Tenor Cicilan (bulan)',
                border: OutlineInputBorder(),
                suffixText: 'bulan',
              ),
              keyboardType: TextInputType.number,
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
          ],
        ],
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
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_keperluanPinjamanList.isEmpty)
          Text('Tidak ada data keperluan pinjaman'),
        ...List.generate(_keperluanPinjamanList.length, (index) {
          final keperluan = _keperluanPinjamanList[index];
          return CheckboxListTile(
            title: Text(keperluan.nama ?? 'Default Title'),

            value: _selectedKeperluan[keperluan.id] ?? false,
            onChanged: (bool? value) {
              setState(() {
                _selectedKeperluan[keperluan.id ?? 0] = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        }),
      ],
    );
  }

  // Barang inputs for Step 1
  Widget _buildBarangInputs() {
    return Column(
      children: [
        TextFormField(
          controller: _jenisBarangController,
          decoration: InputDecoration(
            labelText: 'Jenis Barang',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_selectedJenisPinjaman == 3 &&
                (value == null || value.isEmpty)) {
              return 'Masukkan jenis barang';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _merkTypeController,
          decoration: InputDecoration(
            labelText: 'Merk/Type',
            border: OutlineInputBorder(),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Jaminan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Jenis Jaminan input
          TextFormField(
            controller: _jenisJaminanController,
            decoration: InputDecoration(
              labelText: 'Jenis Jaminan',
              border: OutlineInputBorder(),
              hintText: 'Contoh: Sertifikat Rumah, BPKB, dll',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan jenis jaminan';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Keterangan Jaminan input
          TextFormField(
            controller: _keteranganJaminanController,
            decoration: InputDecoration(
              labelText: 'Keterangan Jaminan',
              border: OutlineInputBorder(),
              hintText: 'Detail informasi terkait jaminan',
            ),
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
          TextFormField(
            controller: _perkiraanNilaiController,
            decoration: InputDecoration(
              labelText: 'Perkiraan Nilai (Rp)',
              border: OutlineInputBorder(),
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
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
        ],
      ),
    );
  }

  // STEP 3: Dokumen
  Widget _buildStep3Content() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumen Pendukung',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload semua dokumen dalam format PDF',
            style: Theme.of(context).textTheme.bodySmall,
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
        ],
      ),
    );
  }

  // Document upload field builder
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isRequired ? '$label *' : label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final path = await _pickPdfFile(label);
                      if (path != null) {
                        onChanged(path);
                        state.didChange(path);
                      }
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value.split('/').last,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () {
                          onChanged(null);
                          state.didChange(null);
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
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
              Divider(),
            ],
          );
        },
      ),
    );
  }
}
