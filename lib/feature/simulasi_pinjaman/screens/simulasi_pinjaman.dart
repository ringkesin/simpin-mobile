// feature/simulasi/screens/simulasi_pinjaman_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../model/tenor_response.dart';
import '../../../model/simulasi_pinjaman_response.dart';
// GANTI IMPORT MODEL JENIS PINJAMAN
import '../../../model/jenis_pinjaman.dart'; // SESUAIKAN PATH JIKA PERLU
import '../../../service/api_service.dart';
import '../../../theme.dart';

class SimulasiPinjamanScreen extends StatefulWidget {
  const SimulasiPinjamanScreen({super.key});

  @override
  State<SimulasiPinjamanScreen> createState() => _SimulasiPinjamanScreenState();
}

class _SimulasiPinjamanScreenState extends State<SimulasiPinjamanScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _jumlahPinjamanController = TextEditingController();
  final _amountFormatter = NumberFormat("#,##0", "id_ID");

  // State untuk Jenis Pinjaman - GUNAKAN JenisPinjamanModel
  bool _isLoadingJenisPinjaman = true;
  String? _jenisPinjamanError;
  List<JenisPinjamanModel> _availableJenisPinjaman = []; // GANTI TIPE LIST
  int? _selectedJenisPinjamanId;

  // State untuk Tenor
  bool _isLoadingTenors = false;
  String? _tenorError;
  List<TenorItem> _availableTenors = [];
  int? _selectedTenor;

  // State untuk Simulasi
  bool _isLoadingSimulasi = false;
  String? _simulasiError;
  SimulasiResult? _simulasiResult;

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
    _fetchJenisPinjaman();
    _jumlahPinjamanController.addListener(_formatAmountInput);
  }

  void _formatAmountInput() {
    final text = _jumlahPinjamanController.text.replaceAll('.', '');
    if (text.isEmpty) return;
    try {
      final value = int.parse(text);
      final formattedValue = _amountFormatter.format(value);
      if (_jumlahPinjamanController.text != formattedValue) {
        _jumlahPinjamanController.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }
    } catch (e) {
      /* Abaikan */
    }
  }

  @override
  void dispose() {
    _jumlahPinjamanController.removeListener(_formatAmountInput);
    _jumlahPinjamanController.dispose();
    super.dispose();
  }

  Future<void> _fetchJenisPinjaman() async {
    setState(() {
      _isLoadingJenisPinjaman = true;
      _jenisPinjamanError = null;
      _availableJenisPinjaman = [];
      _selectedJenisPinjamanId = null;
      _availableTenors = [];
      _selectedTenor = null;
      _tenorError = null;
      _simulasiResult = null;
      _simulasiError = null;
    });
    try {
      // PANGGIL METODE DARI API SERVICE ANDA
      final jenisPinjamanList = await _apiService.getMasterJenisPinjaman();
      if (!mounted) return;
      setState(() {
        _availableJenisPinjaman = jenisPinjamanList;
        _isLoadingJenisPinjaman = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _jenisPinjamanError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingJenisPinjaman = false;
      });
    }
  }

  Future<void> _fetchTenors() async {
    if (_selectedJenisPinjamanId == null) return;

    setState(() {
      _isLoadingTenors = true;
      _tenorError = null;
      _availableTenors = [];
      _selectedTenor = null;
      _simulasiResult = null;
      _simulasiError = null;
    });
    try {
      final tenors = await _apiService.getAvailableTenors(
        jenisPinjamanId: _selectedJenisPinjamanId!,
      );
      if (!mounted) return;
      setState(() {
        _availableTenors = tenors;
        _isLoadingTenors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tenorError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingTenors = false;
      });
    }
  }

  Future<void> _calculateSimulasi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String jumlahPinjamanStr = _jumlahPinjamanController.text.replaceAll(
      '.',
      '',
    );
    final int? jumlahPinjaman = int.tryParse(jumlahPinjamanStr);

    if (jumlahPinjaman == null ||
        _selectedTenor == null ||
        _selectedJenisPinjamanId == null) {
      setState(() {
        _simulasiError =
            "Jenis pinjaman, jumlah pinjaman, dan tenor harus diisi.";
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
        jenisPinjamanId: _selectedJenisPinjamanId!,
      );
      if (!mounted) return;
      setState(() {
        _simulasiResult = result;
        _isLoadingSimulasi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _simulasiError = e.toString().replaceFirst("Exception: ", "");
        _isLoadingSimulasi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Simulasi Pinjaman',
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      backgroundColor: AppColors.primaryBackgroundLight,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hitung Estimasi Angsuran',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryTextLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih jenis pinjaman, masukkan jumlah, dan pilih jangka waktu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                ),
                const SizedBox(height: 32),

                _buildJenisPinjamanDropdown(context), // Dropdown Jenis Pinjaman
                const SizedBox(height: 20),

                TextFormField(
                  controller: _jumlahPinjamanController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Pinjaman',
                    prefixText: 'Rp ',
                    hintText: '5.000.000',
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
                    if (amount < 500000) return 'Minimal pinjaman Rp 500.000';
                    if (amount > 100000000) {
                      return 'Maksimal pinjaman Rp 100.000.000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTenorDropdown(context), // Dropdown Tenor
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon:
                      _isLoadingSimulasi
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.calculate_outlined, size: 20),
                  label: const Text('HITUNG SIMULASI'),
                  onPressed:
                      (_isLoadingSimulasi || _selectedJenisPinjamanId == null)
                          ? null
                          : _calculateSimulasi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTheme.textThemeLight.labelLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 32),
                _buildResultSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJenisPinjamanDropdown(BuildContext context) {
    if (_isLoadingJenisPinjaman) {
      return const Opacity(
        opacity: 0.5,
        child: Text("Memuat pilihan jenis pinjaman..."),
      );
    }
    if (_jenisPinjamanError != null) {
      return Text(
        "Gagal memuat jenis pinjaman: $_jenisPinjamanError",
        style: TextStyle(color: AppColors.errorLight),
      );
    }
    if (_availableJenisPinjaman.isEmpty) {
      return const Text("Tidak ada pilihan jenis pinjaman tersedia.");
    }

    return DropdownButtonFormField<int>(
      value: _selectedJenisPinjamanId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Jenis Pinjaman',
        hintText: 'Pilih jenis pinjaman...',
      ),
      // GUNAKAN JenisPinjamanModel
      items:
          _availableJenisPinjaman.map((JenisPinjamanModel item) {
            return DropdownMenuItem<int>(
              value: item.id,
              child: Text(item.nama),
            );
          }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedJenisPinjamanId = newValue;
          _availableTenors = [];
          _selectedTenor = null;
          _tenorError = null;
          _isLoadingTenors = false;
          _simulasiResult = null;
          _simulasiError = null;
          if (newValue != null) {
            _fetchTenors();
          }
        });
      },
      validator:
          (value) => value == null ? 'Silakan pilih jenis pinjaman' : null,
    );
  }

  Widget _buildTenorDropdown(BuildContext context) {
    if (_selectedJenisPinjamanId == null) {
      return Opacity(
        opacity: 0.5,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Jangka Waktu (Tenor)',
            hintText: 'Pilih jenis pinjaman terlebih dahulu',
            border: const OutlineInputBorder(), // Ensure consistent styling
            contentPadding: const EdgeInsets.symmetric(
              // Consistent padding
              horizontal:
                  12.0, // Adjusted from 10 to match DropdownButtonFormField better
              vertical: 15.0, // Adjusted to ensure text is vertically centered
            ),
            filled: true, // Optional: makes it look more like a disabled field
            fillColor: Colors.grey[100], // Optional
          ),
          child: Text(
            'Pilih jenis pinjaman dahulu',
            style: TextStyle(
              color: Colors.grey[700],
            ), // Darker grey for better readability
          ),
        ),
      );
    }
    if (_isLoadingTenors) {
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
      return const Text("Tidak ada pilihan tenor untuk jenis pinjaman ini.");
    }

    return DropdownButtonFormField<int>(
      value: _selectedTenor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Jangka Waktu (Tenor)',
        hintText: 'Pilih tenor...',
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
      validator: (value) => value == null ? 'Silakan pilih tenor' : null,
    );
  }

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
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estimasi Hasil Simulasi',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.primaryTextLight,
            fontWeight: FontWeight.bold, // Make title a bit bolder
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildResultRow(
          context,
          icon: Icons.percent_outlined,
          label: 'Margin Efektif / Tahun',
          value: _percentFormatter.format((_simulasiResult!.margin ?? 0) / 100),
        ),
        const SizedBox(height: 16),
        if (_simulasiResult!.biayaAdmin != null &&
            _simulasiResult!.biayaAdmin! > 0) ...[
          // Check if > 0
          _buildResultRow(
            context,
            icon: Icons.admin_panel_settings_outlined,
            label: 'Biaya Admin (%)', // Clarified label
            value: _percentFormatter.format(
              (_simulasiResult!.biayaAdmin!) / 100,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_simulasiResult!.biayaAdminRp != null &&
            _simulasiResult!.biayaAdminRp! > 0) ...[
          // Check if > 0
          _buildResultRow(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Biaya Admin (Rp)',
            value: _currencyFormatter.format(_simulasiResult!.biayaAdminRp!),
          ),
          const SizedBox(height: 16),
        ],

        _buildResultRow(
          context,
          icon: Icons.payment_outlined,
          label: 'Estimasi Angsuran / Bulan',
          value: _currencyFormatter.format(_simulasiResult!.angsuran ?? 0),
          isHighlight: true,
        ),
        const SizedBox(height: 20), // Increased spacing
        Text(
          '*Hasil simulasi ini adalah perkiraan dan dapat berbeda dari kondisi sebenarnya.', // Slightly more comprehensive disclaimer
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.secondaryTextLight,
            fontStyle: FontStyle.italic, // Italicize disclaimer
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final textTheme = AppTheme.textThemeLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
      children: [
        // Left part (Icon and Label)
        Expanded(
          // Allows the label to take available space and wrap if necessary
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondaryTextLight, size: 20),
              const SizedBox(width: 12),
              Expanded(
                // Ensures the text within this Row can wrap
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ),
                  softWrap: true, // Allow label to wrap
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8), // Add some spacing between label and value
        // Right part (Value)
        Text(
          value,
          textAlign: TextAlign.right,
          softWrap: false, // Crucial: Prevent value from wrapping
          overflow:
              TextOverflow
                  .ellipsis, // In case value is still too long (unlikely for formatted currency)
          style:
              (isHighlight
                  ? textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  )
                  : textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryTextLight,
                    fontWeight: FontWeight.w500,
                  )),
        ),
      ],
    );
  }
}
