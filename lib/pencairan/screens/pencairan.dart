import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:intl/intl.dart'; // Untuk NumberFormat
import 'package:shared_preferences/shared_preferences.dart';

// --- Sesuaikan Path Import ---
import '../../../service/api_service.dart';
import '../../../model/jenis_tabungan.dart';
import '../../../theme.dart'; // Import theme Anda
// ---------------------------

class PencairanTabunganScreen extends StatefulWidget {
  const PencairanTabunganScreen({Key? key}) : super(key: key);

  @override
  State<PencairanTabunganScreen> createState() =>
      _PencairanTabunganScreenState();
}

class _PencairanTabunganScreenState extends State<PencairanTabunganScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // State untuk data & UI
  bool _isLoadingJenis = true; // Loading untuk jenis tabungan
  bool _isSubmitting = false; // Loading saat submit
  String? _loadingError; // Pesan error saat loading jenis tabungan
  int? _pAnggotaId;

  // Data Dropdown
  List<JenisTabunganItem> _jenisTabunganList = [];
  int? _selectedJenisTabunganId; // ID jenis tabungan yang dipilih

  // Controllers untuk input
  final _jumlahController = TextEditingController();
  final _bankController = TextEditingController();
  final _rekeningController = TextEditingController();
  final _keteranganController = TextEditingController();

  // Formatter untuk input jumlah
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '', // Kosongkan simbol di controller
    decimalDigits: 0,
  );
  final NumberFormat _displayFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ', // Tampilkan simbol di UI lain jika perlu
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _bankController.dispose();
    _rekeningController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // Inisialisasi: ambil ID anggota dan jenis tabungan
  Future<void> _initializePage() async {
    await _loadAnggotaId();
    // Hanya fetch jenis tabungan jika ID anggota berhasil didapat
    if (_pAnggotaId != null) {
      await _fetchJenisTabungan();
    } else {
      if (mounted) {
        setState(() {
          _loadingError = "ID Anggota tidak ditemukan. Silakan login ulang.";
          _isLoadingJenis = false;
        });
      }
    }
  }

  // Ambil p_anggota_id dari SharedPreferences
  Future<void> _loadAnggotaId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // PASTIKAN KEY 'p_anggota_id' BENAR
      _pAnggotaId = prefs.getInt('p_anggota_id');
      print("[PencairanTabungan] p_anggota_id loaded: $_pAnggotaId"); // Debug
      if (_pAnggotaId == null && mounted) {
        // Set error jika ID null setelah mencoba load
        setState(() {
          _loadingError = "ID Anggota tidak ditemukan di penyimpanan.";
          _isLoadingJenis = false; // Hentikan loading jika ID tidak ada
        });
      }
    } catch (e) {
      print("Error loading p_anggota_id: $e");
      if (mounted) {
        setState(() {
          _loadingError = "Gagal memuat ID Anggota: $e";
          _isLoadingJenis = false;
        });
      }
    }
  }

  // Fetch jenis tabungan dari API
  Future<void> _fetchJenisTabungan() async {
    if (!mounted) return;
    setState(() {
      _isLoadingJenis = true;
      _loadingError = null;
    });

    try {
      final response = await _apiService.getJenisTabungan();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          // Filter hanya jenis tabungan yang bisa ditarik (isWithdrawable == true)
          _jenisTabunganList =
              response.data!.jenisTabungan
                  .where((jenis) => jenis.isWithdrawable)
                  .toList();
          _isLoadingJenis = false;
          if (_jenisTabunganList.isEmpty) {
            _loadingError = "Tidak ada jenis tabungan yang bisa ditarik.";
          }
        });
      } else {
        setState(() {
          _loadingError = response.message;
          _isLoadingJenis = false;
        });
      }
    } catch (e) {
      print("Error fetching jenis tabungan: $e");
      if (!mounted) return;
      setState(() {
        _loadingError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingJenis = false;
      });
    }
  }

  // Fungsi untuk submit pengajuan
  Future<void> _submitPengajuan() async {
    // Validasi form
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar(
        "Harap lengkapi semua data yang diperlukan.",
        isError: true,
      );
      return;
    }

    // Pastikan ID anggota ada
    if (_pAnggotaId == null) {
      _showSnackBar("Gagal mengirim: ID Anggota tidak valid.", isError: true);
      return;
    }

    // Konversi jumlah ke tipe num/int
    final String jumlahRaw = _jumlahController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final num? jumlahDiambil = num.tryParse(jumlahRaw);

    if (jumlahDiambil == null || jumlahDiambil <= 0) {
      _showSnackBar("Jumlah yang diambil tidak valid.", isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final response = await _apiService.submitPengajuanPencairan(
        pAnggotaId: _pAnggotaId!,
        pJenisTabunganId:
            _selectedJenisTabunganId!, // Pasti sudah dipilih karena validasi
        jumlahDiambil: jumlahDiambil,
        rekeningBank: _bankController.text,
        rekeningNo: _rekeningController.text,
        keterangan:
            _keteranganController.text.isNotEmpty
                ? _keteranganController.text
                : null, // Kirim null jika kosong
      );

      if (!mounted) return; // Cek lagi setelah await

      if (response.success) {
        _showSnackBar(response.message, isError: false);
        // Reset form atau navigasi kembali setelah sukses
        _formKey.currentState?.reset();
        setState(() {
          _selectedJenisTabunganId = null;
          _jumlahController.clear();
          _bankController.clear();
          _rekeningController.clear();
          _keteranganController.clear();
        });
        // Contoh navigasi kembali setelah delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Helper untuk menampilkan SnackBar
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorLight : AppColors.successLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan theme dari context
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // AppBar menggunakan style dari AppTheme
      appBar: AppBar(title: const Text("Pengajuan Pencairan")),
      body: _buildBody(theme, textTheme),
    );
  }

  // Memisahkan body untuk kejelasan
  Widget _buildBody(ThemeData theme, TextTheme textTheme) {
    // Tampilkan error utama jika ada (misal gagal load ID anggota)
    if (_loadingError != null &&
        _jenisTabunganList.isEmpty &&
        !_isLoadingJenis) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _loadingError!,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.errorLight),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Tampilkan loading awal
    if (_isLoadingJenis && _jenisTabunganList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Tampilkan form jika jenis tabungan sudah dimuat (atau ada error tapi list tidak kosong)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Formulir Pengajuan Pencairan Tabungan",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan isi data berikut untuk mengajukan pencairan dana tabungan Anda.",
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Dropdown Jenis Tabungan
            _buildDropdownJenisTabungan(theme, textTheme),
            const SizedBox(height: 16),

            // Input Jumlah Diambil
            _buildTextField(
              controller: _jumlahController,
              labelText: "Jumlah Dicairkan",
              hintText: "Masukkan jumlah",
              prefixText: "Rp ",
              keyboardType: TextInputType.number,
              icon: Icons.account_balance_wallet_outlined,
              // Format input hanya angka
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                final intValue = int.tryParse(
                  value.replaceAll(RegExp(r'[^\d]'), ''),
                );
                if (intValue == null || intValue <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Input Nama Bank
            _buildTextField(
              controller: _bankController,
              labelText: "Nama Bank Tujuan",
              hintText: "Contoh: Bank BCA, Bank Mandiri",
              icon: Icons.account_balance_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama bank tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Input Nomor Rekening
            _buildTextField(
              controller: _rekeningController,
              labelText: "Nomor Rekening Tujuan",
              hintText: "Masukkan nomor rekening",
              keyboardType: TextInputType.number,
              icon: Icons.confirmation_number_outlined,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor rekening tidak boleh kosong';
                }
                if (value.length < 5) {
                  // Contoh validasi panjang minimal
                  return 'Nomor rekening terlalu pendek';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Input Keterangan (Opsional)
            _buildTextField(
              controller: _keteranganController,
              labelText: "Keterangan (Opsional)",
              hintText: "Contoh: Kebutuhan mendesak, biaya pendidikan",
              icon: Icons.notes_outlined,
              maxLines: 3,
              validator: null, // Tidak wajib
            ),
            const SizedBox(height: 32),

            // Tombol Submit
            ElevatedButton(
              // Style diambil dari AppTheme.elevatedButtonTheme
              onPressed: _isSubmitting ? null : _submitPengajuan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                // Anda bisa override style di sini jika perlu
                // backgroundColor: AppColors.primaryLight,
                // shape: RoundedRectangleBorder(...)
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        "Ajukan Pencairan",
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white, // Pastikan teks kontras
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk Dropdown Jenis Tabungan
  Widget _buildDropdownJenisTabungan(ThemeData theme, TextTheme textTheme) {
    // Tampilkan pesan jika sedang loading atau error
    if (_isLoadingJenis) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 15),
            Text("Memuat jenis tabungan..."),
          ],
        ),
      );
    }
    if (_loadingError != null && _jenisTabunganList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          "Error: $_loadingError",
          style: TextStyle(color: AppColors.errorLight),
        ),
      );
    }
    if (_jenisTabunganList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Text("Tidak ada jenis tabungan yang bisa dicairkan saat ini."),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedJenisTabunganId,
      // Gunakan style dari AppTheme.inputDecorationTheme
      decoration: InputDecoration(
        labelText: 'Jenis Tabungan',
        hintText: 'Pilih jenis tabungan yang akan dicairkan',
        prefixIcon: const Padding(
          // Konsisten dengan _buildTextField
          padding: EdgeInsets.only(left: 12.0, right: 8.0),
          child: Icon(Icons.savings_outlined, size: 20, color: Colors.grey),
        ),
        prefixIconConstraints: const BoxConstraints(
          minHeight: 40,
          minWidth: 40,
        ),
        // Border, padding, dll., diambil dari theme
      ),
      // Filter hanya yang bisa ditarik (sebenarnya sudah difilter di _fetchJenisTabungan)
      items:
          _jenisTabunganList
          // .where((jenis) => jenis.isWithdrawable) // Filter lagi jika perlu
          .map((JenisTabunganItem jenis) {
            return DropdownMenuItem<int>(
              value: jenis.id,
              child: Text(jenis.nama, style: textTheme.bodyLarge),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedJenisTabunganId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Pilih jenis tabungan';
        }
        return null;
      },
      isExpanded: true,
      icon: const Padding(
        // Style ikon dropdown
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(Icons.arrow_drop_down_rounded),
      ),
    );
  }

  // Helper widget untuk TextField (menggunakan style dari theme)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
    IconData? icon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // InputDecoration akan mengambil style dari AppTheme.inputDecorationTheme
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        // Style label, hint, border, padding diambil dari theme
        // Kita hanya perlu menambahkan ikon jika ada
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
    );
  }
}
