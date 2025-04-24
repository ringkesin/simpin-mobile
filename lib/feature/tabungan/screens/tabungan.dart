// feature/tabungan/screens/tabungan.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Ganti import model ---
import '../../../service/api_service.dart';
// import '../../../model/tabungan.dart'; // Hapus atau komentari ini
import '../../../model/tabungan.dart'; // <-- Import model baru
import '../../../theme.dart';
// --------------------------

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  final ApiService _apiService = ApiService();

  String? _selectedBulan;
  String? _selectedTahun;

  bool _isLoading = true;
  String? _errorMessage;
  // --- Ganti tipe state data ---
  TabunganBulananResponse? _tabunganResponse; // <-- Gunakan model response baru
  // TabunganData? _tabunganData; // Hapus atau komentari ini
  // ---------------------------
  int? _pAnggotaId;

  final List<String> _bulanOptions = List.generate(
    12,
    (index) => (index + 1).toString().padLeft(2, '0'),
  );
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

  // ... (Fungsi _initializeAndFetchData tetap sama) ...
  Future<void> _initializeAndFetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _pAnggotaId = prefs.getInt('p_anggota_id');

      if (_pAnggotaId == null) {
        throw Exception(
          'ID Anggota (p_anggota_id) tidak ditemukan di penyimpanan.',
        );
      }

      final now = DateTime.now();
      _selectedBulan = DateFormat('MM').format(now);
      _selectedTahun = DateFormat('yyyy').format(now);

      int currentYear = now.year;
      _tahunOptions =
          List.generate(
            6,
            (index) => (currentYear - 5 + index).toString(),
          ).reversed.toList();
      if (!_tahunOptions.contains(currentYear.toString())) {
        _tahunOptions.insert(0, currentYear.toString());
      }

      await _fetchData(); // Panggil fetch data setelah inisialisasi selesai
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Error Inisialisasi: ${e.toString().replaceFirst("Exception: ", "")}";
          _isLoading = false;
        });
      }
    }
  }

  // --- Update _fetchData ---
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
      // Jangan reset _tabunganResponse di sini jika ingin total card tetap ada saat refresh
    });

    try {
      // Panggil API Service (pastikan getTabungan di ApiService return TabunganBulananResponse)
      final result = await _apiService.getTabungan(
        bulan: _selectedBulan!,
        tahun: _selectedTahun!,
        pAnggotaId: _pAnggotaId,
      );

      if (mounted) {
        setState(() {
          // Simpan seluruh response
          _tabunganResponse = result;
          // Reset error jika sukses (meskipun result.success mungkin false)
          _errorMessage = result.success ? null : result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceFirst("Exception: ", "");
        setState(() {
          _tabunganResponse =
              null; // Hapus data lama jika ada error network/lainnya
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }
  // --- Akhir Update _fetchData ---

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colors = Theme.of(context).brightness == Brightness.light
    //     ? AppColors.primaryLight // ini kurang tepat, ambil dari context saja
    //     : AppColors.primaryDark;
    final theme = Theme.of(context); // Gunakan theme dari context

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tabungan Anggota'),
        // Style AppBar akan diambil dari AppTheme
      ),
      // Background scaffold diambil dari AppTheme
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: theme.primaryColor, // Sesuaikan warna refresh indicator
        child: ListView(
          // Gunakan ListView untuk scrollability + refresh
          children: [
            // --- Area Total Tabungan ---
            // Tampilkan hanya jika tidak loading DAN response ada DAN sukses
            if (!_isLoading &&
                _errorMessage == null &&
                _tabunganResponse != null &&
                _tabunganResponse!.success &&
                _tabunganResponse!.data?.total != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  20.0,
                  16.0,
                  0,
                ), // Beri padding atas
                child: _buildTotalCard(
                  context,
                  _tabunganResponse!.data!.total!,
                ), // Kirim objek TotalTabungan
              ),

            // --- Area Pilihan Bulan & Tahun ---
            _buildSelectionArea(), // Widget ini tetap sama secara fungsional
            // --- Area Tampilan Data Detail / Loading / Error ---
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
              ), // Padding
              child: _buildDataDisplayArea(),
            ),
          ],
        ),
      ),
    );
  }

  // ... (_buildSelectionArea tetap sama secara fungsional, hanya pastikan style diambil dari theme) ...
  Widget _buildSelectionArea() {
    // Tampilkan placeholder jika state belum siap
    if (_selectedBulan == null ||
        _selectedTahun == null ||
        _tahunOptions.isEmpty) {
      // Beri tinggi minimum agar tidak collapse saat loading awal
      return const SizedBox(
        height: 80,
        child: Center(child: Text("Menyiapkan filter...")),
      );
    }
    final theme = Theme.of(context); // Ambil theme

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Beri sedikit style
        color: theme.cardColor,
        // borderRadius: BorderRadius.circular(12), // Opsional: lengkungan
        // border: Border.all(color: theme.dividerColor) // Opsional: border
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ), // Beri margin horizontal juga
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedBulan,
              items:
                  _bulanOptions.map((bulan) {
                    return DropdownMenuItem<String>(
                      value: bulan,
                      child: Text(
                        _formatNamaBulan(bulan),
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBulan = value;
                  });
                }
              },
              // Ambil decoration dari theme
              decoration: InputDecoration(
                labelText: 'Bulan',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedTahun,
              items:
                  _tahunOptions.map((tahun) {
                    return DropdownMenuItem<String>(
                      value: tahun,
                      child: Text(tahun, style: theme.textTheme.bodyMedium),
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
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchData,
              // Style ElevatedButton akan diambil dari theme
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(48, 48), // Pastikan ukurannya cukup
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

  // --- Update _buildDataDisplayArea ---
  Widget _buildDataDisplayArea() {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading && _tabunganResponse == null) {
      // Loading awal
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      // Error state
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              if (!_errorMessage!.contains("ID Anggota"))
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                  onPressed: _fetchData,
                ),
            ],
          ),
        ),
      );
    }

    // Jika response tidak sukses atau data null setelah fetch
    if (_tabunganResponse != null &&
        (!_tabunganResponse!.success || _tabunganResponse!.data == null)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _tabunganResponse!.message ??
                "Data tidak ditemukan untuk periode ini.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Jika response sukses dan data ada (termasuk saat refresh)
    if (_tabunganResponse != null &&
        _tabunganResponse!.success &&
        _tabunganResponse!.data != null) {
      return _buildDetailContent(
        _tabunganResponse!.data!,
      ); // Kirim TabunganBulananData
    }

    // State default sebelum fetch pertama atau jika _tabunganResponse masih null karena alasan lain
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Silakan pilih bulan dan tahun, lalu tekan tombol cari.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ),
    );
  }
  // --- Akhir Update _buildDataDisplayArea ---

  // --- Update _buildDetailContent ---
  Widget _buildDetailContent(TabunganBulananData data) {
    // Terima TabunganBulananData
    final textTheme = Theme.of(context).textTheme;
    final detailList =
        data.detail ?? []; // Ambil list detail, default list kosong

    if (detailList.isEmpty) {
      return const Center(
        child: Text("Tidak ada rincian tabungan untuk periode ini."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Rincian untuk: ${_formatNamaBulan(data.bulan.toString().padLeft(2, '0'))} ${data.tahun}",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Gunakan Card untuk membungkus rincian
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin:
              EdgeInsets
                  .zero, // Hapus margin Card jika sudah ada padding di parent
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // Padding vertikal dalam card
            // Gunakan ListView.separated untuk memberi pemisah antar item
            child: ListView.separated(
              shrinkWrap: true, // Penting di dalam Column/ListView lain
              physics:
                  const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal
              itemCount: detailList.length,
              itemBuilder: (context, index) {
                return _buildDetailItem(
                  context,
                  detailList[index],
                ); // Panggil helper baru
              },
              separatorBuilder:
                  (context, index) => const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ), // Pemisah antar item
            ),
          ),
        ),
      ],
    );
  }
  // --- Akhir Update _buildDetailContent ---

  // --- Update _buildTotalCard ---
  Widget _buildTotalCard(BuildContext context, TotalTabungan total) {
    // Terima TotalTabungan
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final Color textColorOnPrimary =
        theme.colorScheme.onPrimary; // Ambil warna teks onPrimary dari theme

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.primaryColor, // Warna Card dari theme
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 16.0,
        ), // Sesuaikan padding
        child: Column(
          children: [
            Text(
              'Total Saldo Tabungan (s/d Bulan Ini)',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: textColorOnPrimary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currencyFormatter.format(
                total.totalBulanIniSd ?? 0,
              ), // Tampilkan total s/d bulan ini
              style: textTheme.headlineMedium?.copyWith(
                color: textColorOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Tampilkan juga perubahan bulan ini (opsional)
            Text(
              'Perubahan Bulan Ini: ${_currencyFormatter.format(total.totalBulanIni ?? 0)}',
              style: textTheme.bodyMedium?.copyWith(
                color: textColorOnPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- Akhir Update _buildTotalCard ---

  // --- Widget BARU untuk menampilkan satu item detail ---
  Widget _buildDetailItem(BuildContext context, DetailTabunganItem item) {
    final textTheme = Theme.of(context).textTheme;
    final gain = (item.nilaiBulanIni ?? 0) > 0;
    final loss = (item.nilaiBulanIni ?? 0) < 0;
    final unchanged = (item.nilaiBulanIni ?? 0) == 0;
    final Color changeColor =
        gain
            ? AppColors.successLight
            : (loss ? AppColors.errorLight : AppColors.secondaryTextLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Kiri: Jenis Tabungan & Perubahan Bulan Ini
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jenisTabungan ?? '-',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Perubahan Bln Ini:",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currencyFormatter.format(item.nilaiBulanIni ?? 0),
                      style: textTheme.bodySmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Kolom Kanan: Saldo s/d Bulan Ini
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Saldo s/d Bln Ini",
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormatter.format(item.nilaiBulanIniSd ?? 0),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // --- Akhir Widget BARU ---

  // --- HAPUS _buildDetailCard dan _buildDetailRow yang lama ---
  // Widget _buildDetailCard(BuildContext context, Data dataTabungan) { ... }
  // Widget _buildDetailRow(String label, num value) { ... }
  // -------------------------------------------------------------

  String _formatNamaBulan(String bulan) {
    // ... (kode _formatNamaBulan tetap sama) ...
    try {
      final monthNumber = int.parse(bulan);
      final date = DateTime(2000, monthNumber, 1);
      final formatter = DateFormat('MMMM', 'id_ID');
      return formatter.format(date);
    } catch (e) {
      return bulan;
    }
  }
} // Akhir State Class
