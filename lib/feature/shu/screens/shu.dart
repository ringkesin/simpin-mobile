import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Ganti dengan path import yang benar untuk file Anda ---
import '../../../service/api_service.dart'; // Lokasi ApiService Anda
import '../../../model/shu.dart'; // Lokasi model InfoSHU Anda
import '../../../theme.dart'; // Lokasi AppTheme Anda
// ----------------------------------------------------------

class ShuPage extends StatefulWidget {
  const ShuPage({super.key});

  @override
  State<ShuPage> createState() => _ShuPageState();
}

class _ShuPageState extends State<ShuPage> {
  final ApiService _apiService = ApiService();

  String? _selectedTahun;
  bool _isLoading = true;
  String? _errorMessage;
  InfoSHU? _shuData;
  int? _pAnggotaId;
  List<String> _tahunOptions = [];

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    if (!mounted) return; // Cek mounted di awal
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _pAnggotaId = prefs.getInt('p_anggota_id');

      if (_pAnggotaId == null) {
        throw Exception('ID Anggota (p_anggota_id) tidak ditemukan.');
      }

      final now = DateTime.now();
      _selectedTahun = DateFormat('yyyy').format(now);

      int currentYear = now.year;
      // Generate opsi tahun (misal: 5 tahun ke belakang + tahun ini)
      _tahunOptions =
          List.generate(
            6,
            (index) => (currentYear - 5 + index).toString(),
          ).reversed.toList();
      // Pastikan tahun ini ada di list jika belum
      if (!_tahunOptions.contains(currentYear.toString())) {
        _tahunOptions.insert(0, currentYear.toString());
        // Pastikan _selectedTahun valid jika tahun ini baru ditambahkan
        if (!_tahunOptions.contains(_selectedTahun)) {
          _selectedTahun = _tahunOptions.first;
        }
      }

      // Panggil fetch data setelah semua siap
      if (mounted) {
        // Cek mounted lagi sebelum setState dan fetch
        setState(() {}); // Update state untuk _tahunOptions dan _selectedTahun
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        // Cek mounted sebelum setState error
        setState(() {
          _errorMessage =
              "Error Inisialisasi: ${e.toString().replaceFirst("Exception: ", "")}";
          _isLoading = false;
        });
      }
    }
    // Tidak perlu finally di sini karena fetch data sudah dipanggil di try
  }

  Future<void> _fetchData() async {
    // Cek _selectedTahun dan _pAnggotaId sebelum fetch
    if (_selectedTahun == null || _pAnggotaId == null) {
      if (mounted) {
        // Cek mounted sebelum setState error
        setState(() {
          _errorMessage = "Gagal memuat: Tahun atau ID Anggota belum siap.";
          _isLoading = false; // Hentikan loading jika parameter tidak valid
        });
      }
      return;
    }

    if (!mounted) return; // Cek mounted sebelum memulai fetch
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // JANGAN reset _shuData agar nilai sebelumnya tidak hilang saat loading
    });

    try {
      final result = await _apiService.getShu(
        tahun: _selectedTahun!,
        pAnggotaId: _pAnggotaId,
      );

      if (mounted) {
        // Cek mounted sebelum setState hasil
        setState(() {
          if (result.success) {
            _shuData = result;
          } else {
            _shuData = null; // Reset data jika API gagal
            _errorMessage = result.message ?? "Gagal mengambil data SHU.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Cek mounted sebelum setState error
        String errorMsg = e.toString().replaceFirst("Exception: ", "");
        setState(() {
          _shuData = null; // Reset data jika terjadi error
          _errorMessage = "Error: $errorMsg";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi SHU'), // Judul lebih umum
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primaryLight, // Sesuaikan warna refresh indicator
        child: ListView(
          // Gunakan ListView agar bisa di-refresh
          padding: const EdgeInsets.all(16.0), // Padding utama
          children: [
            // 1. Area Seleksi Tahun (Hanya Dropdown)
            _buildYearSelectionDropdown(),

            const SizedBox(height: 24), // Jarak
            // 2. Area Tampilan Data (Loading/Error/Kartu Total)
            _buildDataDisplayArea(),

            const SizedBox(height: 32), // Jarak tambahan di bawah
            // 3. (Opsional) Informasi Tambahan/Ilustrasi
            _buildInformativeSection(),
          ],
        ),
      ),
    );
  }

  // Widget HANYA untuk Dropdown Tahun
  Widget _buildYearSelectionDropdown() {
    // Tampilkan placeholder jika state belum siap
    if (_tahunOptions.isEmpty) {
      return const Center(child: Text("Memuat pilihan tahun..."));
    }
    // Tampilkan dropdown jika tahun sudah siap
    return DropdownButtonFormField<String>(
      value: _selectedTahun, // Pastikan value ada di items
      items:
          _tahunOptions.map((tahun) {
            return DropdownMenuItem<String>(
              value: tahun,
              child: Text(
                tahun,
                style: Theme.of(context).textTheme.bodyLarge,
              ), // Style lebih besar
            );
          }).toList(),
      onChanged: (value) {
        if (value != null && value != _selectedTahun) {
          setState(() {
            _selectedTahun = value;
            // JANGAN reset _shuData di sini agar kartu lama tetap tampil
            // saat loading data baru
          });
          // Langsung fetch data saat tahun berubah
          _fetchData();
        }
      },
      decoration: InputDecoration(
        labelText: 'Pilih Tahun SHU',
        labelStyle: Theme.of(context).textTheme.labelMedium,
        // Gunakan InputDecoratioTheme dari AppTheme
        // border: const OutlineInputBorder(),
        // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(Icons.calendar_today, size: 20), // Tambah ikon
      ),
      // Style dropdown
      style: Theme.of(context).textTheme.bodyLarge,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: Theme.of(context).primaryColor,
      ),
      isExpanded: true, // Agar dropdown memenuhi lebar
    );
  }

  // Widget untuk menampilkan data (Loading/Error/Kartu Total)
  Widget _buildDataDisplayArea() {
    // --- Loading State ---
    if (_isLoading && _shuData == null) {
      // Loading awal (belum ada data sama sekali)
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // --- Error State ---
    // Tampilkan error HANYA jika tidak sedang loading DAN ada pesan error
    if (!_isLoading && _errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.errorLight,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.errorLight),
              ),
              const SizedBox(height: 20),
              // Tombol coba lagi hanya jika error bukan karena ID tidak ditemukan
              if (!_errorMessage!.contains("ID Anggota"))
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                  onPressed: _fetchData, // Panggil _fetchData lagi
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // --- Success State (atau Loading tapi ada data lama) ---
    // Tampilkan kartu total jika ada data (_shuData tidak null)
    // Ini akan menampilkan data lama saat loading data baru
    if (_shuData != null) {
      return Column(
        children: [
          // Indikator loading di atas kartu jika sedang loading data baru
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Kartu Total SHU
          _buildTotalShuCard(
            context,
            _shuData!.data.shuDiterima, // Ambil total
            _shuData!.data.tahun, // Ambil tahun dari data
          ),
        ],
      );
    }

    // --- Default/Initial State (jika tidak loading, tidak error, data null) ---
    // Ini seharusnya jarang terjadi setelah inisialisasi fetch pertama
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Text(
          "Data SHU untuk tahun $_selectedTahun belum tersedia.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  // Widget Kartu Total SHU yang diperbarui
  Widget _buildTotalShuCard(BuildContext context, num total, String tahun) {
    final textTheme = Theme.of(context).textTheme;
    // Warna teks kontras di atas warna primer
    final Color textColorOnPrimary = Theme.of(context).colorScheme.onPrimary;

    return Card(
      elevation: 4.0, // Beri shadow lebih
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: Theme.of(context).primaryColor, // Warna primer dari theme
      child: Container(
        // Tambahkan sedikit gradient atau pattern jika diinginkan
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(...)
        //   borderRadius: BorderRadius.circular(16.0),
        // ),
        padding: const EdgeInsets.symmetric(
          vertical: 32.0,
          horizontal: 24.0,
        ), // Padding lebih besar
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Tengahkan konten
          crossAxisAlignment: CrossAxisAlignment.center, // Rata tengah
          children: [
            Text(
              'Total SHU Diterima',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                // Style lebih besar
                color: textColorOnPrimary.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 4),
            // Tampilkan Tahun di bawah judul
            Text(
              'Tahun $tahun',
              style: textTheme.bodyMedium?.copyWith(
                color: textColorOnPrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16), // Jarak lebih besar
            Text(
              _currencyFormatter.format(total),
              textAlign: TextAlign.center,
              style: textTheme.displayMedium?.copyWith(
                // Font sangat besar
                color: textColorOnPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1, // Sedikit spasi antar huruf
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Opsional untuk Informasi Tambahan
  Widget _buildInformativeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      margin: const EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.5), // Warna background subtle
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "SHU (Sisa Hasil Usaha) adalah keuntungan bersih koperasi yang dibagikan kepada anggota berdasarkan partisipasi mereka.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
