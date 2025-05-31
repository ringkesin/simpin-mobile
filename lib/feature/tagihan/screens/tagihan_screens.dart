import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import ini dengan struktur proyek Anda
import 'package:kkba_mobile/service/api_service.dart'; // Asumsi api_service.dart ada di root/lib
import 'package:kkba_mobile/model/tagihan_anggota.dart'; // Asumsi model ada di lib/model
import 'package:kkba_mobile/theme.dart'; // Asumsi theme.dart ada di lib

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

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
        setState(() {
          _isLoading = false;
          _errorMessage =
              "ID Anggota tidak ditemukan di penyimpanan lokal. Silakan login ulang.";
        });
        return;
      }
    }
    _fetchTagihan();
  }

  Future<void> _fetchTagihan({int? bulan, int? tahun}) async {
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
        throw Exception("Parameter untuk mengambil tagihan tidak lengkap.");
      }

      if (mounted) {
        setState(() {
          _tagihanResponse = response;
          if (!response.success) {
            _errorMessage = response.message;
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

  @override
  Widget build(BuildContext context) {
    String title = 'Daftar Tagihan';
    if (widget.nomorPinjaman != null) {
      title = 'Detail Tagihan Pinjaman';
    } else if (widget.namaAnggota != null && widget.namaAnggota!.isNotEmpty) {
      title = 'Tagihan ${widget.namaAnggota}';
    }

    return Scaffold(appBar: AppBar(title: Text(title)), body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_tagihanResponse == null ||
        !_tagihanResponse!.success ||
        _tagihanResponse!.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _tagihanResponse?.message ?? 'Gagal memuat data tagihan.',
          ),
        ),
      );
    }

    final tagihanData = _tagihanResponse!.data!;

    if (tagihanData.tagihan.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Tidak ada data tagihan untuk ditampilkan.'),
        ),
      );
    }

    // --- MODIFIKASI DIMULAI DI SINI ---
    // Hitung total tagihan yang belum 'paid'
    num totalTagihanBelumLunas = 0;
    String labelTotalTagihan = 'Total Tagihan (Belum Lunas):';

    if (widget.nomorPinjaman != null) {
      // Jika melihat detail per nomor pinjaman, total_tagihan dari API bisa jadi sudah spesifik untuk pinjaman itu.
      // Namun, jika tetap ingin menghitung yang belum lunas dari daftar item:
      for (var item in tagihanData.tagihan) {
        if (item.statusPembayaran != null &&
            item.statusPembayaran!.statusCode.toLowerCase() != 'paid' &&
            item.statusPembayaran!.statusCode.toLowerCase() !=
                'lunas' // Tambahkan pengecekan "lunas" juga
                ) {
          totalTagihanBelumLunas += item.jumlahTagihan;
        }
      }
    } else {
      // Jika melihat semua tagihan anggota, hitung yang belum lunas
      for (var item in tagihanData.tagihan) {
        if (item.statusPembayaran != null &&
            item.statusPembayaran!.statusCode.toLowerCase() != 'paid' &&
            item.statusPembayaran!.statusCode.toLowerCase() != 'lunas') {
          totalTagihanBelumLunas += item.jumlahTagihan;
        }
      }
      // Jika tidak ada tagihan belum lunas sama sekali, bisa tampilkan total dari API atau 0
      if (totalTagihanBelumLunas == 0 &&
          tagihanData.tagihan.any(
            (item) =>
                item.statusPembayaran?.statusCode.toLowerCase() == 'paid' ||
                item.statusPembayaran?.statusCode.toLowerCase() == 'lunas',
          )) {
        // labelTotalTagihan = 'Semua Tagihan Lunas. Total Keseluruhan:'; // Opsional: ubah label
        // totalTagihanBelumLunas = tagihanData.totalTagihan; // Opsional: tampilkan total dari API
      }
    }
    // --- MODIFIKASI SELESAI DI SINI ---

    return RefreshIndicator(
      onRefresh: () => _fetchTagihan(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labelTotalTagihan, // Gunakan label yang sudah disiapkan
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currencyFormatter.format(
                        totalTagihanBelumLunas,
                      ), // Gunakan total yang sudah dihitung
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
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
    Color statusColor =
        Colors.grey; // Warna default untuk status tidak diketahui
    String statusNameDisplay = statusPembayaran?.statusName ?? 'N/A';

    if (statusPembayaran != null) {
      final statusCodeLower = statusPembayaran.statusCode.toLowerCase();
      if (statusCodeLower == 'paid' || statusCodeLower == 'lunas') {
        statusColor = AppColors.successLight; // Hijau untuk lunas
      } else if (statusCodeLower == 'unpaid' ||
          statusCodeLower == 'belum lunas' ||
          statusCodeLower == 'belum_lunas') {
        statusColor = AppColors.errorLight; // Merah untuk belum lunas
        statusNameDisplay = "Belum Lunas"; // Konsistensi display
      } else if (statusCodeLower == 'pending') {
        statusColor = AppColors.warningLight; // Oranye untuk pending
      }
      // Tambahkan kondisi lain jika ada status code lain dari API
    }

    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.uraian,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    statusNameDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8.0),

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
                            namaAnggota:
                                widget
                                    .namaAnggota, // Teruskan nama anggota jika ada
                          ),
                    ),
                  );
                },
              ),

            _buildInfoRow(
              icon: Icons.payment_outlined,
              label: 'Jumlah Tagihan:',
              value: _currencyFormatter.format(item.jumlahTagihan),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18.0,
            color: AppColors.primaryLight,
          ), // Gunakan warna dari AppColors
          const SizedBox(width: 8.0),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: GestureDetector(
              onTap: onValueTap,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      onValueTap != null
                          ? AppColors.primaryLight
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color, // Warna link jika bisa di-tap
                  decoration:
                      onValueTap != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
