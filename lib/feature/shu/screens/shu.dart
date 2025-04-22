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
  final ApiService _apiService = ApiService(); // Inisialisasi ApiService Anda

  // State untuk pilihan tahun
  String? _selectedTahun;

  // State untuk data dan status loading/error
  bool _isLoading = true;
  String? _errorMessage;
  InfoSHU? _shuData; // Untuk menyimpan data SHU
  int? _pAnggotaId; // Untuk menyimpan p_anggota_id dari SharedPreferences

  // Opsi untuk dropdown tahun
  List<String> _tahunOptions = []; // Akan diisi di initState

  // Formatter Mata Uang
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData(); // Panggil fungsi inisialisasi
  }

  // Fungsi untuk inisialisasi (ambil p_anggota_id, set default tahun, fetch data awal)
  Future<void> _initializeAndFetchData() async {
    setState(() {
      _isLoading = true; // Set loading true saat inisialisasi
      _errorMessage = null; // Reset error message
    });

    try {
      // 1. Ambil p_anggota_id dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _pAnggotaId = prefs.getInt('p_anggota_id'); // Ganti key jika perlu

      if (_pAnggotaId == null) {
        throw Exception(
          'ID Anggota (p_anggota_id) tidak ditemukan di penyimpanan.',
        );
      }

      // 2. Set default tahun ke saat ini
      final now = DateTime.now();
      _selectedTahun = DateFormat('yyyy').format(now);

      // 3. Siapkan opsi tahun
      int currentYear = now.year;
      _tahunOptions =
          List.generate(
            6,
            (index) => (currentYear - 5 + index).toString(),
          ).reversed.toList();
      if (!_tahunOptions.contains(currentYear.toString())) {
        _tahunOptions.insert(0, currentYear.toString());
      }

      // 4. Fetch data untuk pertama kali
      await _fetchData();
    } catch (e) {
      setState(() {
        _errorMessage = "Error Inisialisasi: ${e.toString()}";
        _isLoading = false;
      });
    } finally {
      // Pastikan state diupdate meskipun ada error sebelum fetch data
      if (mounted) {
        setState(() {
          // Setidaknya pilihan tahun default terisi
        });
      }
    }
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _fetchData() async {
    if (_selectedTahun == null || _pAnggotaId == null) {
      setState(() {
        _errorMessage = "Gagal memuat: Tahun atau ID Anggota tidak valid.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // JANGAN reset _shuData di sini agar Total Card tidak hilang saat refresh
      // _shuData = null;
    });

    try {
      final result = await _apiService.getShu(
        tahun: _selectedTahun!,
        pAnggotaId: _pAnggotaId,
      );

      if (mounted) {
        setState(() {
          if (result.success) {
            _shuData = result; // Update data jika sukses
          } else {
            _shuData = null; // Hapus data lama jika API return success=false
            _errorMessage = result.message;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        setState(() {
          _shuData = null; // Hapus data lama jika ada error network/lainnya
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil tema dari context
    final textTheme = Theme.of(context).textTheme;
    final colors =
        Theme.of(context).brightness == Brightness.light
            ? AppColors.primaryLight
            : AppColors.primaryDark; // Contoh basic light/dark

    return Scaffold(
      // AppBar akan mengambil style dari AppTheme.lightTheme.appBarTheme
      appBar: AppBar(
        title: const Text('Data SHU Anggota'),
        // Tidak perlu set backgroundColor/foregroundColor di sini
        // titleTextStyle akan diambil dari theme jika didefinisikan di sana
      ),
      // Background scaffold diambil dari AppTheme.lightTheme.scaffoldBackgroundColor
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          children: [
            // --- Area Total SHU (Ditampilkan jika data ada) ---
            // Tampilkan hanya jika tidak loading, tidak error, dan data ada
            if (!_isLoading && _errorMessage == null && _shuData != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  0,
                ), // Padding atas
                child: _buildTotalCard(context, _shuData!.data.shuDiterima),
              ),

            // --- Area Pilihan Tahun ---
            _buildSelectionArea(),

            // --- Area Tampilan Data Detail / Loading / Error ---
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildDataDisplayArea(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk area pilihan tahun dan tombol submit
  Widget _buildSelectionArea() {
    // Tampilkan placeholder jika state belum siap
    if (_selectedTahun == null || _tahunOptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text("Menyiapkan pilihan..."), // Atau indikator lain
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // Dropdown Tahun
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedTahun,
              items:
                  _tahunOptions.map((tahun) {
                    return DropdownMenuItem<String>(
                      value: tahun,
                      child: Text(
                        tahun,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTahun = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Tahun',
                labelStyle: Theme.of(context).textTheme.labelMedium,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Submit
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return Theme.of(context).disabledColor;
                  }
                  return Theme.of(context).primaryColor;
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  return Colors.white;
                }),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.search, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan data detail / loading / error
  Widget _buildDataDisplayArea() {
    final textTheme = Theme.of(context).textTheme;

    // --- Loading State ---
    if (_isLoading) {
      // Jika loading tapi sudah ada data sebelumnya
      if (_shuData != null) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            _buildDetailContent(_shuData!.data),
          ],
        );
      }
      // Jika loading awal
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // --- Error State ---
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.errorLight, size: 50),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorLight,
                ),
              ),
              const SizedBox(height: 20),
              if (!_errorMessage!.contains("ID Anggota"))
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  onPressed: _fetchData,
                ),
            ],
          ),
        ),
      );
    }

    // --- Success State (Data Tersedia) ---
    if (_shuData != null) {
      return _buildDetailContent(_shuData!.data);
    }

    // --- Default State (tidak loading, tidak error, data null) ---
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Silakan pilih tahun, lalu tekan tombol cari untuk menampilkan data.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ),
    );
  }

  // Helper widget untuk konten detail
  Widget _buildDetailContent(ShuData data) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Data untuk Tahun: ${data.tahun}",
                style: textTheme.titleSmall?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          _buildDetailCard(context, data),
        ],
      ),
    );
  }

  // Widget Card Total
  Widget _buildTotalCard(BuildContext context, num total) {
    final textTheme = Theme.of(context).textTheme;
    final Color textColorOnPrimary = Colors.white;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              'Total SHU Diterima',
              style: textTheme.titleMedium?.copyWith(
                color: textColorOnPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(total),
              style: textTheme.headlineMedium?.copyWith(
                color: textColorOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Card Detail
  Widget _buildDetailCard(BuildContext context, ShuData data) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rincian SHU', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('SHU Diterima', data.shuDiterima),
            _buildDetailRow('SHU Dibagi', data.shuDibagi),
            _buildDetailRow('SHU Ditabung', data.shuDitabung),
            _buildDetailRow('SHU Tahun Lalu', data.shuTahunLalu),
          ],
        ),
      ),
    );
  }

  // Widget Row Detail
  Widget _buildDetailRow(String label, num value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: textTheme.bodySmall?.color,
            ),
          ),
          Text(
            _currencyFormatter.format(value),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Fungsi helper nama bulan (Tidak berubah)
  String _formatNamaBulan(String bulan) {
    try {
      final monthNumber = int.parse(bulan);
      final date = DateTime(2000, monthNumber, 1);
      final formatter = DateFormat('MMMM', 'id_ID');
      return formatter.format(date);
    } catch (e) {
      return bulan;
    }
  }
}
