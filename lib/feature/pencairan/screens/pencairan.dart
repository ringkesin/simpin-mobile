// File: lib/screens/pencairan/pencairan_tabungan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/feature/pencairan/screens/history.dart';
// Pastikan path formatter sudah benar
import 'package:kkba_mobile/feature/pencairan/widgets/formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Sesuaikan Path Import ---
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/jenis_tabungan.dart';
import 'package:kkba_mobile/model/tabungan_tahunan_response.dart'; // Model yang sudah diperbarui
// Import AppTheme (yang berisi AppColors)
import 'package:kkba_mobile/theme.dart'; // Mengandung AppColors
// ---------------------------

class PencairanTabunganScreen extends StatefulWidget {
  const PencairanTabunganScreen({super.key});

  @override
  State<PencairanTabunganScreen> createState() =>
      _PencairanTabunganScreenState();
}

class _PencairanTabunganScreenState extends State<PencairanTabunganScreen> {
  // --- State Variables & Logic Functions (Tetap sama) ---
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoadingPage = true;
  bool _isSubmitting = false;
  String? _pageError;
  int? _pAnggotaId;
  List<JenisTabunganItem> _jenisTabunganList = [];
  int? _selectedJenisTabunganId;
  TabunganTahunanData? _tabunganTahunanData;
  num? _saldoTersedia;
  final _jumlahController = TextEditingController();
  final _bankController = TextEditingController();
  final _rekeningController = TextEditingController();
  final _keteranganController = TextEditingController();
  final NumberFormat _displayFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  late final int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
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

  // --- Fungsi Logic (initState, dispose, initializePage, loadAnggotaId, fetch..., updateSaldo, submit, reset) ---
  // --- Tidak ada perubahan signifikan pada logic, hanya pada _showSnackBar ---
  Future<void> _initializePage() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPage = true;
      _pageError = null;
      _jenisTabunganList = [];
      _tabunganTahunanData = null;
      _selectedJenisTabunganId = null;
      _saldoTersedia = null;
    });
    try {
      await _loadAnggotaId();
      if (_pAnggotaId == null) {
        throw Exception("ID Anggota tidak ditemukan. Silakan login ulang.");
      }
      final results = await Future.wait([
        _fetchJenisTabungan(),
        _fetchTabunganTahunan(_currentYear),
      ]);
      if (mounted) {
        String? combinedError;
        if (results[0] is String) {
          combinedError = results[0] as String?;
        }
        if (results[1] is String) {
          final err = results[1] as String;
          combinedError =
              (combinedError == null) ? err : '$combinedError\n$err';
        }
        _pageError = combinedError;
        if (_jenisTabunganList.isEmpty && _pageError == null) {
          _pageError = "Tidak ada jenis tabungan yang dapat ditarik.";
        }
      }
    } catch (e) {
      print("Init Error: $e");
      if (mounted) {
        _pageError =
            "Gagal memuat data: ${e.toString().replaceFirst("Exception: ", "")}";
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPage = false);
      }
    }
  }

  Future<void> _loadAnggotaId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _pAnggotaId = prefs.getInt('p_anggota_id');
    print("ID Loaded: $_pAnggotaId");
  }

  Future<String?> _fetchJenisTabungan() async {
    try {
      final r = await _apiService.getJenisTabungan();
      if (!mounted) return "Operation cancelled";
      if (r.success && r.data != null) {
        _jenisTabunganList =
            r.data!.jenisTabungan.where((j) => j.isWithdrawable).toList();
        return null; // Success
      } else {
        return r.message ?? "Gagal memuat jenis tabungan";
      }
    } catch (e) {
      print("Error fetching Jenis Tabungan: $e");
      return "Terjadi kesalahan saat mengambil jenis tabungan: ${e.toString().replaceFirst("Exception: ", "")}";
    }
  }

  Future<String?> _fetchTabunganTahunan(int t) async {
    if (_pAnggotaId == null) return "ID Anggota tidak valid";
    try {
      final r = await _apiService.getTabunganTahunan(
        tahun: t,
        pAnggotaId: _pAnggotaId,
      );
      if (!mounted) return "Operation cancelled";
      if (r.success && r.data != null) {
        _tabunganTahunanData = r.data;
        return null; // Success
      } else {
        return r.success == false &&
                r.message != null &&
                r.message!.toLowerCase().contains("tidak ditemukan")
            ? null
            : r.message ?? "Gagal memuat data tabungan tahunan";
      }
    } catch (e) {
      print("Error fetching Tabungan Tahunan: $e");
      return "Terjadi kesalahan saat mengambil data tabungan: ${e.toString().replaceFirst("Exception: ", "")}";
    }
  }

  void _updateSaldoTersedia(int? jenisTabunganId) {
    setState(() {
      _selectedJenisTabunganId = jenisTabunganId;
      _saldoTersedia = null;
      if (jenisTabunganId != null && _tabunganTahunanData != null) {
        try {
          final saldoItem = _tabunganTahunanData!.detail.firstWhere(
            (item) => item.pJenisTabunganId == jenisTabunganId,
          );
          _saldoTersedia = saldoItem.saldoAkhir;
        } catch (e) {
          print("Saldo for ID $jenisTabunganId not found in data.");
          _saldoTersedia = 0;
        }
      }
      _formKey.currentState?.validate();
    });
  }

  Future<void> _submitPengajuan() async {
    // 1. Validasi Form
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar(
        "Harap periksa kembali isian formulir Anda.",
        isError: true,
      );
      return;
    }

    // 2. Validasi ID Anggota (pastikan sudah dimuat)
    if (_pAnggotaId == null) {
      _showSnackBar(
        "ID Anggota tidak valid. Coba muat ulang halaman.",
        isError: true,
      );
      return; // Jangan lanjutkan jika ID Anggota null
    }

    // 3. Validasi Jenis Tabungan & Saldo
    if (_selectedJenisTabunganId == null) {
      _showSnackBar(
        "Silakan pilih jenis tabungan terlebih dahulu.",
        isError: true,
      );
      return;
    }
    if (_saldoTersedia == null) {
      _showSnackBar(
        "Verifikasi saldo gagal, coba pilih ulang jenis tabungan.",
        isError: true,
      );
      return;
    }

    // 4. Ambil dan Validasi Jumlah
    final String rawAmount = _jumlahController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final num amount = num.tryParse(rawAmount) ?? 0;
    if (amount <= 0) {
      _showSnackBar("Jumlah pencairan tidak valid.", isError: true);
      return;
    }
    if (amount > _saldoTersedia!) {
      _showSnackBar(
        "Jumlah pencairan melebihi saldo tersedia (${_displayFormatter.format(_saldoTersedia)}).",
        isError: true,
      );
      return;
    }

    // 5. Ambil Data Lainnya
    final String bankName = _bankController.text.trim();
    final String accountNumber = _rekeningController.text.trim();
    final String? description =
        _keteranganController.text.trim().isNotEmpty
            ? _keteranganController.text.trim()
            : null;

    // 6. Set Loading State
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      // 7. Panggil API Service dengan data yang sudah divalidasi
      //    Menggunakan _pAnggotaId yang sudah ada di state
      final response = await _apiService.submitPengajuanPencairan(
        pAnggotaId: _pAnggotaId!, // <-- Menggunakan ID Anggota dari state
        pJenisTabunganId: _selectedJenisTabunganId!,
        jumlahDiambil: amount,
        rekeningBank: bankName,
        rekeningNo: accountNumber,
        keterangan: description,
      );

      if (!mounted) return;

      // 8. Handle Response API
      if (response.success) {
        _showSnackBar(
          response.message ?? "Pengajuan pencairan berhasil dikirim.",
          isError: false,
        );
        _resetForm(); // Reset form jika sukses
        // Refresh saldo (opsional, tergantung kebutuhan)
        final refreshError = await _fetchTabunganTahunan(_currentYear);
        if (mounted) {
          if (refreshError != null) {
            _showSnackBar(
              "Pengajuan OK, namun gagal refresh saldo: $refreshError",
              isError: true,
            );
          }
          // Navigasi kembali setelah delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        // Tampilkan pesan error dari API jika gagal
        _showSnackBar(
          response.message ?? "Gagal mengirim pengajuan.",
          isError: true,
        );
      }
    } catch (e) {
      // Tangani error koneksi atau error tak terduga lainnya
      if (mounted) {
        _showSnackBar(
          // Menampilkan pesan error yang dilempar oleh ApiService
          e.toString().replaceFirst("Exception: ", ""),
          isError: true,
        );
      }
    } finally {
      // 9. Reset Loading State
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _jumlahController.clear();
    _bankController.clear();
    _rekeningController.clear();
    _keteranganController.clear();
    setState(() {
      _selectedJenisTabunganId = null;
      _saldoTersedia = null;
    });
  }

  // Modifikasi _showSnackBar untuk menggunakan AppColors secara langsung
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    final theme = Theme.of(context); // Masih perlu untuk textTheme
    final textTheme = theme.textTheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          // Gunakan style dari theme, sesuaikan warna dari AppColors
          style: textTheme.bodyMedium?.copyWith(
            // Teks putih di atas background error/sukses
            color: AppColors.secondaryLight, // White color
          ),
        ),
        // Gunakan warna error/sukses langsung dari AppColors
        backgroundColor:
            isError ? AppColors.errorLight : AppColors.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        elevation: 4.0,
      ),
    );
  }
  // --- Akhir State & Logic ---

  // ===========================================================
  // == BAGIAN BUILD WIDGET (HANYA MENGGUNAKAN AppColors) ==
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    // Ambil theme HANYA untuk textTheme dan theme components lainnya
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengajuan Pencairan"),
        // Style otomatis dari theme.appBarTheme
        // --- Tambahkan actions ---
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded), // Icon history
            tooltip: 'Riwayat Pengajuan', // Teks saat ditahan lama
            onPressed: () {
              // Navigasi ke Halaman History
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPengajuanScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // Sedikit jarak di kanan
        ],
        // ------------------------
      ),
      backgroundColor:
          AppColors.primaryBackgroundLight, // Langsung dari AppColors
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildBody(theme, textTheme), // Kirim theme dan textTheme saja
        ),
      ),
    );
  }

  // Widget Body Utama
  Widget _buildBody(
    ThemeData theme, // Masih perlu theme untuk akses theme components lain
    TextTheme textTheme,
  ) {
    // --- Tampilan Loading ---
    if (_isLoadingPage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 20),
            Text("Memuat data formulir...", style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    // --- Tampilan Error Awal ---
    if (_pageError != null && _jenisTabunganList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: AppColors.errorLight,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                "Oops! Gagal Memuat",
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.errorLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _pageError!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text("Coba Muat Ulang"),
                onPressed: _initializePage,
                // Style tombol dari theme, tapi pastikan warnanya primaryLight
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight, // white text
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Tampilan Form Utama ---
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Formulir Pencairan Dana",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Lengkapi detail berikut untuk mengajukan pencairan saldo.",
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // --- Input Fields ---
            _buildDropdownJenisTabungan(theme, textTheme),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder:
                  (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
              child:
                  _saldoTersedia != null
                      ? _buildSaldoTersedia(textTheme)
                      : SizedBox(key: UniqueKey()),
            ),
            SizedBox(height: _saldoTersedia != null ? 20 : 0),

            _buildTextField(
              theme: theme,
              textTheme: textTheme,
              controller: _jumlahController,
              labelText: "Jumlah Dicairkan",
              hintText: "0",
              prefixText: "Rp ",
              keyboardType: TextInputType.number,
              icon: Icons.account_balance_wallet_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty || value == '0') {
                  return 'Jumlah harus diisi';
                }
                final rawValue = value.replaceAll(RegExp(r'[^\d]'), '');
                final num amount = num.tryParse(rawValue) ?? 0;
                if (amount <= 0) {
                  return 'Jumlah tidak valid';
                }
                if (_selectedJenisTabunganId != null &&
                    _saldoTersedia != null &&
                    amount > _saldoTersedia!) {
                  return 'Saldo tidak mencukupi (${_displayFormatter.format(_saldoTersedia)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildTextField(
              theme: theme,
              textTheme: textTheme,
              controller: _bankController,
              labelText: "Nama Bank Tujuan",
              hintText: "Contoh: Bank Central Asia",
              icon: Icons.account_balance_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama bank harus diisi';
                }
                if (value.trim().length < 3) {
                  return 'Nama bank terlalu pendek';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildTextField(
              theme: theme,
              textTheme: textTheme,
              controller: _rekeningController,
              labelText: "Nomor Rekening Tujuan",
              hintText: "Masukkan nomor rekening valid",
              keyboardType: TextInputType.number,
              icon: Icons.confirmation_number_outlined,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor rekening harus diisi';
                }
                if (value.length < 8 || value.length > 20) {
                  return 'Format nomor rekening tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildTextField(
              theme: theme,
              textTheme: textTheme,
              controller: _keteranganController,
              labelText: "Keterangan (Opsional)",
              hintText: "Tulis catatan tambahan jika diperlukan...",
              icon: Icons.notes_rounded,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: null,
            ),
            const SizedBox(height: 36),

            // --- Tombol Submit ---
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPengajuan,
              // --- Style Eksplisit untuk memastikan warna primer ---
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryLight, // Warna background primer
                foregroundColor:
                    AppColors.secondaryLight, // Warna teks/icon putih
                // Ambil padding dan shape dari theme jika ada, atau definisikan di sini
                padding: theme.elevatedButtonTheme.style?.padding?.resolve({}),
                // const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Contoh padding
                shape:
                    theme.elevatedButtonTheme.style?.shape?.resolve({}) ??
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ), // Contoh shape
              ),
              // ------------------------------------------------------
              child:
                  _isSubmitting
                      ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          // Warna indicator kontras (putih)
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryLight, // White
                          ),
                        ),
                      )
                      : Text(
                        "Ajukan Pencairan",
                        // Text style otomatis dari foregroundColor di styleFrom
                      ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // == HELPER WIDGETS (Dengan Input Minimalis/Modern) ==
  // ===========================================================

  // Helper Widget Saldo Tersedia (Tetap sama)
  Widget _buildSaldoTersedia(TextTheme textTheme) {
    return Container(
      key: const ValueKey('saldo_display'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.wallet_outlined,
                size: 20,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 10),
              Text(
                "Saldo Tersedia",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            _displayFormatter.format(_saldoTersedia!),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Input Decoration untuk style minimalis/modern ---
  InputDecoration _buildMinimalInputDecoration({
    required TextTheme textTheme,
    required String labelText,
    String? hintText,
    String? prefixText,
    IconData? icon,
  }) {
    // Radius & Padding yang konsisten
    const double borderRadius = 10.0;
    const EdgeInsets contentPadding = EdgeInsets.symmetric(
      vertical: 14,
      horizontal: 16,
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      // Style Label & Hint diambil dari theme, tidak perlu set di sini
      // labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryTextLight),
      // hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryTextLight.withOpacity(0.7)),

      // --- Style Minimalis ---
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight, // Warna fill terang
      contentPadding: contentPadding,

      // Border saat tidak aktif (enabled) -> sangat tipis / halus
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: AppColors.secondaryTextLight.withOpacity(
            0.3,
          ), // Warna abu-abu sangat transparan
          width: 1.0,
        ),
      ),

      // Border saat aktif (focused) -> warna primer
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: AppColors.primaryLight, // Warna primer
          width: 1.5, // Sedikit lebih tebal
        ),
      ),

      // Border saat error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: AppColors.errorLight, // Warna error
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: AppColors.errorLight, // Warna error
          width: 1.5,
        ),
      ),

      // Border default (jika diperlukan, samakan dengan enabled)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: AppColors.secondaryTextLight.withOpacity(0.3),
          width: 1.0,
        ),
      ),

      // ------------------------
      prefixText: prefixText,
      prefixStyle: textTheme.bodyLarge?.copyWith(
        color: AppColors.primaryTextLight,
      ),

      prefixIcon:
          icon != null
              ? Padding(
                // Padding di sekitar icon prefix
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.primaryLight, // Warna icon primer
                ),
              )
              : null,
      prefixIconConstraints: const BoxConstraints(
        minHeight: 40, // Sesuaikan tinggi minimum constraint
        minWidth: 40,
      ),
    );
  }
  // ----------------------------------------------------

  // Helper Dropdown Jenis Tabungan (Menggunakan InputDecoration baru)
  Widget _buildDropdownJenisTabungan(ThemeData theme, TextTheme textTheme) {
    if (!_isLoadingPage && _jenisTabunganList.isEmpty) {
      // Tampilan empty state tetap sama
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              theme.inputDecorationTheme.fillColor ??
              AppColors.secondaryBackgroundLight,
          borderRadius: BorderRadius.circular(
            12,
          ), // Samakan radius dengan input
          border: Border.all(
            color: AppColors.primaryTextLight.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.alternateLight,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pageError ??
                    "Tidak ada jenis tabungan yang bisa ditarik saat ini.",
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedJenisTabunganId,
      // --- Gunakan Decoration Minimalis ---
      decoration: _buildMinimalInputDecoration(
        textTheme: textTheme,
        labelText: 'Pilih Jenis Tabungan',
        hintText: _isLoadingPage ? 'Memuat...' : 'Tap untuk memilih',
        icon: Icons.savings_outlined,
      ),
      // ------------------------------------
      items:
          _jenisTabunganList.map((JenisTabunganItem jenis) {
            return DropdownMenuItem<int>(
              value: jenis.id,
              child: Text(
                jenis.nama,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryTextLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged:
          (_isSubmitting || _isLoadingPage)
              ? null
              : (value) {
                if (value != null) {
                  _updateSaldoTersedia(value);
                }
              },
      validator: (value) {
        if (value == null) {
          return 'Jenis tabungan harus dipilih';
        }
        return null;
      },
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.alternateLight, // Warna panah dropdown
      ),
      borderRadius: BorderRadius.circular(
        10.0,
      ), // Samakan radius dengan input border
      style: textTheme.bodyLarge?.copyWith(
        color: AppColors.primaryTextLight,
      ), // Teks terpilih
      dropdownColor: AppColors.primaryBackgroundLight, // Background menu
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // Helper TextField Umum (Menggunakan InputDecoration baru)
  Widget _buildTextField({
    required ThemeData theme,
    required TextTheme textTheme,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
    IconData? icon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      // --- Gunakan Decoration Minimalis ---
      decoration: _buildMinimalInputDecoration(
        textTheme: textTheme,
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        icon: icon,
      ),
      // ------------------------------------
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
