// home_widget.dart
import 'package:flutter/material.dart';
// ... other imports from your original home_widget.dart (keep them)
import 'package:kkba_mobile/feature/list_pinjaman/screens/list_pinjaman.dart';
import 'package:kkba_mobile/feature/shu/screens/shu.dart';
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart'; // Assuming this path is correct
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:kkba_mobile/feature/pencairan/screens/pencairan.dart';
import 'dart:math' as math;

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
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // Perkirakan tinggi banner berdasarkan rasio aspek umum kartu (misal 85.6mm × 53.98mm ≈ 1.586)
    // Anda bisa menyesuaikan multiplier ini agar pas dengan Card.png Anda
    final double cardHeight =
        screenWidth * 0.52; // Contoh, ini akan membuat kartu cukup tinggi

    // --- Penentuan Teks dan Style untuk Nama Pengguna ---
    String displayUsername;
    TextStyle usernameStyle =
        textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
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
      usernameStyle = usernameStyle.copyWith(
        color: AppColors.errorLight,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      );
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
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: Offset(0.5, 0.5),
            ),
          ],
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
        style: nomorAnggotaBaseStyle.copyWith(
          fontSize: 12,
          color: AppColors.errorLight,
          fontWeight: FontWeight.w600,
        ),
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

    double qrIconContainerSize = (cardHeight * 0.4).clamp(
      50.0,
      65.0,
    ); // Ukuran QR relatif terhadap tinggi kartu

    return SizedBox(
      // Menggunakan SizedBox untuk mengontrol tinggi BannerWidget secara eksplisit
      height: cardHeight,
      width: double.infinity, // Mengambil lebar penuh dari parent
      child: Card(
        elevation: 6.0,
        clipBehavior:
            Clip.antiAlias, // Penting agar gambar tidak keluar dari rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        margin: EdgeInsets.zero, // Card tidak memberi margin sendiri
        child: Stack(
          // Menggunakan Stack untuk menumpuk gambar dan konten
          fit: StackFit.expand, // Membuat Stack mengisi Card
          children: [
            // Lapisan 1: Gambar Latar Belakang Penuh
            Image.asset(
              'assets/images/Card.png',
              fit: BoxFit.cover, // Memastikan gambar menutupi seluruh area Card
            ),

            // Lapisan 2: Konten (Nama, No Anggota, Tombol)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 18.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween, // Mendorong tombol keanggotaan ke bawah
                children: [
                  // Bagian atas: Nama dan Nomor Anggota (tanpa QR di sini)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayUsername,
                        style: usernameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: nomorAnggotaWidget,
                        ),
                      ),
                    ],
                  ),

                  // Bagian bawah: Tombol Keanggotaan
                  if (onKeanggotaanTap != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: onKeanggotaanTap,
                        icon: Icon(
                          Icons.card_membership_rounded,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        label: Text(
                          'Keanggotaan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.95),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 10.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Lapisan 3: Tombol QR di tengah kanan secara vertikal
            if (onGenerateQr != null)
              Positioned(
                right: 18.0, // Jarak dari kanan
                top: 0,
                bottom: 0,
                child: Center(
                  // Untuk memusatkan QR secara vertikal
                  child: InkWell(
                    onTap:
                        (isLoading ||
                                nomorAnggotaError != null ||
                                nomorAnggota == null ||
                                nomorAnggota!.isEmpty)
                            ? null
                            : onGenerateQr,
                    borderRadius: BorderRadius.circular(
                      qrIconContainerSize / 2,
                    ),
                    child: Container(
                      width: qrIconContainerSize,
                      height: qrIconContainerSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.primaryLight,
                        size: qrIconContainerSize * 0.55,
                        semanticLabel: 'Tampilkan QR Code',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget: Categories (This can be removed or commented out if not used elsewhere)
// class CategoriesWidget extends StatelessWidget { ... }
// For this solution, we are building the menus directly in home_screen.dart,
// so CategoriesWidget as it was is no longer needed here. If you use it on other screens, keep it.

// Widget: BeritaListWidget (Keep as is, or adjust styling if needed)
// The existing BeritaListWidget is quite good. We'll ensure its title is handled in home_screen.dart
class BeritaListWidget extends StatelessWidget {
  final List<BeritaItem> beritaList;

  const BeritaListWidget({Key? key, required this.beritaList})
    : super(key: key);

  String _formatDisplayDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      // Format tanggal seperti "21 Mei 2025"
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

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

    // Penyesuaian ukuran kartu berita agar lebih mirip dengan gambar
    double responsiveCardWidth = (screenWidth * 0.55).clamp(180.0, 220.0);
    // Tinggi kartu bisa dibuat lebih proporsional dengan gambar yang full
    // Misal, rasio 3:4 (lebar:tinggi) atau sesuaikan dengan preferensi Anda
    double responsiveCardHeight =
        responsiveCardWidth * 1.15; // Contoh rasio tinggi

    return SizedBox(
      height:
          responsiveCardHeight + 8, // Tambah sedikit padding untuk shadow Card
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: limitedBeritaList.length,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        itemBuilder: (context, index) {
          final berita = limitedBeritaList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: responsiveCardWidth,
              height: responsiveCardHeight, // Terapkan tinggi kartu
              child: Card(
                elevation: 3.0,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14.0,
                  ), // Radius lebih besar
                ),
                clipBehavior:
                    Clip.antiAlias, // Penting untuk efek gambar penuh dan gradasi
                child: InkWell(
                  onTap: () {
                    print("Berita tapped: ${berita.id} - ${berita.title}");
                    // TODO: Navigasi ke detail berita
                  },
                  child: Stack(
                    fit: StackFit.expand, // Membuat Stack mengisi penuh Card
                    children: [
                      // Lapisan 1: Gambar Berita (Full)
                      (berita.thumbnailPath != null &&
                              berita.thumbnailPath!.isNotEmpty)
                          ? Image.network(
                            berita.thumbnailPath!,
                            fit: BoxFit.cover, // Gambar mengisi penuh
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
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey[500],
                                  size: 40,
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[500],
                              size: 40,
                            ),
                          ),

                      // Lapisan 2: Gradasi Gelap di Bawah
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(
                                  0.05,
                                ), // Mulai sedikit gelap
                                Colors.black.withOpacity(
                                  0.75,
                                ), // Lebih gelap di bawah
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [
                                0.4,
                                0.6,
                                1.0,
                              ], // Kontrol penyebaran gradasi
                            ),
                          ),
                        ),
                      ),

                      // Lapisan 3: Teks (Tanggal dan Judul)
                      Positioned(
                        bottom: 10.0,
                        left: 10.0,
                        right: 10.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tanggal Berita
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(
                                  0.85,
                                ), // Warna background tanggal (misal: hijau tema)
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                _formatDisplayDate(berita.validFrom),
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize:
                                      9.5, // Ukuran font tanggal lebih kecil
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            // Judul Berita
                            Text(
                              berita.title,
                              style: textTheme.titleMedium?.copyWith(
                                // Bisa juga titleSmall
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15, // Sesuaikan ukuran font judul
                                height: 1.25, // Line height
                                shadows: [
                                  // Tambahkan shadow tipis agar lebih terbaca
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 2, // Batasi judul menjadi 2 baris
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
  }
}
