// home_widget.dart
import 'package:flutter/material.dart';
// ... other imports from your original home_widget.dart (keep them)
// import 'package:kkba_mobile/feature/list_pinjaman/screens/list_pinjaman.dart';
// import 'package:kkba_mobile/feature/shu/screens/shu.dart';
// import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
// import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
// import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart'; // Assuming this path is correct
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Di bagian atas home_widget.dart
import '../../berita/screens/berita_detail.dart';

// import 'package:kkba_mobile/feature/pencairan/screens/pencairan.dart';
// import 'dart:math' as math;

// Widget: Banner (Modified)
// Widget: Banner (Modified)
class BannerWidget extends StatelessWidget {
  final bool isLoading;
  final String? username;
  final String? nomorAnggota;
  final String? usernameError;
  final String? nomorAnggotaError;
  final VoidCallback? onGenerateQr;
  final VoidCallback? onKeanggotaanTap;

  const BannerWidget({
    Key? key,
    this.isLoading = false,
    this.username,
    this.nomorAnggota,
    this.usernameError,
    this.nomorAnggotaError,
    this.onGenerateQr,
    this.onKeanggotaanTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // PENYESUAIAN: Mengambil textTheme dari AppTheme untuk konsistensi
    final TextTheme textTheme = AppTheme.textThemeLight;
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = screenWidth * 0.52;
    double qrIconContainerSize = (cardHeight * 0.4).clamp(50.0, 65.0);

    // --- Penentuan Teks dan Style untuk Nama Pengguna ---
    String displayUsername;
    TextStyle usernameStyle =
        textTheme.headlineSmall?.copyWith(
          color: Colors.white, // Tetap putih karena di atas gambar
          fontWeight: FontWeight.bold,
          // shadows: [
          //   Shadow(
          //     color: Colors.black.withOpacity(0.4),
          //     blurRadius: 3,
          //     offset: const Offset(1, 1),
          //   ),
          // ],
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        );

    if (isLoading) {
      displayUsername = 'Memuat Nama...';
      usernameStyle = usernameStyle.copyWith(
        color: Colors.white.withOpacity(0.8),
        fontSize: 18,
      );
    } else if (usernameError != null) {
      displayUsername = usernameError!;
      usernameStyle =
          textTheme.titleMedium?.copyWith(
            // Ukuran disesuaikan
            color: AppColors.errorLight,
            fontWeight: FontWeight.bold,
          ) ??
          usernameStyle;
    } else {
      displayUsername =
          username?.isNotEmpty ?? false ? username! : 'Nama Tidak Tersedia';
    }

    // --- Penentuan Teks dan Style untuk Nomor Anggota ---
    Widget nomorAnggotaWidget;
    final nomorAnggotaBaseStyle =
        textTheme.titleMedium?.copyWith(
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w500,
          // shadows: [
          //   Shadow(
          //     color: Colors.black.withOpacity(0.3),
          //     blurRadius: 2,
          //     offset: const Offset(0.5, 0.5),
          //   ),
          // ],
        ) ??
        TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );

    if (isLoading) {
      nomorAnggotaWidget = Text(
        'Memuat...',
        style: nomorAnggotaBaseStyle.copyWith(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    } else if (nomorAnggotaError != null) {
      nomorAnggotaWidget = Text(
        nomorAnggotaError!,
        style:
            textTheme.bodyMedium?.copyWith(
              // Ukuran disesuaikan
              color: AppColors.errorLight,
              fontWeight: FontWeight.w600,
            ) ??
            nomorAnggotaBaseStyle,
      );
    } else if (nomorAnggota == null || nomorAnggota!.isEmpty) {
      nomorAnggotaWidget = Text(
        'N/A',
        style: nomorAnggotaBaseStyle.copyWith(
          fontSize: 14,
          color: Colors.white.withOpacity(0.75),
        ),
      );
    } else {
      nomorAnggotaWidget = Text(nomorAnggota!, style: nomorAnggotaBaseStyle);
    }

    return Card(
      elevation: 0.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          // 1. Background menggunakan Image.asset lagi
          Positioned.fill(
            child: Image.asset('assets/images/Card.png', fit: BoxFit.cover),
          ),

          // 2. Konten diatur dengan Padding dan Column
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 18.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bagian atas: Nama dan Nomor Anggota
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoading
                          ? 'Memuat Nama...'
                          : (username ?? 'Nama Anggota'),
                      style: usernameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: nomorAnggotaWidget,
                    ),
                  ],
                ),
                // Bagian bawah: Tombol Keanggotaan dikembalikan
                // ElevatedButton(
                //   onPressed: onKeanggotaanTap,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.white.withOpacity(0.2),
                //     elevation: 0,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 16,
                //       vertical: 8,
                //     ),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Text(
                //         'Keanggotaan',
                //         style: textTheme.labelMedium?.copyWith(
                //           color: Colors.white,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //       const SizedBox(width: 6),
                //       const Icon(
                //         Icons.arrow_forward_ios,
                //         size: 12,
                //         color: Colors.white,
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),

          // 3. Tombol QR di posisi kanan tengah
          Positioned(
            right: 18.0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    isLoading || (nomorAnggota?.isEmpty ?? true)
                        ? null
                        : onGenerateQr,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.qrCode,
                    color: AppColors.primaryLight,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget: BeritaListWidget (Telah disesuaikan dengan AppTheme)
// Di dalam file home_widget.dart

class BeritaListWidget extends StatelessWidget {
  final List<BeritaItem> beritaList;

  const BeritaListWidget({Key? key, required this.beritaList})
    : super(key: key);

  String _formatDisplayDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yy', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight;
    final limitedBeritaList = beritaList.take(5).toList();

    if (limitedBeritaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            "Saat ini belum ada berita.",
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Menggunakan LayoutBuilder untuk membuat layout 2 kartu yang presisi dan responsif
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gutter = 12.0; // Jarak antar kartu
        final double availableWidth = constraints.maxWidth;
        // Rumus: (Lebar Total - Jarak Antar Kartu) / Jumlah Kartu
        final double cardWidth = (availableWidth - gutter) / 2;
        // Membuat tinggi kartu proporsional dengan lebarnya
        final double cardHeight = cardWidth * 1.25;

        return SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: limitedBeritaList.length,
            // Padding diatur agar kartu pertama dan terakhir tidak terpotong
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemBuilder: (context, index) {
              final berita = limitedBeritaList[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == limitedBeritaList.length - 1 ? 0 : gutter,
                ),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Card(
                    elevation: 3.0,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Pastikan ID tidak null sebelum navigasi
                        if (berita.id != null && berita.id!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => BeritaDetailScreen(
                                    beritaId: berita.id!,
                                    beritaTitle: berita.title,
                                  ),
                            ),
                          );
                        } else {
                          // Opsional: Tampilkan pesan jika ID tidak valid
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Detail berita ini tidak tersedia.',
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Lapisan 1: Gambar Berita
                          (berita.thumbnailPath != null &&
                                  berita.thumbnailPath!.isNotEmpty)
                              ? Image.network(
                                berita.thumbnailPath!,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, error, stackTrace) {
                                  return Container(
                                    color: AppColors.secondaryBackgroundLight,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.secondaryTextLight,
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                color: AppColors.secondaryBackgroundLight,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.secondaryTextLight,
                                  size: 40,
                                ),
                              ),
                          // Lapisan 2: Gradasi Gelap
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.1),
                                    Colors.black.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.4, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Lapisan 3: Teks
                          Positioned(
                            bottom: 12.0,
                            left: 12.0,
                            right: 12.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 3.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withOpacity(
                                      0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    _formatDisplayDate(berita.validFrom),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  berita.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.25,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
