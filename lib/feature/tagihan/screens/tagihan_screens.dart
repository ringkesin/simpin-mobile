import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Sesuaikan path import ini dengan struktur proyek Anda
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/model/tagihan_anggota.dart';
import 'package:kkba_mobile/theme.dart';

class TagihanScreen extends StatefulWidget {
  final String? nomorPinjaman;
  final String? namaAnggota;

  const TagihanScreen({Key? key, this.nomorPinjaman, this.namaAnggota})
    : super(key: key);

  @override
  _TagihanScreenState createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  TagihanAnggotaResponse? _tagihanResponse;
  int? _pAnggotaId;

  // State untuk filter
  int? _selectedMonth;
  int? _selectedYear;
  final List<int> _monthOptions = List.generate(12, (i) => i + 1);
  final List<int> _yearOptions = List.generate(
    5,
    (i) => DateTime.now().year - i,
  ); // 5 tahun terakhir

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.nomorPinjaman == null) {
      final prefs = await SharedPreferences.getInstance();
      _pAnggotaId = prefs.getInt('p_anggota_id');
      if (_pAnggotaId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                "ID Anggota tidak ditemukan di penyimpanan lokal. Silakan login ulang.";
          });
        }
        return;
      }
    }
    _fetchTagihan(bulan: _selectedMonth, tahun: _selectedYear);
  }

  Future<void> _fetchTagihan({int? bulan, int? tahun}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      TagihanAnggotaResponse response;
      if (widget.nomorPinjaman != null) {
        response = await _apiService.getTagihanByNomorPinjaman(
          nomorPinjaman: widget.nomorPinjaman!,
          bulan: bulan,
          tahun: tahun,
        );
      } else if (_pAnggotaId != null) {
        response = await _apiService.getTagihanByAnggota(
          pAnggotaId: _pAnggotaId!,
          bulan: bulan,
          tahun: tahun,
        );
      } else {
        // Jika tidak ada nomorPinjaman dan _pAnggotaId null (misalnya setelah error load _pAnggotaId)
        // kita set error message dan jangan lanjutkan fetch.
        if (mounted) {
          setState(() {
            _isLoading = false; // Hentikan loading
            _errorMessage = "Parameter untuk mengambil tagihan tidak lengkap.";
            _tagihanResponse =
                null; // Pastikan tidak ada data lama yang ditampilkan
          });
        }
        return; // Keluar dari fungsi
      }

      if (mounted) {
        setState(() {
          _tagihanResponse = response;
          if (!response.success) {
            _errorMessage = response.message ?? "Gagal memuat data.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    _fetchTagihan(bulan: _selectedMonth, tahun: _selectedYear);
  }

  void _resetFilter() {
    setState(() {
      _selectedMonth = null;
      _selectedYear = null;
    });
    _fetchTagihan();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Daftar Tagihan';
    if (widget.nomorPinjaman != null) {
      title = 'Detail Tagihan Pinjaman';
    } else if (widget.namaAnggota != null && widget.namaAnggota!.isNotEmpty) {
      title = 'Tagihan ${widget.namaAnggota}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1.0,
      ),
      backgroundColor: AppColors.secondaryBackgroundLight,
      body: _buildBody(),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.primaryLight.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: AppColors.secondaryLight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tagihan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedMonth,
                      decoration: _customInputDecoration(
                        labelText: 'Bulan',
                        hintText: 'Pilih Bulan',
                      ),
                      items:
                          _monthOptions.map((int month) {
                            return DropdownMenuItem<int?>(
                              value: month,
                              child: Text(
                                DateFormat.MMMM(
                                  'id_ID',
                                ).format(DateTime(0, month)),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.secondaryTextLight,
                      ),
                      dropdownColor: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedYear,
                      decoration: _customInputDecoration(
                        labelText: 'Tahun',
                        hintText: 'Pilih Tahun',
                      ),
                      items:
                          _yearOptions.map((int year) {
                            return DropdownMenuItem<int?>(
                              value: year,
                              child: Text(
                                year.toString(),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.secondaryTextLight,
                      ),
                      dropdownColor: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: Text(
                        'Reset',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryTextLight,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _resetFilter,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.filter_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Tampilkan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _applyFilter,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.inter(
        color: AppColors.secondaryTextLight.withOpacity(0.9),
        fontSize: 13.5,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.secondaryTextLight.withOpacity(0.7),
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.secondaryBackgroundLight.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.grey.shade300.withOpacity(0.6),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 14.0,
      ),
    );
  }

  Widget _buildTotalTagihanCard() {
    num totalTagihanBelumLunas = 0;
    final tagihanData = _tagihanResponse?.data;

    if (tagihanData != null && tagihanData.tagihan.isNotEmpty) {
      for (var item in tagihanData.tagihan) {
        if (item.statusPembayaran != null &&
            item.statusPembayaran!.statusCode.toLowerCase() != 'paid' &&
            item.statusPembayaran!.statusCode.toLowerCase() != 'lunas') {
          totalTagihanBelumLunas += item.jumlahTagihan;
        }
      }
    }
    // Jika tidak ada tagihan sama sekali (baik dari API atau setelah filter), total tetap 0.

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.primaryLight.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: AppColors.secondaryLight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan (Belum Lunas):', // Label selalu ini
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextLight,
                ),
              ),
              Text(
                _currencyFormatter.format(totalTagihanBelumLunas),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // Warna berdasarkan apakah ada tagihan belum lunas atau tidak
                  color:
                      totalTagihanBelumLunas > 0
                          ? AppColors.errorLight
                          : AppColors.successLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Bagian total tagihan selalu ditampilkan di atas, di luar kondisi loading/error untuk list
    Widget totalTagihanWidget = _buildTotalTagihanCard();

    if (_isLoading) {
      return Column(
        children: [
          _buildFilterSection(),
          totalTagihanWidget, // Tampilkan total bahkan saat loading list
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          _buildFilterSection(),
          totalTagihanWidget, // Tampilkan total bahkan saat error
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.errorLight,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Data Tagihan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.secondaryTextLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('Coba Lagi', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed:
                          () => _fetchTagihan(
                            bulan: _selectedMonth,
                            tahun: _selectedYear,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final tagihanData = _tagihanResponse?.data;
    bool noTagihanAfterFilter =
        tagihanData != null &&
        tagihanData.tagihan.isEmpty &&
        (_selectedMonth != null || _selectedYear != null);

    // Jika tidak ada data tagihan (baik awal maupun setelah filter)
    if (tagihanData == null || tagihanData.tagihan.isEmpty) {
      return Column(
        children: [
          _buildFilterSection(),
          totalTagihanWidget, // Total tetap ditampilkan
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 60,
                      color: AppColors.secondaryTextLight.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      noTagihanAfterFilter
                          ? 'Tidak ada tagihan untuk filter yang dipilih.'
                          : 'Tidak ada data tagihan untuk ditampilkan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.secondaryTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Jika ada data tagihan
    return RefreshIndicator(
      onRefresh:
          () => _fetchTagihan(bulan: _selectedMonth, tahun: _selectedYear),
      color: AppColors.primaryLight,
      child: Column(
        children: [
          _buildFilterSection(),
          totalTagihanWidget, // Total ditampilkan di sini juga
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              itemCount: tagihanData.tagihan.length,
              itemBuilder: (context, index) {
                final item = tagihanData.tagihan[index];
                return _buildTagihanListItem(item);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanListItem(TagihanItem item) {
    final statusPembayaran = item.statusPembayaran;
    Color statusColor = Colors.grey;
    Color statusTextColor = AppColors.secondaryTextLight;
    String statusNameDisplay = statusPembayaran?.statusName ?? 'N/A';

    if (statusPembayaran != null) {
      final statusCodeLower = statusPembayaran.statusCode.toLowerCase();
      if (statusCodeLower == 'paid' || statusCodeLower == 'lunas') {
        statusColor = AppColors.successLight;
        statusTextColor = AppColors.successLight;
      } else if (statusCodeLower == 'unpaid' ||
          statusCodeLower == 'belum lunas' ||
          statusCodeLower == 'belum_lunas') {
        statusColor = AppColors.errorLight;
        statusTextColor = AppColors.errorLight;
        statusNameDisplay = "Belum Lunas";
      } else if (statusCodeLower == 'pending') {
        statusColor = AppColors.warningLight;
        statusTextColor = AppColors.warningLight;
      }
    }

    return Card(
      elevation: 2.0,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: AppColors.secondaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.uraian,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    statusNameDisplay,
                    style: GoogleFonts.inter(
                      color: statusTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Divider(color: Colors.grey.shade200, height: 12),
            const SizedBox(height: 6.0),

            if (widget.nomorPinjaman == null &&
                item.pinjamanAnggota?.nomorPinjaman.isNotEmpty == true)
              _buildInfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'No. Pinjaman:',
                value: item.pinjamanAnggota!.nomorPinjaman,
                onValueTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TagihanScreen(
                            nomorPinjaman: item.pinjamanAnggota!.nomorPinjaman,
                            namaAnggota: widget.namaAnggota,
                          ),
                    ),
                  );
                },
              ),

            _buildInfoRow(
              icon: Icons.payment_outlined,
              label: 'Jumlah Tagihan:',
              value: _currencyFormatter.format(item.jumlahTagihan),
              valueColor: AppColors.primaryLight,
            ),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Periode:',
              value: '${item.bulan}/${item.tahun}',
            ),
            if (item.tglJatuhTempo.isNotEmpty)
              _buildInfoRow(
                icon: Icons.event_busy_outlined,
                label: 'Jatuh Tempo:',
                value: item.tglJatuhTempo,
              ),

            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: 'Catatan:',
              value: item.remarks ?? '-',
            ),

            if (item.metodePembayaran?.metodeName.isNotEmpty == true)
              _buildInfoRow(
                icon: Icons.credit_card_outlined,
                label: 'Metode Bayar:',
                value: item.metodePembayaran!.metodeName,
              ),
            if (item.paidAt.isNotEmpty)
              _buildInfoRow(
                icon: Icons.check_circle_outline,
                label: 'Dibayar Pada:',
                value: item.paidAt,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onValueTap,
    Color? valueColor,
  }) {
    final bool isLink = onValueTap != null;
    final Color displayValueColor =
        valueColor ??
        (isLink ? AppColors.primaryLight : AppColors.primaryTextLight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17.0,
            color: AppColors.primaryLight.withOpacity(0.85),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.secondaryTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onValueTap,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
                  color: displayValueColor,
                  decoration:
                      isLink ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: AppColors.primaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
