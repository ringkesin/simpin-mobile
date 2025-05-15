// feature/tabungan/screens/tabungan.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service/api_service.dart';
import '../../../model/tabungan.dart';
import '../../../model/mutasi_tabungan_response.dart';
import '../../../theme.dart'; // Pastikan AppColors ada di sini

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  final ApiService _apiService = ApiService();

  String? _selectedBulan;
  String? _selectedTahun;

  bool _isLoadingSaldo = true;
  String? _errorMessageSaldo;
  TabunganBulananResponse? _tabunganResponse;

  bool _isLoadingMutasi = true;
  String? _errorMessageMutasi;
  MutasiTabunganResponse? _mutasiResponse;

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
  final DateFormat _dateFormatter = DateFormat('dd MMM yy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeAndFetchData() async {
    // ... (Implementasi _initializeAndFetchData Anda tetap sama dari respons sebelumnya) ...
    setState(() {
      _isLoadingSaldo = true;
      _isLoadingMutasi = true;
      _errorMessageSaldo = null;
      _errorMessageMutasi = null;
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
      await _fetchAllData();
    } catch (e) {
      if (mounted) {
        setState(() {
          final initError =
              "Error Inisialisasi: ${e.toString().replaceFirst("Exception: ", "")}";
          _errorMessageSaldo = initError;
          _errorMessageMutasi = initError;
          _isLoadingSaldo = false;
          _isLoadingMutasi = false;
        });
      }
    }
  }

  Future<void> _fetchAllData() async {
    // ... (Implementasi _fetchAllData Anda tetap sama dari respons sebelumnya) ...
    if (_selectedBulan == null ||
        _selectedTahun == null ||
        _pAnggotaId == null) {
      final errMsg = "Gagal memuat: Bulan, Tahun, atau ID Anggota tidak valid.";
      setState(() {
        _errorMessageSaldo = errMsg;
        _errorMessageMutasi = errMsg;
        _isLoadingSaldo = false;
        _isLoadingMutasi = false;
      });
      return;
    }
    setState(() {
      _isLoadingSaldo = true;
      _isLoadingMutasi = true;
      _errorMessageSaldo = null;
      _errorMessageMutasi = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getTabungan(
          bulan: _selectedBulan!,
          tahun: _selectedTahun!,
          pAnggotaId: _pAnggotaId,
        ),
        _apiService.getMutasiTabungan(
          bulan: _selectedBulan!,
          tahun: _selectedTahun!,
          pAnggotaId: _pAnggotaId,
        ),
      ]);
      if (mounted) {
        final tabunganResult = results[0] as TabunganBulananResponse;
        final mutasiResult = results[1] as MutasiTabunganResponse;
        setState(() {
          _tabunganResponse = tabunganResult;
          _errorMessageSaldo =
              tabunganResult.success ? null : tabunganResult.message;
          _mutasiResponse = mutasiResult;
          _errorMessageMutasi =
              mutasiResult.success ? null : mutasiResult.message;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg =
            "Terjadi kesalahan: ${e.toString().replaceFirst("Exception: ", "")}";
        setState(() {
          _tabunganResponse = null;
          _mutasiResponse = null;
          _errorMessageSaldo = errorMsg;
          _errorMessageMutasi = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSaldo = false;
          _isLoadingMutasi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Bisa tetap digunakan untuk TextTheme jika AppTheme tidak lengkap

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tabungan Anggota'),
        backgroundColor: AppColors.primaryLight, // Gunakan AppColors
        foregroundColor:
            Colors.white, // Biasanya putih untuk AppColors.primaryLight
        elevation: 1,
      ),
      backgroundColor: AppColors.primaryBackgroundLight, // Gunakan AppColors
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        color: AppColors.primaryLight, // Gunakan AppColors
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start, // Agar judul "Riwayat Mutasi" rata kiri
                children: [
                  if (_isLoadingSaldo)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 75.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessageSaldo != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        20.0,
                        16.0,
                        10.0,
                      ),
                      child: Text(
                        "Gagal memuat total saldo: $_errorMessageSaldo",
                        style: TextStyle(color: AppColors.errorLight),
                        textAlign: TextAlign.center,
                      ), // Gunakan AppColors
                    )
                  else if (_tabunganResponse?.success == true &&
                      _tabunganResponse!.data?.total != null)
                    _buildTotalCard(context, _tabunganResponse!.data!.total!)
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        20.0,
                        16.0,
                        10.0,
                      ),
                      child: Text(
                        _tabunganResponse?.message ??
                            "Total saldo tidak tersedia.",
                        style: TextStyle(color: AppColors.secondaryTextLight),
                        textAlign: TextAlign.center,
                      ), // Gunakan AppColors
                    ),

                  _buildSelectionArea(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text(
                      "Riwayat Mutasi (${_formatNamaBulan(_selectedBulan ?? DateFormat('MM').format(DateTime.now()))} $_selectedTahun)",
                      style: AppTheme.textThemeLight.titleMedium?.copyWith(
                        // Gunakan AppTheme
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextLight, // Gunakan AppColors
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildMutasiDisplayArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, TotalTabungan total) {
    final textTheme = AppTheme.textThemeLight; // Prioritaskan AppTheme

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: AppColors.primaryLight, // Gunakan AppColors
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Saldo (s/d Bulan Ini)',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(
                0.9,
              ), // Teks putih di atas primaryLight
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormatter.format(total.totalBulanIniSd ?? 0),
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white, // Teks putih
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Perubahan Bulan Ini: ${_currencyFormatter.format(total.totalBulanIni ?? 0)}',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8), // Teks putih
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionArea() {
    final textTheme = AppTheme.textThemeLight;
    final theme = Theme.of(context); // Ambil theme di sini jika belum
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.secondaryTextLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );

    if (_selectedBulan == null ||
        _selectedTahun == null ||
        _tahunOptions.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text("Menyiapkan filter...")),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _selectedBulan,
              items:
                  _bulanOptions.map((bulan) {
                    // Awal dari .map()
                    return DropdownMenuItem<String>(
                      value: bulan,
                      child: Text(
                        _formatNamaBulan(bulan),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                    );
                  }).toList(), // <--- PASTIKAN .toList() ADA DI SINI
              onChanged: (value) {
                if (value != null) setState(() => _selectedBulan = value);
              },
              decoration: inputDecoration.copyWith(labelText: 'Bulan'),
              dropdownColor: AppColors.primaryBackgroundLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedTahun,
              items:
                  _tahunOptions.map((tahun) {
                    // Awal dari .map()
                    return DropdownMenuItem<String>(
                      value: tahun,
                      child: Text(
                        tahun,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                    );
                  }).toList(), // <--- PASTIKAN .toList() ADA DI SINI
              onChanged: (value) {
                if (value != null) setState(() => _selectedTahun = value);
              },
              decoration: inputDecoration.copyWith(labelText: 'Tahun'),
              dropdownColor: AppColors.primaryBackgroundLight,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            child: AspectRatio(
              aspectRatio: 1,
              child: ElevatedButton(
                onPressed:
                    _isLoadingSaldo || _isLoadingMutasi ? null : _fetchAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child:
                    _isLoadingSaldo || _isLoadingMutasi
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.search, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutasiDisplayArea() {
    final textTheme = AppTheme.textThemeLight; // Prioritaskan AppTheme

    if (_isLoadingMutasi && _mutasiResponse == null) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessageMutasi != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.secondaryTextLight,
                  size: 60,
                ), // AppColors
                const SizedBox(height: 16),
                Text(
                  "Gagal Memuat Mutasi",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextLight,
                  ),
                ), // AppColors
                const SizedBox(height: 8),
                Text(
                  _errorMessageMutasi!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ), // AppColors
                ),
                const SizedBox(height: 20),
                if (!_errorMessageMutasi!.toLowerCase().contains(
                      "id anggota",
                    ) &&
                    !_errorMessageMutasi!.toLowerCase().contains("token") &&
                    !_errorMessageMutasi!.toLowerCase().contains("sesi"))
                  ElevatedButton.icon(
                    // Kembali ke ElevatedButton
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                    onPressed: _fetchAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight, // AppColors
                      foregroundColor: Colors.white, // AppColors
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (_mutasiResponse == null ||
        !_mutasiResponse!.success ||
        _mutasiResponse!.data == null ||
        _mutasiResponse!.data!.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: AppColors.secondaryTextLight,
                  size: 60,
                ), // AppColors
                const SizedBox(height: 16),
                Text(
                  "Tidak Ada Mutasi",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextLight,
                  ),
                ), // AppColors
                const SizedBox(height: 8),
                Text(
                  _mutasiResponse?.message ??
                      "Tidak ada data mutasi untuk periode ini.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ), // AppColors
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mutasiList = _mutasiResponse!.data!.items;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = mutasiList[index];
          final bool isLastItem = index == mutasiList.length - 1;
          return Column(
            children: [
              _buildMutasiListItem(context, item),
              if (!isLastItem)
                Divider(
                  height: 1,
                  thickness: 0.5,
                ), // Gunakan AppColors jika ada, atau default
            ],
          );
        }, childCount: mutasiList.length),
      ),
    );
  }

  Widget _buildMutasiListItem(BuildContext context, MutasiTabunganItem item) {
    final textTheme = AppTheme.textThemeLight; // Prioritaskan AppTheme
    final bool isDebit = item.nilai < 0;
    final Color nilaiColor =
        isDebit ? AppColors.errorLight : AppColors.successLight;
    final IconData typeIcon =
        isDebit
            ? Icons.arrow_circle_down_rounded
            : Icons.arrow_circle_up_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(typeIcon, color: nilaiColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jenisTabungan.nama,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextLight,
                  ), // AppColors
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.tglTransaksi != null
                      ? _dateFormatter.format(item.tglTransaksi!)
                      : '-',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryTextLight,
                  ), // AppColors
                ),
                if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Catatan: ${item.catatan}",
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.secondaryTextLight.withOpacity(0.8),
                    ), // AppColors
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isDebit ? '-' : '+'}${_currencyFormatter.format(item.nilai.abs())}",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: nilaiColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormatter.format(item.nilaiSd),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryTextLight,
                ), // AppColors
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNamaBulan(String bulan) {
    // ... (Implementasi _formatNamaBulan Anda tetap sama) ...
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
