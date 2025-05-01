// screens/form_wizard_screen.dart
import 'package:flutter/material.dart';
// Import file_picker HANYA JIKA masih digunakan di tempat lain
// import 'package:file_picker/file_picker.dart'; // Hapus jika tidak perlu
import 'package:step_progress_indicator/step_progress_indicator.dart';
// --- Ganti dengan path import yang benar ---
import '../../../service/api_service.dart';
import '../../../model/jenis_pinjaman.dart';
import '../../../model/keperluan_pinjaman.dart';
// -----------------------------------------

class FormWizardScreen extends StatefulWidget {
  const FormWizardScreen({Key? key}) : super(key: key);

  @override
  _FormWizardScreenState createState() => _FormWizardScreenState();
}

class _FormWizardScreenState extends State<FormWizardScreen> {
  // Current step index
  int _currentStep = 0;
  final int _totalSteps = 2; // Total steps sekarang 2

  // Form keys for validation
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  // Hapus key form step 3: final _formKeyStep3 = GlobalKey<FormState>();

  // Form data - Step 1
  int? _selectedJenisPinjaman;
  // Hapus map yang tidak terpakai: Map<int, bool> _selectedKeperluan = {};
  final _jenisBarangController = TextEditingController();
  final _merkTypeController = TextEditingController();
  final _hargaController = TextEditingController();
  final _tenorCicilanController = TextEditingController();
  // Gunakan Set ini untuk menyimpan ID keperluan yang dipilih
  final Set<int> _selectedKeperluanIds = {};

  // Form data - Step 2
  final _jenisJaminanController = TextEditingController();
  final _keteranganJaminanController = TextEditingController();
  final _perkiraanNilaiController = TextEditingController();

  // Hapus state data step 3
  // String? _ktpPemohon;
  // String? _ktpPasangan;
  // String? _kartuKeluarga;
  // String? _idCard;
  // String? _slipGaji;

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

  // Fetch Jenis Pinjaman (Tetap sama)
  Future<void> _fetchJenisPinjaman() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMasterJenisPinjaman();
      setState(() => _jenisPinjamanList = data);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat jenis pinjaman: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fetch Keperluan Pinjaman (Tetap sama)
  Future<void> _fetchKeperluanPinjaman() async {
    if (!mounted) return; // Cek mounted sebelum setState
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMasterKeperluanPinjaman();
      if (!mounted) return; // Cek mounted setelah await
      setState(() => _keperluanPinjamanList = data);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat keperluan pinjaman: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Cek mounted sebelum setState
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Jangan tampilkan jika widget sudah di-dispose
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle jenis pinjaman selection (Tetap sama)
  void _onJenisPinjamanChanged(int? value) {
    setState(() {
      _selectedJenisPinjaman = value;
      _selectedKeperluanIds.clear(); // Reset keperluan ID selections
      _keperluanPinjamanList = []; // Kosongkan list keperluan saat ganti jenis

      if (value != 3) {
        // Clear barang fields jika bukan pinjaman barang
        _jenisBarangController.clear();
        _merkTypeController.clear();
      }

      // Fetch keperluan HANYA jika jenisnya Umum atau Khusus
      if (value == 1 || value == 2) {
        _fetchKeperluanPinjaman();
      }
    });
  }

  // Hapus fungsi pick file PDF
  /*
  Future<String?> _pickPdfFile(String title) async { ... }
  */

  // --- Validasi Steps (DIRUBAH) ---
  bool _validateStep1() {
    if (_formKeyStep1.currentState?.validate() ?? false) {
      // Validasi checkbox: Jika pinjaman umum/khusus, _selectedKeperluanIds tidak boleh kosong
      if ((_selectedJenisPinjaman == 1 || _selectedJenisPinjaman == 2) &&
          _selectedKeperluanIds.isEmpty) {
        // <-- Gunakan _selectedKeperluanIds.isEmpty
        _showErrorSnackBar('Pilih minimal satu keperluan pinjaman');
        return false;
      }
      return true; // Lolos validasi form dan checkbox
    }
    return false; // Gagal validasi form
  }

  bool _validateStep2() {
    return _formKeyStep2.currentState?.validate() ?? false;
  }

  // Hapus validasi step 3
  /*
  bool _validateStep3() { ... }
  */

  // --- Navigasi Steps (DIRUBAH) ---
  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      if (_validateStep2()) {
        // Step terakhir, panggil submit
        _submitForm();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Submit Form (Tetap sama, tidak perlu ubah jika hanya kirim data step 1 & 2)
  void _submitForm() {
    // Pastikan p_anggota_id didapatkan dengan benar, contoh hardcoded
    final pAnggotaId = 1276; // Ganti dengan cara Anda mendapatkan ID Anggota

    List<int> selectedKeperluanIds = _selectedKeperluanIds.toList();

    // Format data untuk dikirim
    Map<String, dynamic> formData = {
      "p_anggota_id": pAnggotaId,
      "p_jenis_pinjaman_id": _selectedJenisPinjaman,
      "tenor": _tenorCicilanController.text,
      // Pastikan membersihkan format Rupiah sebelum mengirim
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
      // Tambahkan field barang jika itu pinjaman barang
      if (_selectedJenisPinjaman == 3) ...{
        "barang_jenis": _jenisBarangController.text,
        "barang_merk": _merkTypeController.text,
      },
    };

    // Tambahkan keperluan IDs jika ada (untuk pinjaman umum/khusus)
    if (_selectedJenisPinjaman == 1 || _selectedJenisPinjaman == 2) {
      for (int i = 0; i < selectedKeperluanIds.length; i++) {
        // Key disesuaikan dengan format yang dibutuhkan API (contoh: array)
        formData["p_pinjaman_keperluan_ids[$i]"] =
            selectedKeperluanIds[i].toString();
        // Atau jika API mengharapkan list langsung:
        // formData["p_pinjaman_keperluan_ids"] = selectedKeperluanIds; // Perlu konfirmasi format API
      }
    }

    // Log data sebelum dikirim (untuk debugging)
    print("Submitting Form Data: $formData");

    // TODO: Implementasi pengiriman data ke API menggunakan _apiService
    // Contoh:
    // try {
    //   setState(() => _isLoading = true);
    //   await _apiService.submitPengajuanPinjaman(formData); // Ganti dengan nama fungsi API Anda
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Pengajuan pinjaman berhasil dikirim'),
    //       backgroundColor: Colors.green,
    //       behavior: SnackBarBehavior.floating,
    //     ),
    //   );
    //   // Navigasi ke halaman sukses atau kembali
    //   Navigator.pop(context);
    // } catch (e) {
    //   _showErrorSnackBar('Gagal mengirim pengajuan: $e');
    // } finally {
    //   if (mounted) setState(() => _isLoading = false);
    // }

    // Placeholder sukses message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengajuan pinjaman akan diproses (simulasi)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Contoh kembali ke halaman sebelumnya setelah submit
    // Future.delayed(Duration(seconds: 1), () {
    //   if (mounted) Navigator.pop(context);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ), // Warna ikon akan diambil dari theme
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Form Pengajuan Pinjaman'), // Style dari theme
        centerTitle: true,
        // backgroundColor, elevation dari theme
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            StepProgressIndicator(
              totalSteps: _totalSteps, // Total steps jadi 2
              currentStep: _currentStep + 1, // currentStep tetap 1-based
              size: 6,
              selectedColor:
                  Colors.green, // Atau Theme.of(context).primaryColor
              unselectedColor: Colors.grey[300]!,
              roundedEdges: const Radius.circular(10),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Tidak bisa swipe antar step
                children: [
                  _buildStep1Content(),
                  _buildStep2Content(),
                  // Hapus step 3 dari children: _buildStep3Content(),
                ],
              ),
            ),
            // Tombol navigasi tidak perlu ditaruh di sini karena
            // sudah ada di dalam buildStep1Content dan buildStep2Content
          ],
        ),
      ),
    );
  }

  // STEP 1: Data Pinjaman (Widget Build - DIRUBAH: hanya tombol Next)
  Widget _buildStep1Content() {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 16,
        ), // Padding bawah untuk tombol
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pinjaman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Jenis Pinjaman Dropdown
            _buildDropdown<int>(
              // Tipe data <int>
              value: _selectedJenisPinjaman,
              items:
                  _jenisPinjamanList.map((jenis) {
                    return DropdownMenuItem<int>(
                      value: jenis.id, // ID sebagai value
                      child: Text(
                        jenis.nama ?? 'Tidak Bernama',
                      ), // Teks yang tampil
                    );
                  }).toList(),
              onChanged: _onJenisPinjamanChanged,
              labelText: 'Jenis Pinjaman',
              hintText: 'Pilih jenis pinjaman',
              icon: Icons.account_balance_wallet_outlined, // Ganti ikon
              validator: (value) {
                if (value == null) return 'Pilih jenis pinjaman';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Konten Dinamis: Keperluan atau Barang
            if (_selectedJenisPinjaman == 1 || _selectedJenisPinjaman == 2)
              _buildKeperluanPinjamanCheckboxes()
            else if (_selectedJenisPinjaman == 3)
              _buildBarangInputs(),

            // Input Harga dan Tenor (muncul jika jenis pinjaman dipilih)
            if (_selectedJenisPinjaman != null) ...[
              const SizedBox(height: 20),
              _buildTextField(
                controller: _hargaController,
                labelText: 'Jumlah Pengajuan (Rp)', // Ganti label
                hintText: 'Masukkan jumlah pengajuan',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                icon: Icons.monetization_on_outlined, // Ganti ikon
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan jumlah pengajuan';
                  }
                  if (int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ==
                      null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tenorCicilanController,
                labelText: 'Tenor Cicilan (bulan)',
                hintText: 'Masukkan tenor',
                suffixText: 'bulan',
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today_outlined, // Ganti ikon
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan tenor cicilan';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  if (int.parse(value) <= 0) return 'Tenor harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Tombol hanya Next di Step 1
              _buildNextButton(),
            ],
          ],
        ),
      ),
    );
  }

  // Keperluan Pinjaman checkboxes (Build Widget - Tidak berubah signifikan)
  Widget _buildKeperluanPinjamanCheckboxes() {
    // Pastikan list tidak null sebelum digunakan
    if (_isLoading && _keperluanPinjamanList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isLoading &&
        _keperluanPinjamanList.isEmpty &&
        _selectedJenisPinjaman != null) {
      return const Text("Tidak ada data keperluan untuk jenis pinjaman ini.");
    }
    if (_keperluanPinjamanList.isEmpty) {
      return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika list kosong
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keperluan Pinjaman *', // Tambah indikator wajib
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          // Beri border luar agar terlihat seperti grup
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(_keperluanPinjamanList.length, (index) {
              final keperluan = _keperluanPinjamanList[index];
              int keperluanId = keperluan.id ?? index; // Fallback ID

              return CheckboxListTile(
                title: Text(
                  keperluan.nama ?? 'Keperluan ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _selectedKeperluanIds.contains(keperluanId),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedKeperluanIds.add(keperluanId);
                    } else {
                      _selectedKeperluanIds.remove(keperluanId);
                    }
                  });
                  // Validate form again implicitly if needed, or rely on Next button validation
                  // _formKeyStep1.currentState?.validate();
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ), // Padding lebih kecil
                controlAffinity: ListTileControlAffinity.leading,
                activeColor:
                    Colors.green, // Atau Theme.of(context).primaryColor
                dense: true,
                // Tambahkan visual divider antar item
                visualDensity: VisualDensity.compact,
                // Beri border bawah untuk setiap item kecuali yang terakhir
                // Jika ingin, uncomment ini dan hapus border Container luar
                //  decoration: BoxDecoration(
                //    border: index < _keperluanPinjamanList.length - 1
                //        ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
                //        : null,
                //  ),
              );
            }),
          ),
        ),
        // Tambahkan pesan validasi di bawah grup checkbox jika diperlukan
        // Namun validasi utama ada di _validateStep1
      ],
    );
  }

  // Barang inputs (Build Widget - Tidak berubah)
  Widget _buildBarangInputs() {
    return Column(
      children: [
        _buildTextField(
          controller: _jenisBarangController,
          labelText: 'Jenis Barang',
          hintText: 'Masukkan jenis barang',
          icon: Icons.category_outlined, // Ganti ikon
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
          icon: Icons.branding_watermark_outlined, // Ganti ikon
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

  // STEP 2: Jaminan (Widget Build - DIRUBAH: ada tombol Back & Submit)
  Widget _buildStep2Content() {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 16,
        ), // Padding bawah untuk tombol
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Jaminan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Jenis Jaminan input
            _buildTextField(
              controller: _jenisJaminanController,
              labelText: 'Jenis Jaminan',
              hintText: 'Contoh: Sertifikat Rumah, BPKB, dll',
              icon: Icons.security_outlined, // Ganti ikon
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
              icon: Icons.description_outlined, // Ganti ikon
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
              labelText: 'Perkiraan Nilai Jaminan (Rp)', // Ganti label
              hintText: 'Masukkan perkiraan nilai',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              icon: Icons.monetization_on_outlined, // Ganti ikon
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan perkiraan nilai';
                }
                if (int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ==
                    null) {
                  return 'Masukkan angka yang valid';
                }
                if (int.parse(value.replaceAll(RegExp(r'[^\d]'), '')) <= 0) {
                  return 'Nilai harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Tombol navigasi Back & Submit di Step 2
            _buildNavigationButtons(
              isLastStep: true,
            ), // Tandai sebagai step terakhir
          ],
        ),
      ),
    );
  }

  // Hapus fungsi build Step 3
  /*
  Widget _buildStep3Content() { ... }
  */

  // Hapus fungsi build document upload field
  /*
  Widget _buildDocumentUploadField(...) { ... }
  */

  // Common TextField widget (Build Widget - Ganti Ikon)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
    String? suffixText,
    IconData? icon, // Tetap IconData untuk fleksibilitas
    int maxLines = 1,
  }) {
    final textTheme = Theme.of(context).textTheme;
    // Ambil warna dari theme jika memungkinkan
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Theme.of(
      context,
    ).dividerColor.withOpacity(0.5); // Warna border lebih lembut

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: textTheme.bodyLarge, // Style teks input
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: textTheme.labelMedium, // Style label
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ), // Style hint
          prefixText: prefixText,
          suffixText: suffixText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ), // Padding konten
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Radius border lebih besar
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ), // Border fokus lebih tebal
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          // Gunakan prefixIcon agar padding konsisten
          prefixIcon:
              icon != null
                  ? Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Icon(icon, size: 20, color: Colors.grey[600]),
                  )
                  : null,
          prefixIconConstraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 40,
          ), // Atur constraint ikon
        ),
        validator: validator,
      ),
    );
  }

  // Custom dropdown (Build Widget - Ganti Ikon)
  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String labelText,
    String? hintText,
    IconData? icon, // Tetap IconData
    String? Function(T?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: textTheme.labelMedium,
          hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ), // Sesuaikan padding
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          prefixIcon:
              icon != null
                  ? Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Icon(icon, size: 20, color: Colors.grey[600]),
                  )
                  : null,
          prefixIconConstraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 40,
          ),
          // suffixIcon tidak diperlukan, dropdown button sudah ada arrow default
        ),
        // icon: SizedBox.shrink(), // Sembunyikan ikon default jika pakai prefixIcon
        icon: Padding(
          // Atau style ikon default
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
        ),
        isExpanded: true,
        dropdownColor: Colors.white, // Warna background dropdown
      ),
    );
  }

  // Tombol Next (Build Widget - Tidak Berubah)
  Widget _buildNextButton() {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Atau Theme.of(context).primaryColor
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Berikutnya", // Ganti teks "Next"
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ), // Tebalkan teks
        ),
      ),
    );
  }

  // Tombol Navigasi Back & Next/Submit (Build Widget - Tidak Berubah)
  Widget _buildNavigationButtons({bool isLastStep = false}) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tombol Back (OutlinedButton agar tidak terlalu dominan)
        OutlinedButton(
          onPressed: _prevStep,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.grey[400]!), // Warna border
          ),
          child: Text(
            "Kembali", // Ganti teks
            style: textTheme.titleMedium?.copyWith(color: Colors.black54),
          ),
        ),
        // Tombol Next/Submit
        ElevatedButton(
          onPressed:
              _nextStep, // Fungsi _nextStep akan handle submit di step terakhir
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.green, // Atau Theme.of(context).primaryColor
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isLastStep ? "Ajukan Pinjaman" : "Berikutnya", // Ganti teks submit
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
