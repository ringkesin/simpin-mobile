import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Ganti dengan path import yang benar untuk file Anda ---
import '../../../service/api_service.dart'; // Lokasi ApiService Anda
import '../../../model/tabungan.dart'; // Lokasi model TabunganData Anda
import '../../../theme.dart'; // Lokasi AppTheme Anda
// ----------------------------------------------------------

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  final ApiService _apiService = ApiService(); // Inisialisasi ApiService Anda

  // State untuk pilihan bulan dan tahun
  String? _selectedBulan;
  String? _selectedTahun;

  // State untuk data dan status loading/error
  bool _isLoading = true; // Loading saat pertama kali masuk
  String? _errorMessage;
  TabunganData? _tabunganData; // Untuk menyimpan data yang berhasil diambil
  int? _pAnggotaId; // Untuk menyimpan p_anggota_id dari SharedPreferences

  // Opsi untuk dropdown
  final List<String> _bulanOptions = List.generate(
    12,
    (index) => (index + 1).toString().padLeft(2, '0'),
  ); // "01" - "12"
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

  // Fungsi untuk inisialisasi (ambil p_anggota_id, set default date, fetch data awal)
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

      // 2. Set default bulan dan tahun ke saat ini
      final now = DateTime.now();
      _selectedBulan = DateFormat('MM').format(now);
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
        // Cek jika widget masih terpasang
        setState(() {
          // Setidaknya pilihan bulan/tahun default terisi
        });
      }
    }
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _fetchData() async {
    if (_selectedBulan == null ||
        _selectedTahun == null ||
        _pAnggotaId == null) {
      setState(() {
        _errorMessage =
            "Gagal memuat: Bulan, Tahun, atau ID Anggota tidak valid.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // JANGAN reset _tabunganData di sini agar Total Card tidak hilang saat refresh
      // _tabunganData = null;
    });

    try {
      final result = await _apiService.getTabungan(
        bulan: _selectedBulan!,
        tahun: _selectedTahun!,
        pAnggotaId: _pAnggotaId,
      );

      if (mounted) {
        // Cek jika widget masih terpasang sebelum setState
        setState(() {
          if (result.success) {
            _tabunganData = result; // Update data jika sukses
          } else {
            _tabunganData =
                null; // Hapus data lama jika API return success=false
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
          _tabunganData =
              null; // Hapus data lama jika ada error network/lainnya
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil theme dari context
    final textTheme = Theme.of(context).textTheme;
    final colors =
        Theme.of(context).brightness == Brightness.light
            ? AppColors.primaryLight
            : AppColors.primaryDark; // Contoh basic light/dark

    return Scaffold(
      // AppBar akan mengambil style dari AppTheme.lightTheme.appBarTheme
      appBar: AppBar(
        title: const Text('Detail Tabungan Anggota'),
        // Tidak perlu set backgroundColor/foregroundColor di sini
        // titleTextStyle akan diambil dari theme jika didefinisikan di sana
      ),
      // Background scaffold diambil dari AppTheme.lightTheme.scaffoldBackgroundColor
      body: RefreshIndicator(
        // Tambahkan RefreshIndicator
        onRefresh: _fetchData, // Panggil _fetchData saat pull-to-refresh
        child: ListView(
          // Ganti Column ke ListView agar bisa di-scroll saat konten banyak + RefreshIndicator
          children: [
            // --- Area Total Tabungan (Ditampilkan jika data ada) ---
            // Tampilkan hanya jika tidak loading, tidak error, dan data ada
            if (!_isLoading && _errorMessage == null && _tabunganData != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  0,
                ), // Padding atas
                child: _buildTotalCard(
                  context,
                  _tabunganData!.data.totalTabungan,
                ),
              ),

            // --- Area Pilihan Bulan & Tahun ---
            _buildSelectionArea(),

            // --- Area Tampilan Data Detail / Loading / Error ---
            // Gunakan Padding bukan Expanded karena sudah di dalam ListView
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // Padding bawah
              child: _buildDataDisplayArea(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk area pilihan bulan, tahun, dan tombol submit
  Widget _buildSelectionArea() {
    // Tampilkan placeholder jika state belum siap
    if (_selectedBulan == null ||
        _selectedTahun == null ||
        _tahunOptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text("Menyiapkan pilihan..."),
        ), // Atau indikator lain
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      // Gunakan warna background sekunder dari theme jika ada, atau cardColor
      color: Theme.of(context).cardColor, // Lebih adaptif dengan theme
      margin: const EdgeInsets.symmetric(vertical: 16.0), // Beri jarak vertikal
      child: Row(
        children: [
          // Dropdown Bulan
          Expanded(
            flex: 3, // Lebih lebar
            child: DropdownButtonFormField<String>(
              value: _selectedBulan,
              items:
                  _bulanOptions.map((bulan) {
                    return DropdownMenuItem<String>(
                      value: bulan,
                      child: Text(
                        _formatNamaBulan(bulan),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ), // Terapkan theme text
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBulan = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Bulan',
                labelStyle:
                    Theme.of(context).textTheme.labelMedium, // Theme label
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ), // Sesuaikan padding
                isDense: true,
                // Warna border dll akan mengikuti theme input decoration
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Dropdown Tahun
          Expanded(
            flex: 2, // Sedikit lebih sempit dari bulan
            child: DropdownButtonFormField<String>(
              value: _selectedTahun,
              items:
                  _tahunOptions.map((tahun) {
                    return DropdownMenuItem<String>(
                      value: tahun,
                      child: Text(
                        tahun,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ), // Terapkan theme text
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
                labelStyle:
                    Theme.of(context).textTheme.labelMedium, // Theme label
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ), // Sesuaikan padding
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Submit
          SizedBox(
            // Bungkus dengan SizedBox agar bisa atur tinggi
            height: 48, // Samakan tinggi dengan dropdown (kurang lebih)
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchData,
              style: ElevatedButton.styleFrom(
                // Warna tombol akan diambil dari theme primaryColor
                // foregroundColor (warna teks/ikon) bisa diset jika perlu kontras
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ), // Padding horizontal saja
                // minimumSize: Size(40, 48) // Atur ukuran minimum jika perlu
              ).copyWith(
                // Pastikan background color diambil dari theme jika tidak diset spesifik
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return Theme.of(
                      context,
                    ).disabledColor; // Warna saat disable
                  }
                  return Theme.of(
                    context,
                  ).primaryColor; // Warna utama dari theme
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  // Tentukan warna ikon/teks berdasarkan background
                  // Jika primaryColor terang, gunakan teks gelap, dst.
                  // Contoh sederhana: selalu putih
                  return Colors.white; // Atau AppColors.primaryTextDark
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
      // Jika loading tapi sudah ada data sebelumnya (saat refresh), tampilkan data lama + indikator kecil
      if (_tabunganData != null) {
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
            _buildDetailContent(_tabunganData!.data), // Tampilkan konten lama
          ],
        );
      }
      // Jika loading awal / setelah error
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(), // Indikator lebih besar
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
              Icon(
                Icons.error_outline,
                color: AppColors.errorLight,
                size: 50,
              ), // Gunakan warna error dari theme
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                // Gunakan style dari theme, set warna error
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
                  // Style tombol akan mengikuti theme
                ),
            ],
          ),
        ),
      );
    }

    // --- Success State (Data Tersedia) ---
    if (_tabunganData != null) {
      // Tampilkan konten detail
      return _buildDetailContent(_tabunganData!.data);
    }

    // --- Default State (tidak loading, tidak error, data null) ---
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Silakan pilih bulan dan tahun, lalu tekan tombol cari untuk menampilkan data.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium, // Gunakan style dari theme
        ),
      ),
    );
  }

  // Helper widget untuk konten detail (dipisahkan agar bisa dipakai ulang saat loading refresh)
  Widget _buildDetailContent(Data data) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      // Bungkus dengan SingleChildScrollView jika kontennya bisa panjang
      physics:
          const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal karena sudah di ListView utama
      // shrinkWrap: true, // Agar SCSV menyesuaikan tinggi kontennya
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Padding kiri kanan
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Data untuk: ${_formatNamaBulan(data.bulan)} ${data.tahun}",
                // Gunakan style theme yang sesuai
                style: textTheme.titleSmall?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          _buildDetailCard(context, data), // Hanya card detail
        ],
      ),
    );
  }

  // Widget Card Total (Gunakan Text Styles dari Theme)
  Widget _buildTotalCard(BuildContext context, num total) {
    final textTheme = Theme.of(context).textTheme;
    // Warna teks di card ini mungkin perlu spesifik (putih) karena backgroundnya warna primer
    final Color textColorOnPrimary =
        Colors.white; // Atau tentukan dari theme jika ada

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      // Warna Card diambil dari theme primary color
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              'Total Tabungan',
              // Gunakan style theme, override warna jika perlu
              style: textTheme.titleMedium?.copyWith(
                color: textColorOnPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(total),
              // Gunakan style theme, override warna jika perlu
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

  // Widget Card Detail (Gunakan Text Styles dari Theme)
  Widget _buildDetailCard(BuildContext context, Data dataTabungan) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      // Warna card akan mengikuti theme
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Simpanan',
              style: textTheme.titleMedium, // Ambil style dari theme
            ),
            const SizedBox(height: 8),
            const Divider(), // Divider akan mengikuti theme
            const SizedBox(height: 8),
            _buildDetailRow('Simpanan Pokok', dataTabungan.simpananPokok),
            _buildDetailRow('Simpanan Wajib', dataTabungan.simpananWajib),
            _buildDetailRow('Tabungan Sukarela', dataTabungan.tabunganSukarela),
            _buildDetailRow('Tabungan Indir', dataTabungan.tabunganIndir),
            _buildDetailRow(
              'Kompensasi Masa Kerja',
              dataTabungan.kompensasiMasaKerja,
            ),
          ],
        ),
      ),
    );
  }

  // Widget Row Detail (Gunakan Text Styles dari Theme)
  Widget _buildDetailRow(String label, num value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            // Gunakan bodySmall atau bodyMedium, warna secondary text dari theme
            style: textTheme.bodyMedium?.copyWith(
              color: textTheme.bodySmall?.color,
            ),
          ),
          Text(
            _currencyFormatter.format(value),
            // Gunakan bodyMedium atau bodyLarge, warna primary text, weight sedikit tebal
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
