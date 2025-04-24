// feature/simulasi/screens/simulasi_pinjaman_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../model/tenor_response.dart';
import '../../../model/simulasi_pinjaman_response.dart';
import '../../../service/api_service.dart';
import '../../../theme.dart'; // Import AppTheme Anda

class SimulasiPinjamanScreen extends StatefulWidget {
  const SimulasiPinjamanScreen({super.key});

  @override
  State<SimulasiPinjamanScreen> createState() => _SimulasiPinjamanScreenState();
}

class _SimulasiPinjamanScreenState extends State<SimulasiPinjamanScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _jumlahPinjamanController = TextEditingController();
  // Tambahkan formatter untuk input ribuan (opsional tapi bagus)
  final _amountFormatter = NumberFormat("#,##0", "id_ID");

  bool _isLoadingTenors = true;
  String? _tenorError;
  List<TenorItem> _availableTenors = [];
  int? _selectedTenor;

  bool _isLoadingSimulasi = false;
  String? _simulasiError;
  SimulasiResult? _simulasiResult;

  // Formatter output
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _percentFormatter = NumberFormat.decimalPercentPattern(
    locale: 'id_ID',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _fetchTenors();
    // Listener untuk format input jumlah pinjaman (opsional)
    _jumlahPinjamanController.addListener(_formatAmountInput);
  }

  // Fungsi format input jumlah pinjaman (opsional)
  void _formatAmountInput() {
    final text = _jumlahPinjamanController.text.replaceAll(
      '.',
      '',
    ); // Hapus pemisah lama
    if (text.isEmpty) return;
    try {
      final value = int.parse(text);
      final formattedValue = _amountFormatter.format(value);
      // Cek agar tidak infinite loop
      if (_jumlahPinjamanController.text != formattedValue) {
        _jumlahPinjamanController.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }
    } catch (e) {
      // Abaikan jika parsing gagal (misal saat user masih mengetik)
    }
  }

  @override
  void dispose() {
    _jumlahPinjamanController.removeListener(
      _formatAmountInput,
    ); // Hapus listener
    _jumlahPinjamanController.dispose();
    super.dispose();
  }

  Future<void> _fetchTenors() async {
    // ... (logika fetch tenor tetap sama) ...
    setState(() {
      _isLoadingTenors = true;
      _tenorError = null;
      _availableTenors = [];
      _selectedTenor = null;
    });
    try {
      final tenors = await _apiService.getAvailableTenors();
      setState(() {
        _availableTenors = tenors;
        _isLoadingTenors = false;
      });
    } catch (e) {
      setState(() {
        _tenorError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingTenors = false;
      });
    }
  }

  Future<void> _calculateSimulasi() async {
    // ... (logika calculate simulasi tetap sama) ...
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String jumlahPinjamanStr = _jumlahPinjamanController.text.replaceAll(
      '.',
      '',
    );
    final int? jumlahPinjaman = int.tryParse(jumlahPinjamanStr);

    if (jumlahPinjaman == null || _selectedTenor == null) {
      setState(() {
        _simulasiError = "Jumlah pinjaman dan tenor harus diisi.";
      });
      return;
    }

    setState(() {
      _isLoadingSimulasi = true;
      _simulasiError = null;
      _simulasiResult = null;
    });

    try {
      final result = await _apiService.postSimulasiPinjaman(
        jumlahPinjaman: jumlahPinjaman,
        tenor: _selectedTenor!,
      );
      setState(() {
        _simulasiResult = result;
        _isLoadingSimulasi = false;
      });
    } catch (e) {
      setState(() {
        _simulasiError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingSimulasi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan TextTheme dari AppTheme
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Simulasi Pinjaman',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight, // Tetap hijau untuk branding
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1, // Sedikit shadow
      ),
      // --- Ganti Background menjadi Putih ---
      backgroundColor: AppColors.primaryBackgroundLight,
      body: GestureDetector(
        // Untuk unfocus keyboard saat tap di luar
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 28.0,
          ), // Sesuaikan padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Judul Form (lebih simpel)
                Text(
                  'Hitung Estimasi Angsuran',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryTextLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan jumlah pinjaman dan pilih jangka waktu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
                const SizedBox(height: 32), // Spasi lebih lega
                // --- Input Jumlah Pinjaman ---
                TextFormField(
                  controller: _jumlahPinjamanController,
                  // Gunakan style input dari Theme
                  decoration: InputDecoration(
                    labelText: 'Jumlah Pinjaman',
                    prefixText: 'Rp ', // Prefix Rp
                    hintText: '5.000.000',
                    // Icon tidak di dalam, tapi bisa di label jika suka
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah pinjaman tidak boleh kosong';
                    }
                    final int? amount = int.tryParse(value.replaceAll('.', ''));
                    if (amount == null || amount <= 0) {
                      return 'Masukkan jumlah yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20), // Spasi antar input
                // --- Dropdown Tenor ---
                _buildTenorDropdown(context),
                const SizedBox(height: 40), // Spasi sebelum tombol
                // --- Tombol Hitung ---
                ElevatedButton.icon(
                  icon:
                      _isLoadingSimulasi
                          ? const SizedBox(
                            // Loading indicator tetap sama
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.calculate_outlined,
                            size: 20,
                          ), // Sedikit perbesar ikon?
                  label: const Text('HITUNG SIMULASI'),
                  onPressed: _isLoadingSimulasi ? null : _calculateSimulasi,
                  style: ElevatedButton.styleFrom(
                    // --- Eksplisit Gunakan Warna Primer ---
                    backgroundColor:
                        AppColors.primaryLight, // Warna background dari theme
                    foregroundColor:
                        Colors.white, // Warna teks dan ikon di atasnya
                    // --- Ambil style lain dari theme atau definisikan di sini ---
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ), // Tinggi tombol
                    shape: RoundedRectangleBorder(
                      // Bentuk tombol (sesuaikan dengan theme)
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTheme.textThemeLight.labelLarge?.copyWith(
                      // Style teks tombol
                      color: Colors.white, // Pastikan warna teks putih
                      letterSpacing: 0.5, // Sedikit spasi (opsional)
                    ),
                    elevation: 2, // Sedikit shadow (opsional)
                    // -----------------------------------------
                  ),
                ),
                const SizedBox(height: 32), // Spasi sebelum hasil
                // --- Tampilan Hasil Simulasi ---
                _buildResultSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk membangun dropdown tenor (tetap fungsional, style dari theme)
  Widget _buildTenorDropdown(BuildContext context) {
    if (_isLoadingTenors) {
      // Loading state lebih simpel
      return const Opacity(
        opacity: 0.5,
        child: Text("Memuat pilihan tenor..."),
      );
    }
    if (_tenorError != null) {
      return Text(
        "Gagal memuat tenor: $_tenorError",
        style: TextStyle(color: AppColors.errorLight),
      );
    }
    if (_availableTenors.isEmpty) {
      return const Text("Tidak ada pilihan tenor tersedia.");
    }

    return DropdownButtonFormField<int>(
      value: _selectedTenor,
      isExpanded: true,
      // Gunakan style input dari Theme
      decoration: const InputDecoration(
        labelText: 'Jangka Waktu (Tenor)',
        hintText: 'Pilih...',
        // Prefix icon bisa dihapus untuk lebih minimalis jika diinginkan
        // prefixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.primaryLight, size: 20),
      ),
      items:
          _availableTenors.map((TenorItem item) {
            return DropdownMenuItem<int>(
              value: item.tenor,
              child: Text('${item.tenor ?? '-'} Bulan'),
            );
          }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedTenor = newValue;
          _simulasiResult = null;
          _simulasiError = null;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Silakan pilih tenor';
        }
        return null;
      },
    );
  }

  // Widget untuk menampilkan hasil simulasi (lebih minimalis)
  Widget _buildResultSection(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    if (_isLoadingSimulasi) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }
    if (_simulasiError != null) {
      return Center(
        child: Text(
          "Gagal menghitung: $_simulasiError",
          style: textTheme.bodyMedium?.copyWith(color: AppColors.errorLight),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_simulasiResult == null) {
      return const SizedBox.shrink(); // Tidak tampil apa-apa jika belum ada hasil
    }

    // Tampilkan hasil tanpa Card dan Divider
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estimasi Hasil Simulasi',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.primaryTextLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24), // Spasi lebih lega
        // Gunakan helper row yang dimodifikasi
        _buildResultRow(
          context,
          icon: Icons.percent_outlined,
          label: 'Margin Efektif / Tahun',
          value: _percentFormatter.format((_simulasiResult!.margin ?? 0) / 100),
        ),
        const SizedBox(height: 16),
        _buildResultRow(
          context,
          icon: Icons.payment_outlined,
          label: 'Estimasi Angsuran / Bulan',
          value: _currencyFormatter.format(_simulasiResult!.angsuran ?? 0),
          isHighlight: true, // Tetap highlight angsuran
        ),
        const SizedBox(height: 12),
        Text(
          '*Hasil simulasi ini adalah perkiraan dan dapat berbeda tergantung pada perhitungan akhir.',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.secondaryTextLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper row hasil yang dimodifikasi (lebih modern, dengan ikon)
  Widget _buildResultRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final textTheme = AppTheme.textThemeLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon dan Label di kiri
        Row(
          children: [
            Icon(icon, color: AppColors.secondaryTextLight, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryTextLight,
              ),
            ),
          ],
        ),
        // Value di kanan
        Flexible(
          // Agar teks panjang bisa wrap jika perlu
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                (isHighlight
                    ? textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ) // Font lebih besar untuk highlight
                    : textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryTextLight,
                      fontWeight: FontWeight.w500,
                    ) // Font value standar sedikit lebih besar
                    ),
          ),
        ),
      ],
    );
  }
} // Akhir State
