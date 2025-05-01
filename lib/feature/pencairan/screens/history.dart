// lib/screens/history/history_pengajuan_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/list_pengajuan.dart'; // Import model list
import 'package:kkba_mobile/service/api_service.dart';
import 'package:kkba_mobile/theme.dart'; // Import AppColors

class HistoryPengajuanScreen extends StatefulWidget {
  const HistoryPengajuanScreen({super.key});

  @override
  State<HistoryPengajuanScreen> createState() => _HistoryPengajuanScreenState();
}

class _HistoryPengajuanScreenState extends State<HistoryPengajuanScreen> {
  final ApiService _apiService = ApiService();
  final List<PengajuanItem> _pengajuanList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String? _pageError;
  final ScrollController _scrollController = ScrollController();

  // Map untuk melacak status pembatalan per item ID
  final Map<String, bool> _isCancelling = {};

  // Formatter
  final DateFormat _dateFormat = DateFormat('dd/MM/yy HH:mm', 'id_ID');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Status Colors (Gunakan AppColors atau definisikan di sini)
  final Map<String, Color> _statusColors = {
    'PENDING': AppColors.warningLight, // Oranye/Kuning
    'DISETUJUI': AppColors.successLight, // Hijau
    'DITOLAK': AppColors.errorLight, // Merah
    'DIVERIFIKASI': AppColors.infoLight, // Biru
    'DEFAULT': AppColors.secondaryTextLight, // Abu-abu
  };

  @override
  void initState() {
    super.initState();
    _fetchPengajuan(isRefresh: true);

    // Listener untuk scroll controller (implementasi load more on scroll)
    _scrollController.addListener(() {
      // Jika scroll mencapai bagian bawah dan tidak sedang loading more dan masih ada halaman
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent -
                  100 && // Toleransi sebelum akhir
          !_isLoadingMore &&
          _hasNextPage) {
        _fetchPengajuan();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPengajuan({bool isRefresh = false}) async {
    // Jangan fetch jika sedang loading atau sudah tidak ada halaman lagi (kecuali refresh)
    if (_isLoadingMore || (!isRefresh && !_hasNextPage)) return;

    setState(() {
      if (isRefresh) {
        _isLoading = true;
        _pageError = null; // Reset error saat refresh
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      // Jika refresh, reset halaman dan list
      if (isRefresh) {
        _currentPage = 1;
        _pengajuanList.clear();
        _hasNextPage = true; // Asumsikan ada halaman lagi saat refresh
      }

      final response = await _apiService.getListPengajuanPencairan(
        page: _currentPage,
        // perPage: 15, // Sesuaikan per page jika perlu
      );

      if (mounted && response.success && response.data != null) {
        setState(() {
          _pengajuanList.addAll(response.data!.data);
          _currentPage++; // Pindah ke halaman berikutnya untuk request selanjutnya
          // Cek apakah masih ada halaman berikutnya
          _hasNextPage =
              response.data!.nextPageUrl != null &&
              response.data!.data.isNotEmpty;
        });
      } else if (mounted) {
        // Tangani jika response.success false atau data null
        // Jika ini terjadi pada page > 1, set _hasNextPage = false
        if (_currentPage > 1) {
          _hasNextPage = false;
        } else {
          // Tampilkan error jika terjadi pada halaman pertama
          _pageError = response.message ?? "Gagal memuat data pengajuan.";
          // Jika list kosong dan ada error, biarkan error ditampilkan
          // Jika list tidak kosong tapi fetch berikutnya gagal, abaikan error ini
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Tampilkan error hanya jika terjadi pada load pertama
          if (_currentPage == 1) {
            _pageError = e.toString().replaceFirst("Exception: ", "");
          } else {
            // Jika error terjadi saat load more, set hasNextPage ke false agar tidak coba lagi
            _hasNextPage = false;
            // Opsional: Tampilkan snackbar untuk error load more
            _showSnackBar(
              "Gagal memuat data selanjutnya: ${e.toString().replaceFirst("Exception: ", "")}",
              isError: true,
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _cancelPengajuan(String id, int itemIndex) async {
    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text(
            'Apakah Anda yakin ingin membatalkan pengajuan ini?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorLight,
              ),
              child: const Text('Ya, Batalkan'),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    // Jika user tidak konfirmasi (confirm bukan true)
    if (confirm != true) {
      return;
    }

    // Tandai item ini sedang dalam proses pembatalan
    setState(() {
      _isCancelling[id] = true;
    });

    try {
      final response = await _apiService.cancelPengajuanPencairan(id);
      if (mounted && response.success) {
        _showSnackBar(
          response.message ?? "Pengajuan berhasil dibatalkan.",
          isError: false,
        );
        // Hapus item dari list secara lokal untuk update UI instan
        setState(() {
          _pengajuanList.removeAt(itemIndex);
        });
        // Opsional: Panggil _fetchPengajuan(isRefresh: true) untuk data paling update dari server
        // _fetchPengajuan(isRefresh: true);
      } else if (mounted) {
        _showSnackBar(
          response.message ?? "Gagal membatalkan pengajuan.",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst("Exception: ", ""),
          isError: true,
        );
      }
    } finally {
      // Hapus tanda loading pembatalan untuk item ini
      if (mounted) {
        setState(() {
          _isCancelling.remove(id);
        });
      }
    }
  }

  // Helper untuk SnackBar (copy dari screen sebelumnya jika perlu)
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryLight,
          ), // White
        ),
        backgroundColor:
            isError ? AppColors.errorLight : AppColors.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        elevation: 4.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("History Pengajuan Pencairan"),
        // Style AppBar otomatis dari theme
      ),
      backgroundColor:
          AppColors.secondaryBackgroundLight, // Background agak abu-abu
      body: RefreshIndicator(
        onRefresh: () => _fetchPengajuan(isRefresh: true),
        color: AppColors.primaryLight, // Warna refresh indicator
        child: _buildBodyContent(textTheme),
      ),
    );
  }

  Widget _buildBodyContent(TextTheme textTheme) {
    // --- Handle Loading Awal ---
    if (_isLoading && _pengajuanList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
        ),
      );
    }

    // --- Handle Error Awal ---
    if (_pageError != null && _pengajuanList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.errorLight, size: 50),
              const SizedBox(height: 16),
              Text(
                "Gagal Memuat Data",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _pageError!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Coba Lagi"),
                onPressed: () => _fetchPengajuan(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Handle Data Kosong ---
    if (_pengajuanList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                color: AppColors.secondaryTextLight,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                "Belum Ada History",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Anda belum pernah melakukan pengajuan pencairan.",
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // --- Tampilkan List Data ---
    return ListView.builder(
      controller: _scrollController,
      itemCount:
          _pengajuanList.length +
          (_hasNextPage ? 1 : 0), // +1 untuk loading/tombol
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemBuilder: (context, index) {
        // Tampilkan item loading atau tombol load more di akhir list
        if (index == _pengajuanList.length) {
          return _buildLoadMoreIndicator();
        }

        // Tampilkan item pengajuan
        final item = _pengajuanList[index];
        return _buildPengajuanItem(
          item,
          textTheme,
          index,
        ); // Kirim index untuk delete
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
        ),
      );
    }
    // Tampilkan tombol jika tidak sedang loading dan masih ada halaman (meskipun scroll listener ada)
    // Atau bisa juga return SizedBox.shrink() jika hanya mengandalkan scroll listener
    // return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child:
            _hasNextPage
                ? OutlinedButton(
                  onPressed: _isLoadingMore ? null : _fetchPengajuan,
                  child: const Text("Muat Lebih Banyak"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(
                      color: AppColors.primaryLight.withOpacity(0.5),
                    ),
                  ),
                )
                : Text(
                  "Sudah Mencapai Akhir",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
      ),
    );
  }

  Widget _buildPengajuanItem(
    PengajuanItem item,
    TextTheme textTheme,
    int itemIndex,
  ) {
    String status = item.statusPengambilan.toUpperCase();
    Color statusColor = _statusColors[status] ?? _statusColors['DEFAULT']!;
    bool isPending = status == 'PENDING';
    bool showDetails =
        status == 'DISETUJUI'; // Hanya tampilkan detail jika disetujui

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.primaryBackgroundLight, // Warna card putih
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Kolom Kiri (Info Utama) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.tglPengajuan != null
                        ? _dateFormat.format(item.tglPengajuan!)
                        : 'Tanggal tidak valid',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryTextLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Pengajuan Sebesar ${_currencyFormat.format(item.jumlahDiambil)}",
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.jenisTabungan?.nama ?? 'Jenis Tidak Diketahui',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryTextLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12), // Spasi antar kolom
            // --- Kolom Kanan (Status & Aksi/Detail) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween, // Agar status dan tombol/detail berjauhan
              children: [
                // Status Pengambilan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(
                      0.15,
                    ), // Background status transparan
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor, // Warna teks status sesuai map
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ), // Jarak antara status dan tombol/detail
                // Tombol Hapus (jika PENDING) atau Detail (jika DISETUJUI)
                if (isPending)
                  _buildCancelButton(item.tTabunganPengambilanId, itemIndex)
                else if (showDetails)
                  _buildApprovalDetails(item, textTheme)
                else
                  const SizedBox(
                    height: 24,
                  ), // Placeholder agar tinggi konsisten jika tidak ada aksi/detail
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(String id, int itemIndex) {
    // Cek apakah item ini sedang dalam proses pembatalan
    bool cancelling = _isCancelling[id] ?? false;

    return SizedBox(
      height: 30, // Ukuran konsisten
      width: 30,
      child:
          cancelling
              ? const Padding(
                // Tampilkan loading kecil jika sedang cancelling
                padding: EdgeInsets.all(4.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.errorLight,
                  ),
                ),
              )
              : IconButton(
                padding: EdgeInsets.zero, // Hapus padding default IconButton
                iconSize: 20,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.errorLight,
                ),
                onPressed: () => _cancelPengajuan(id, itemIndex),
                tooltip: 'Batalkan Pengajuan',
                visualDensity: VisualDensity.compact, // Kurangi space visual
              ),
    );
  }

  Widget _buildApprovalDetails(PengajuanItem item, TextTheme textTheme) {
    // Tampilkan detail jika disetujui
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (item.jumlahDisetujui != null &&
            item.jumlahDisetujui != item.jumlahDiambil)
          Text(
            "Disetujui: ${_currencyFormat.format(item.jumlahDisetujui)}",
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        if (item.tglPencairan != null)
          Text(
            "Cair: ${_dateFormat.format(item.tglPencairan!)}",
            style: textTheme.bodySmall,
          ),
        if (item.catatanApprover != null &&
            item.catatanApprover!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            "Ket: ${item.catatanApprover}",
            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
} // Akhir State
