// screens/form_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:image_picker/image_picker.dart'; // Untuk XFile
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat dan NumberFormat
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
// --- Ganti dengan path import yang benar ---
import '../../../service/api_service.dart';
import '../../../model/jenis_pinjaman.dart'; // Asumsi model ini ada
import '../../../model/keperluan_pinjaman.dart'; // Asumsi model ini ada
import '../../../model/tenor_response.dart'; // Asumsi model ini ada
import '../../../model/simulasi_pinjaman_response.dart'; // Asumsi model ini ada
import 'package:path_provider/path_provider.dart';
// Jika Anda memiliki model untuk p_anggota_id atau data user, impor di sini
// import '../../../model/user_data_model.dart';
import '../../../theme.dart';

// -----------------------------------------

class FormWizardScreen extends StatefulWidget {
  const FormWizardScreen({Key? key}) : super(key: key);

  @override
  _FormWizardScreenState createState() => _FormWizardScreenState();
}

class _FormWizardScreenState extends State<FormWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 2;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  bool _step1PassedInitialValidation = false; // <-- TAMBAHKAN INI

  // Form data - Step 1
  int? _selectedJenisPinjamanId;
  final _jenisBarangController = TextEditingController();
  final _merkTypeController = TextEditingController();
  final _hargaController = TextEditingController();
  int? _selectedTenor;
  final _biayaAdminController = TextEditingController();
  final Set<int> _selectedKeperluanIds = {};

  // Form data - Step 2
  final _jenisJaminanController = TextEditingController();
  final _keteranganJaminanController = TextEditingController();
  final _perkiraanNilaiController = TextEditingController();
  final _noRekeningController = TextEditingController();
  final _bankController = TextEditingController();
  XFile? _docSlipGaji;

  List<JenisPinjamanModel> _jenisPinjamanList = [];
  List<KeperluanPinjamanModel> _keperluanPinjamanList = [];
  List<TenorItem> _availableTenors =
      []; // Menggunakan TenorItem dari model Anda

  bool _isLoadingJenisPinjaman = false;
  bool _isLoadingKeperluan = false;
  bool _isLoadingTenors = false;
  bool _isLoadingSimulasi = false;
  bool _isSubmitting = false;

  double? _simulasiBiayaAdmin;
  // String? _simulasiCicilanPerBulan;

  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchJenisPinjaman();
    _hargaController.addListener(_onJumlahPinjamanOrTenorChanged);
    _hargaController.addListener(_formatRupiahInputHarga);
    _perkiraanNilaiController.addListener(_formatRupiahInputNilaiJaminan);
  }

  @override
  void dispose() {
    _hargaController.removeListener(_formatRupiahInputHarga);
    _perkiraanNilaiController.removeListener(_formatRupiahInputNilaiJaminan);
    // _biayaAdminController.removeListener(_formatRupiahInputBiayaAdmin);
    _hargaController.removeListener(_onJumlahPinjamanOrTenorChanged);

    _jenisBarangController.dispose();
    _merkTypeController.dispose();
    _hargaController.dispose();
    _biayaAdminController.dispose();
    _jenisJaminanController.dispose();
    _keteranganJaminanController.dispose();
    _perkiraanNilaiController.dispose();
    _noRekeningController.dispose();
    _bankController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _formatRupiah(TextEditingController controller) {
    if (controller.text.isEmpty) return;
    String plainNumber = controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (plainNumber.isEmpty) {
      controller.clear();
      return;
    }
    try {
      double value = double.parse(plainNumber);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );
      String formatted = formatter.format(value);
      if (controller.text != formatted) {
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } catch (e) {
      print("Error formatting to Rupiah: $e");
    }
  }

  void _formatRupiahInputHarga() => _formatRupiah(_hargaController);
  void _formatRupiahInputNilaiJaminan() =>
      _formatRupiah(_perkiraanNilaiController);
  // void _formatRupiahInputBiayaAdmin() => _formatRupiah(_biayaAdminController);
  String _getCleanNumber(TextEditingController controller) =>
      controller.text.replaceAll(RegExp(r'[^\d]'), '');

  Future<void> _fetchJenisPinjaman() async {
    setState(() => _isLoadingJenisPinjaman = true);
    try {
      final data = await _apiService.getMasterJenisPinjaman();
      if (mounted) setState(() => _jenisPinjamanList = data);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat jenis pinjaman: $e');
    } finally {
      if (mounted) setState(() => _isLoadingJenisPinjaman = false);
    }
  }

  Future<void> _fetchKeperluanPinjaman() async {
    if (!mounted) return;
    setState(() => _isLoadingKeperluan = true);
    try {
      final data = await _apiService.getMasterKeperluanPinjaman();
      print('[fetchKeperluanPinjaman] Data diterima: $data');
      if (mounted) setState(() => _keperluanPinjamanList = data);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat keperluan pinjaman: $e');
    } finally {
      print(
        '[fetchKeperluanPinjaman] Sebelum setState(false) - _isLoadingKeperluan: $_isLoadingKeperluan',
      );
      if (mounted) setState(() => _isLoadingKeperluan = false);
      print(
        '[fetchKeperluanPinjaman] Sesudah setState(false) - _isLoadingKeperluan: $_isLoadingKeperluan',
      );
    }
  }

  Future<void> _fetchAvailableTenors(int jenisPinjamanId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingTenors = true;
      _availableTenors = [];
      _selectedTenor = null;
      _biayaAdminController.clear();
      _simulasiBiayaAdmin = null;
    });
    try {
      final tenors = await _apiService.getAvailableTenors(
        jenisPinjamanId: jenisPinjamanId,
      );
      if (mounted) {
        setState(() => _availableTenors = tenors);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat tenor: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTenors = false);
    }
  }

  Future<void> _fetchSimulasiPinjaman() async {
    if (_selectedJenisPinjamanId == null ||
        _selectedTenor == null ||
        _hargaController.text.isEmpty) {
      if (_simulasiBiayaAdmin != null ||
          _biayaAdminController.text.isNotEmpty) {
        if (mounted) {
          setState(() {
            _biayaAdminController.clear();
            _simulasiBiayaAdmin = null; // Sekarang ini adalah persentase
          });
        }
      }
      return;
    }

    final String cleanJumlah = _getCleanNumber(_hargaController);
    if (cleanJumlah.isEmpty) return;
    final double? jumlahPinjamanDouble = double.tryParse(cleanJumlah);

    if (jumlahPinjamanDouble == null || jumlahPinjamanDouble <= 0) return;
    // jumlahPinjaman (int) masih ada jika diperlukan untuk referensi lain,
    // tapi tidak untuk menghitung _simulasiBiayaAdmin di sini lagi.
    final int jumlahPinjaman = jumlahPinjamanDouble.toInt();

    if (!mounted) return;
    setState(() => _isLoadingSimulasi = true);
    try {
      final SimulasiResult
      simulasiData = await _apiService.postSimulasiPinjaman(
        jenisPinjamanId: _selectedJenisPinjamanId!,
        tenor: _selectedTenor!,
        jumlahPinjaman:
            jumlahPinjaman, // Jumlah pinjaman tetap dikirim untuk API simulasi
      );

      // Cetak dulu nilai mentah dari API
      print(
        'DEBUG: Nilai mentah simulasiData.biayaAdmin dari API: ${simulasiData.biayaAdmin}',
      );

      if (mounted) {
        setState(() {
          if (simulasiData.biayaAdmin != null) {
            double actualPercentageFromApi = simulasiData.biayaAdmin!;
            // Contoh: jika API mengirim 1.5 untuk 1.5% -> actualPercentageFromApi = 1.5

            // 1. Simpan persentase langsung ke _simulasiBiayaAdmin
            _simulasiBiayaAdmin =
                actualPercentageFromApi; // Menyimpan persentase, misal 1.5

            // // 2. Atur teks untuk UI Controller (menampilkan angka persentase)
            _biayaAdminController.text = actualPercentageFromApi
                .toStringAsFixed((actualPercentageFromApi % 1 == 0) ? 0 : 1);
            // 2. Atur teks untuk UI Controller (menampilkan angka persentase)
            // _biayaAdminController.text = '1.5';
            print(
              'DEBUG: Simulasi Selesai. '
              'API biayaAdmin (nilai % diterima): $actualPercentageFromApi, '
              'UI TxtCtrlr (angka % ditampilkan): "${_biayaAdminController.text}", '
              'Stored _simulasiBiayaAdmin (sekarang persentase): $_simulasiBiayaAdmin',
            );
          } else {
            _biayaAdminController.clear();
            _simulasiBiayaAdmin = null;
            _showErrorSnackBar(
              "Data persentase biaya admin tidak ditemukan dari simulasi.",
            );
            print(
              'DEBUG: Simulasi GAGAL, simulasiData.biayaAdmin (persentase) adalah null',
            );
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mendapatkan simulasi biaya admin: $e');
      if (mounted) {
        setState(() {
          _biayaAdminController.clear();
          _simulasiBiayaAdmin = null;
        });
      }
      print('DEBUG: Error saat fetchSimulasiPinjaman: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSimulasi = false);
    }
  }

  void _onJumlahPinjamanOrTenorChanged() {
    if (_selectedJenisPinjamanId != null &&
        _selectedTenor != null &&
        _hargaController.text.isNotEmpty) {
      _fetchSimulasiPinjaman();
    } else {
      if (_biayaAdminController.text.isNotEmpty ||
          _simulasiBiayaAdmin != null) {
        if (mounted)
          setState(() {
            _biayaAdminController.clear();
            _simulasiBiayaAdmin = null;
          });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onJenisPinjamanChanged(int? value) {
    setState(() {
      _selectedJenisPinjamanId = value;
      _selectedKeperluanIds.clear();
      _keperluanPinjamanList = [];
      _availableTenors = [];
      _selectedTenor = null;
      _biayaAdminController.clear();
      _simulasiBiayaAdmin = null;

      if (value != 3) {
        _jenisBarangController.clear();
        _merkTypeController.clear();
      }
      if (value != null) {
        _fetchAvailableTenors(value);
      }
      if (value == 1 || value == 2) {
        _fetchKeperluanPinjaman();
      }
    });
  }

  void _onTenorChanged(int? value) {
    setState(() {
      _selectedTenor = value;
    });
    _onJumlahPinjamanOrTenorChanged();
  }

  Future<String?> _getDownloadDirectoryPath() async {
    Directory? downloadsDirectory;
    try {
      List<Directory>? dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (dirs != null && dirs.isNotEmpty) {
        downloadsDirectory = dirs.first;
        print('DEBUG: Download directory found: ${downloadsDirectory.path}');
        return downloadsDirectory.path;
      } else {
        print('DEBUG: Download directory list is null or empty.');
      }
    } catch (e) {
      print("DEBUG: Error getting download directory: $e");
    }
    return null;
  }

  Future<void> _pickSlipGaji() async {
    String? initialDirPath = await _getDownloadDirectoryPath();
    print(
      'DEBUG: Path yang akan digunakan untuk initialDirectory _pickSlipGaji: $initialDirPath',
    );

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        initialDirectory: initialDirPath,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _docSlipGaji = XFile(result.files.single.path!));
        _showSuccessSnackBar(
          'Slip gaji berhasil dipilih: ${result.files.single.name}',
        );
      } else {
        print('Pemilihan slip gaji dibatalkan.');
      }
    } catch (e) {
      print("Error picking PDF: $e");
      _showErrorSnackBar("Gagal memilih file: ${e.toString()}");
    }
  }

  // --- FUNGSI VALIDASI DENGAN PRINT DEBUG ---
  bool _validateStep1() {
    print('DEBUG Validasi Step1: Memulai validasi...');
    bool formIsValid = _formKeyStep1.currentState?.validate() ?? false;
    print(
      'DEBUG Validasi Step1: _formKeyStep1.currentState.validate() => $formIsValid',
    );

    if (formIsValid) {
      // Cek Keperluan Pinjaman
      if ((_selectedJenisPinjamanId == 1 || _selectedJenisPinjamanId == 2)) {
        bool keperluanIsValid = _selectedKeperluanIds.isNotEmpty;
        print(
          'DEBUG Validasi Step1: Keperluan Pinjaman (ID 1/2) Valid => $keperluanIsValid (_selectedKeperluanIds: $_selectedKeperluanIds)',
        );
        if (!keperluanIsValid) {
          _showErrorSnackBar('Pilih minimal satu keperluan pinjaman');
          return false;
        }
      }

      // Cek Tenor
      bool tenorIsValid = _selectedTenor != null;
      print(
        'DEBUG Validasi Step1: Tenor Valid => $tenorIsValid (_selectedTenor: $_selectedTenor)',
      );
      if (!tenorIsValid) {
        _showErrorSnackBar('Tenor cicilan wajib dipilih.');
        return false;
      }

      // Cek Biaya Admin dari Simulasi
      // Kondisi asli: (_simulasiBiayaAdmin == null && _biayaAdminController.text.isEmpty) -> GAGAL jika TRUE
      bool biayaAdminProblem = _simulasiBiayaAdmin == null;

      print(
        'DEBUG Validasi Step1: Cek Masalah Biaya Admin => biayaAdminProblem: $biayaAdminProblem (_simulasiBiayaAdmin (Rp): $_simulasiBiayaAdmin, _biayaAdminController.text (UI %): "${_biayaAdminController.text}")',
      );
      if (biayaAdminProblem) {
        _showErrorSnackBar(
          'Biaya admin belum didapatkan dari simulasi. Pastikan jumlah dan tenor terisi.',
        );
        return false;
      }

      print('DEBUG Validasi Step1: Semua pengecekan kustom Lolos.');
      return true; // Semua validasi kustom lolos
    } else {
      // formIsValid adalah false
      _showErrorSnackBar(
        'Lengkapi semua field yang wajib diisi pada Langkah 1 (biasanya ditandai merah).',
      );
      print('DEBUG Validasi Step1: Gagal karena _formKeyStep1 tidak valid.');
      return false; // Validasi form gagal
    }
  }

  bool _validateStep2() {
    print('DEBUG Validasi Step2: Memulai validasi...');
    bool formIsValid = _formKeyStep2.currentState?.validate() ?? false;
    print(
      'DEBUG Validasi Step2: _formKeyStep2.currentState.validate() => $formIsValid',
    );
    if (!formIsValid) {
      _showErrorSnackBar(
        'Lengkapi semua field yang wajib diisi pada Langkah 2 (biasanya ditandai merah).',
      );
      print('DEBUG Validasi Step2: Gagal karena _formKeyStep2 tidak valid.');
    }
    return formIsValid;
  }
  // --- AKHIR FUNGSI VALIDASI DENGAN PRINT DEBUG ---

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) {
        _step1PassedInitialValidation =
            true; // <-- Tandai bahwa validasi awal berhasil
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _step1PassedInitialValidation =
            false; // <-- Tandai gagal jika validasi awal gagal
      }
    } else if (_currentStep == 1) {
      if (_validateStep2()) {
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

  Future<void> _submitForm() async {
    print('DEBUG SubmitForm: Memulai proses submit...');

    // Print nilai controller Step 1 sebelum validasi ulang
    print(
      'DEBUG SubmitForm: Nilai _selectedJenisPinjamanId SEBELUM validasi ulang: $_selectedJenisPinjamanId',
    );
    print(
      'DEBUG SubmitForm: Nilai _jenisBarangController.text SEBELUM validasi ulang: ${_jenisBarangController.text}',
    );
    print(
      'DEBUG SubmitForm: Nilai _merkTypeController.text SEBELUM validasi ulang: ${_merkTypeController.text}',
    );
    print(
      'DEBUG SubmitForm: Nilai _hargaController.text SEBELUM validasi ulang: ${_hargaController.text}',
    );
    print(
      'DEBUG SubmitForm: Nilai _selectedTenor SEBELUM validasi ulang: $_selectedTenor',
    );
    print(
      'DEBUG SubmitForm: Nilai _biayaAdminController.text SEBELUM validasi ulang: ${_biayaAdminController.text}',
    );
    print(
      'DEBUG SubmitForm: Nilai _selectedKeperluanIds SEBELUM validasi ulang: $_selectedKeperluanIds',
    );
    print(
      'DEBUG SubmitForm: Nilai _simulasiBiayaAdmin SEBELUM validasi ulang: $_simulasiBiayaAdmin',
    );

    bool step1IsValid;
    if (_step1PassedInitialValidation) {
      print(
        'DEBUG SubmitForm: Langkah 1 sudah pernah divalidasi berhasil. Hanya cek kondisi kustom.',
      );
      // Hanya jalankan pemeriksaan kustom, karena _formKeyStep1.currentState.validate() bermasalah saat dipanggil ulang
      bool keperluanIsValid = true;
      if ((_selectedJenisPinjamanId == 1 || _selectedJenisPinjamanId == 2)) {
        keperluanIsValid = _selectedKeperluanIds.isNotEmpty;
        print(
          'DEBUG SubmitForm (Recheck Kustom): Keperluan Valid => $keperluanIsValid',
        );
      }
      bool tenorIsValid = _selectedTenor != null;
      print('DEBUG SubmitForm (Recheck Kustom): Tenor Valid => $tenorIsValid');
      bool biayaAdminProblem =
          (_simulasiBiayaAdmin == null && _biayaAdminController.text.isEmpty);
      print(
        'DEBUG SubmitForm (Recheck Kustom): Biaya Admin Problem => $biayaAdminProblem',
      );

      step1IsValid = keperluanIsValid && tenorIsValid && !biayaAdminProblem;

      if (!step1IsValid) {
        if (!keperluanIsValid)
          _showErrorSnackBar(
            'Pilih minimal satu keperluan pinjaman (pengecekan ulang).',
          );
        else if (!tenorIsValid)
          _showErrorSnackBar('Tenor cicilan wajib dipilih (pengecekan ulang).');
        else if (biayaAdminProblem)
          _showErrorSnackBar(
            'Biaya admin belum didapatkan dari simulasi (pengecekan ulang).',
          );
      }
    } else {
      // Jika _step1PassedInitialValidation adalah false (artinya belum pernah lolos, atau kembali dari step 2)
      print(
        'DEBUG SubmitForm: Langkah 1 belum pernah divalidasi berhasil atau direset. Lakukan validasi penuh.',
      );
      step1IsValid =
          _validateStep1(); // Lakukan validasi penuh (termasuk formKey.validate())
    }

    print(
      'DEBUG SubmitForm: Hasil _validateStep1 (setelah logika baru): $step1IsValid',
    );

    bool step2IsValid = _validateStep2(); // Validasi ulang Step 2
    print('DEBUG SubmitForm: Hasil _validateStep2(): $step2IsValid');

    if (!step1IsValid) {
      _showErrorSnackBar(
        "Pengecekan ulang: Harap lengkapi semua data yang diperlukan di Langkah 1.",
      );
      // Opsional: kembali ke step 1
      // _pageController.jumpToPage(0);
      // if (mounted) setState(() => _currentStep = 0);
      return;
    }
    if (!step2IsValid) {
      _showErrorSnackBar(
        "Pengecekan ulang: Harap lengkapi semua data yang diperlukan di Langkah 2.",
      );
      return;
    }

    // Pengecekan tambahan yang sudah ada di kode Anda
    if (_selectedTenor == null || _simulasiBiayaAdmin == null) {
      _showErrorSnackBar(
        "Data tenor atau biaya admin belum lengkap (pengecekan di submit). Silakan periksa kembali.",
      );
      print(
        'DEBUG SubmitForm: Gagal karena _selectedTenor atau _simulasiBiayaAdmin null. Tenor: $_selectedTenor, BiayaAdmin: $_simulasiBiayaAdmin',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? pAnggotaId = prefs.getInt("p_anggota_id");
      if (pAnggotaId == null) {
        throw Exception("ID Anggota tidak ditemukan. Silakan login ulang.");
      }

      final Map<String, dynamic> response =
          await ApiService.submitLoanApplication(
            pAnggotaId: pAnggotaId,
            pJenisPinjamanId: _selectedJenisPinjamanId!,
            pPinjamanKeperluanIds:
                (_selectedJenisPinjamanId == 1 || _selectedJenisPinjamanId == 2)
                    ? _selectedKeperluanIds
                        .where((id) => id != null)
                        .cast<int>()
                        .toList()
                    : null,
            jenisBarang:
                _selectedJenisPinjamanId == 3
                    ? _jenisBarangController.text
                    : null,
            merkType:
                _selectedJenisPinjamanId == 3 ? _merkTypeController.text : null,
            tenor: _selectedTenor!,
            raJumlahPinjaman: double.parse(_getCleanNumber(_hargaController)),
            biayaAdmin: _simulasiBiayaAdmin!,
            jaminan: _jenisJaminanController.text,
            jaminanKeterangan: _keteranganJaminanController.text,
            jaminanPerkiraanNilai: double.tryParse(
                  _getCleanNumber(_perkiraanNilaiController),
                ) ??
                0,
            noRekening: _noRekeningController.text,
            bank: _bankController.text,
            docSlipGaji: _docSlipGaji,
          );
      if (mounted) {
        if (response['success'] == true) {
          _showSuccessSnackBar(
            response['message'] ?? 'Pengajuan pinjaman berhasil dikirim!',
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context, true);
          });
        } else {
          throw Exception(
            response['message'] ?? 'Gagal mengirim pengajuan pinjaman.',
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        e is Exception
            ? e.toString().replaceFirst("Exception: ", "")
            : 'Terjadi kesalahan.',
      );
      print('DEBUG SubmitForm: Exception saat submit: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0)
              _prevStep();
            else
              Navigator.pop(context);
          },
        ),
        title: const Text('Form Pengajuan Pinjaman'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            StepProgressIndicator(
              totalSteps: _totalSteps,
              currentStep: _currentStep + 1,
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
                children: [_buildStep1Content(), _buildStep2Content()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Content() {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pinjaman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDropdown<int>(
              value: _selectedJenisPinjamanId,
              items:
                  _isLoadingJenisPinjaman
                      ? []
                      : _jenisPinjamanList
                          .map(
                            (jenis) => DropdownMenuItem<int>(
                              value: jenis.id,
                              child: Text(jenis.nama),
                            ),
                          )
                          .toList(),
              onChanged:
                  _isLoadingJenisPinjaman ? null : _onJenisPinjamanChanged,
              labelText: 'Jenis Pinjaman',
              hintText:
                  _isLoadingJenisPinjaman
                      ? 'Memuat...'
                      : 'Pilih jenis pinjaman',
              icon: Icons.account_balance_wallet_outlined,
              validator: (value) {
                String? errorMessage;
                if (value == null) {
                  errorMessage = 'Pilih jenis pinjaman';
                }
                // HAPUS _getCallerMethodName() dari sini:
                print(
                  'DEBUG Validator JenisPinjaman: value=$value, error="$errorMessage"',
                );
                return errorMessage;
              },
            ),
            const SizedBox(height: 20),
            if (_selectedJenisPinjamanId == 1 || _selectedJenisPinjamanId == 2)
              _buildKeperluanPinjamanCheckboxes()
            else if (_selectedJenisPinjamanId == 3)
              _buildBarangInputs(),

            if (_selectedJenisPinjamanId != null) ...[
              const SizedBox(height: 20),
              _buildTextField(
                controller: _hargaController,
                labelText: 'Jumlah Pengajuan (Rp)',
                hintText: 'Masukkan jumlah pengajuan',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                icon: Icons.monetization_on_outlined,
                validator: (value) {
                  String? errorMessage;
                  if (value == null ||
                      _getCleanNumber(_hargaController).isEmpty) {
                    errorMessage = 'Masukkan jumlah pengajuan';
                  } else if (double.tryParse(
                        _getCleanNumber(_hargaController),
                      ) ==
                      null) {
                    errorMessage = 'Masukkan angka yang valid';
                  }
                  // HAPUS _getCallerMethodName() dari sini:
                  print(
                    'DEBUG Validator Harga: value="$value", clean="${_getCleanNumber(_hargaController)}", error="$errorMessage"',
                  );
                  return errorMessage;
                },
              ),
              const SizedBox(height: 16),

              if (_isLoadingTenors)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_availableTenors.isNotEmpty)
                _buildDropdown<int?>(
                  value: _selectedTenor,
                  items:
                      _availableTenors
                          .map(
                            (item) => DropdownMenuItem<int?>(
                              value: item.tenor,
                              child: Text('${item.tenor ?? '?'} bulan'),
                            ),
                          )
                          .toList(),
                  onChanged: _onTenorChanged,
                  labelText: 'Tenor Cicilan',
                  hintText: 'Pilih tenor',
                  icon: Icons.calendar_today_outlined,
                  validator: (value) {
                    String? errorMessage;
                    if (value == null) {
                      errorMessage = 'Pilih tenor cicilan';
                    }
                    // HAPUS _getCallerMethodName() dari sini:
                    print(
                      'DEBUG Validator TenorCicilan: value=$value, error="$errorMessage"',
                    );
                    return errorMessage;
                  },
                )
              else if (_selectedJenisPinjamanId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  child: Text(
                    "Tenor tidak tersedia untuk jenis pinjaman ini.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              // const SizedBox(height: 16),
              // Stack(
              //   children: [
              //     _buildTextField(
              //       controller: _biayaAdminController,
              //       labelText: 'Biaya Admin', // Ubah label jika perlu
              //       hintText:
              //           _isLoadingSimulasi
              //               ? 'Menghitung...'
              //               : 'Akan terisi setelah simulasi',
              //       // prefixText: 'Rp ', // HAPUS ATAU GANTI INI
              //       suffixText: '%', // TAMBAHKAN INI
              //       keyboardType:
              //           TextInputType.number, // Meskipun readOnly, ini relevan
              //       icon:
              //           Icons.percent_outlined, // Ganti ikon menjadi persentase
              //       readOnly: true,
              //       validator: (value) {
              //         String? errorMessage;
              //         // Validasi tetap berdasarkan apakah _simulasiBiayaAdmin (nilai Rupiah) sudah dihitung
              //         if (_simulasiBiayaAdmin == null) {
              //           errorMessage = 'Biaya admin belum disimulasikan';
              //         }
              //         print(
              //           'DEBUG Validator BiayaAdmin (UI Persen): value="$value", _simulasiBiayaAdmin (Rp)=$_simulasiBiayaAdmin, error="$errorMessage"',
              //         );
              //         return errorMessage;
              //       },
              //     ),
              //     if (_isLoadingSimulasi)
              //       Positioned.fill(
              //         child: Container(
              //           color: Colors.white.withOpacity(0.1),
              //           alignment: Alignment.centerRight,
              //           padding: const EdgeInsets.only(right: 40.0),
              //           child: const SizedBox(
              //             width: 20,
              //             height: 20,
              //             child: CircularProgressIndicator(strokeWidth: 2),
              //           ),
              //         ),
              //       ),
              //   ],
              // ),
              const SizedBox(height: 32),
              _buildNextButton(), // Tombol "Berikutnya" di Step 1
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeperluanPinjamanCheckboxes() {
    print(
      '[_buildKeperluanPinjamanCheckboxes] Isi _keperluanPinjamanList: $_keperluanPinjamanList',
    );
    Widget checkboxContent;
    if (_isLoadingKeperluan) {
      checkboxContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      final validKeperluanList =
          _keperluanPinjamanList
              .where((kp) => kp.id != null && kp.nama != null)
              .toList();
      if (validKeperluanList.isEmpty) {
        checkboxContent = const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Tidak ada data keperluan untuk jenis pinjaman ini.",
            textAlign: TextAlign.center,
          ),
        );
        print('ini validKeperluan $_keperluanPinjamanList');
      } else {
        checkboxContent = Column(
          children:
              validKeperluanList.map((keperluan) {
                print(
                  '[_buildKeperluanPinjamanCheckboxes] Isi validKeperluanList: $validKeperluanList',
                );
                final int keperluanId = keperluan.id!;
                final String keperluanNama = keperluan.nama!;

                return CheckboxListTile(
                  title: Text(
                    keperluanNama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _selectedKeperluanIds.contains(keperluanId),
                  onChanged:
                      (bool? value) => setState(() {
                        if (value == true)
                          _selectedKeperluanIds.add(keperluanId);
                        else
                          _selectedKeperluanIds.remove(keperluanId);
                      }),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primaryLight,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keperluan Pinjaman *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: checkboxContent,
        ),
      ],
    );
  }

  Widget _buildBarangInputs() {
    return Column(
      children: [
        _buildTextField(
          controller: _jenisBarangController,
          labelText: 'Jenis Barang',
          hintText: 'Masukkan jenis barang',
          icon: Icons.category_outlined,
          validator: (value) {
            String? errorMessage;
            if (_selectedJenisPinjamanId == 3 &&
                (value == null || value.isEmpty)) {
              errorMessage = 'Masukkan jenis barang';
            }
            // HAPUS _getCallerMethodName() dari sini:
            print(
              'DEBUG Validator JenisBarang: value="$value", _selectedJenisPinjamanId=$_selectedJenisPinjamanId, error="$errorMessage"',
            );
            return errorMessage;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _merkTypeController,
          labelText: 'Merk/Type',
          hintText: 'Masukkan merk/type',
          icon: Icons.branding_watermark_outlined,
          validator: (value) {
            String? errorMessage;
            if (_selectedJenisPinjamanId == 3 &&
                (value == null || value.isEmpty)) {
              errorMessage = 'Masukkan merk/type';
            }
            // HAPUS _getCallerMethodName() dari sini:
            print(
              'DEBUG Validator MerkType: value="$value", _selectedJenisPinjamanId=$_selectedJenisPinjamanId, error="$errorMessage"',
            );
            return errorMessage;
          },
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Jaminan & Pencairan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _jenisJaminanController,
              labelText: 'Jenis Jaminan',
              hintText: 'Contoh: Sertifikat Rumah, BPKB, dll',
              icon: Icons.security_outlined,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Masukkan jenis jaminan'
                          : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _keteranganJaminanController,
              labelText: 'Keterangan Jaminan',
              hintText: 'Detail informasi terkait jaminan',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Masukkan keterangan jaminan'
                          : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _perkiraanNilaiController,
              labelText: 'Perkiraan Nilai Jaminan (Rp, Opsional)',
              hintText: 'Masukkan perkiraan nilai',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              icon: Icons.monetization_on_outlined,
              validator: (value) {
                final clean =
                    _getCleanNumber(_perkiraanNilaiController);
                // Field opsional: kosong atau 0 diperbolehkan
                if (clean.isEmpty) return null;
                if (double.tryParse(clean) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _noRekeningController,
              labelText: 'Nomor Rekening Pencairan',
              hintText: 'Masukkan nomor rekening',
              keyboardType: TextInputType.number,
              icon: Icons.account_balance_outlined,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Masukkan nomor rekening'
                          : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bankController,
              labelText: 'Nama Bank Pencairan',
              hintText: 'Contoh: BSI, Mandiri, BCA',
              icon: Icons.business_outlined,
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Masukkan nama bank'
                          : null,
            ),
            const SizedBox(height: 16),
            _buildDocumentPicker(
              label: "Upload Slip Gaji (PDF, Opsional)",
              file: _docSlipGaji,
              onPick: _pickSlipGaji,
            ),
            const SizedBox(height: 32),
            _buildNavigationButtons(
              isLastStep: true,
            ), // Tombol di Step 2 (termasuk "Ajukan Pinjaman")
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required XFile? file,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file_outlined, color: AppColors.primaryLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file.name : 'Pilih file PDF...',
                    style: TextStyle(
                      color: file != null ? Colors.black87 : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.successLight,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Maks. 2MB, format .pdf",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

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
    bool readOnly = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = AppColors.primaryLight;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: textTheme.bodyLarge,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: textTheme.labelMedium,
          hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          prefixText: prefixText,
          suffixText: suffixText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required String labelText,
    String? hintText,
    IconData? icon,
    String? Function(T?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = AppColors.primaryLight;
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
          ),
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
        ),
        icon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
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
          backgroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Berikutnya",
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons({bool isLastStep = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: _prevStep,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.grey[400]!),
          ),
          child: Text(
            "Kembali",
            style: textTheme.titleMedium?.copyWith(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed:
              _isSubmitting
                  ? null
                  : (isLastStep
                      ? _submitForm
                      : _nextStep), // Menggunakan _submitForm jika isLastStep
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isSubmitting &&
                      isLastStep // Tampilkan loading hanya saat submit di step terakhir
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    isLastStep ? "Ajukan Pinjaman" : "Berikutnya",
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
