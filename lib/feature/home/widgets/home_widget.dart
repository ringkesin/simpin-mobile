import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/shu/screens/shu.dart';
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart';
import '../../../page_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:kkba_mobile/model/berita.dart';
import 'package:kkba_mobile/feature/pencairan/screens/pencairan.dart';

// Widget: Header
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Welcome, Alwi Ghozali",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class BannerWidget extends StatelessWidget {
  // --- Parameter Constructor (Tetap sama) ---
  final bool isLoading;
  final String? error;
  final String? username;
  final String? nomorAnggota;
  final VoidCallback? onGenerateQr;

  const BannerWidget({
    Key? key,
    this.isLoading = false,
    this.error,
    this.username,
    this.nomorAnggota,
    this.onGenerateQr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan Theme yang aktif dari context
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    // --- Logika Tampilan Username (Tetap sama) ---
    String displayUsername;
    TextStyle usernameStyle =
        textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)) ??
        const TextStyle(color: Colors.white70, fontSize: 16);

    if (isLoading) {
      displayUsername = 'Memuat Nama...';
      usernameStyle = usernameStyle.copyWith(
        color: Colors.white.withOpacity(0.7),
      );
    } else if (error != null) {
      displayUsername = 'Gagal Memuat Nama';
      usernameStyle = usernameStyle.copyWith(color: AppColors.warningLight);
    } else {
      displayUsername = username?.isNotEmpty ?? false ? username! : 'Pengguna';
    }

    // --- Logika Tampilan nomorAnggota (Tetap sama) ---
    Widget nomorAnggotaWidget;
    final nomorAnggotaTextStyle =
        textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        );

    if (isLoading) {
      nomorAnggotaWidget = Text(
        'Memuat No. Anggota...',
        style: nomorAnggotaTextStyle.copyWith(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      );
    } else if (error != null) {
      nomorAnggotaWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.warningLight, size: 20),
          const SizedBox(width: 8),
          Text(
            'Gagal Memuat No. Anggota',
            style:
                textTheme.bodyLarge?.copyWith(
                  color: AppColors.warningLight,
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(color: AppColors.warningLight, fontSize: 16),
          ),
        ],
      );
    } else if (nomorAnggota == null || nomorAnggota!.isEmpty) {
      nomorAnggotaWidget = Text(
        'No. Anggota Tidak Tersedia',
        style: nomorAnggotaTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    } else {
      nomorAnggotaWidget = Text(nomorAnggota!, style: nomorAnggotaTextStyle);
    }
    // --- Akhir Logika Tampilan nomorAnggota ---

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Padding utama card
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ), // Padding simetris
        // Gunakan Row utama untuk layout Kiri (Teks) dan Kanan (QR)
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Tengahkan item secara vertikal
          children: [
            // Bagian Kiri: Kolom untuk teks username dan nomor anggota
            Expanded(
              // Ambil semua ruang tersisa di kiri
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Teks rata kiri
                mainAxisSize: MainAxisSize.min, // Column sekecil kontennya
                children: [
                  // Tampilkan Nama Pengguna
                  Text(
                    displayUsername,
                    style: usernameStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Batasi 1 baris jika terlalu panjang
                  ),
                  const SizedBox(
                    height: 10,
                  ), // Jarak antara username & no anggota
                  // Tampilkan Widget nomorAnggota
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      // Pastikan widget rata kiri
                      key: ValueKey<String>(
                        nomorAnggotaWidget.toString() +
                            (isLoading ? 'loading' : error ?? 'ok'),
                      ),
                      alignment: Alignment.centerLeft,
                      child: nomorAnggotaWidget,
                    ),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ],
              ),
            ),

            // Beri sedikit jarak horizontal antara teks dan ikon QR
            const SizedBox(width: 12),

            // Bagian Kanan: Tombol QR
            IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: Colors.white.withOpacity(0.9),
                size: 50, // Ukuran ikon yang sudah diperbesar
              ),
              onPressed: isLoading || error != null ? null : onGenerateQr,
              tooltip: 'Tampilkan QR Code No. Anggota',
              splashRadius: 24,
              // IconButton secara alami akan ditengahkan vertikal oleh Row
              // Tidak perlu constraints atau padding khusus di sini kecuali untuk visual
              // constraints: const BoxConstraints(),
              // padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildActionButton(IconData icon, String label) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}

// Widget: Categories
// Widget: Categories (MODIFIED childAspectRatio)
class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.calculate, "label": "Simulasi Pinjaman"},
      {"icon": Icons.assignment, "label": "Pengajuan Pinjaman"},
      {"icon": Icons.info, "label": "Info SHU"},
      {"icon": Icons.person, "label": "Info Profile"},
      {"icon": Icons.savings, "label": "Info Tabungan"},
      {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
    ]; // Data tidak diubah

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 4 : 3,
        // --- PERUBAHAN HANYA DI SINI ---
        // Mengurangi aspect ratio untuk memberi ruang tinggi lebih pada item,
        // mengatasi overflow saat teks label 2 baris.
        // Coba nilai lain (misal: 0.95, 0.9) jika 1.0 belum cukup.
        childAspectRatio: 1.0, // Diubah dari 1.2
        // --- AKHIR PERUBAHAN ---
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryItem(
          // Memanggil CategoryItem
          category: category,
          isDarkMode: isDarkMode,
          textTheme: textTheme,
          onTap: () {
            _navigateToPage(context, index);
          },
        );
      },
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    // Logika navigasi tidak diubah
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SimulasiPinjamanScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
        );
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShuPage()));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TabunganPage()),
        ); // Seharusnya ke Info Tabungan? -> TabunganPage()
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PencairanTabunganScreen()),
        ); // Seharusnya ke Pencairan?
        break;
    }
  }
}

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    Key? key,
    required this.category,
    required this.isDarkMode,
    required this.textTheme,
    required this.onTap,
  }) : super(key: key);

  final Map<String, dynamic> category;
  final bool isDarkMode;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.primaryDark.withOpacity(0.1)
                  : AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              child: Icon(
                category['icon'],
                color:
                    isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              // Added SizedBox to limit the width of the Text widget
              width: 80, // You can adjust this value as needed
              child: Text(
                category['label'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.primaryTextLight
                          : AppColors.primaryTextLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget: Recent Transactions
class BeritaListWidget extends StatelessWidget {
  final List<BeritaItem> beritaList;

  const BeritaListWidget({Key? key, required this.beritaList})
    : super(key: key);

  // Fungsi helper format tanggal (tetap sama)
  String _formatDisplayDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // --- BATASI JUMLAH BERITA MENJADI MAKSIMAL 5 ---
    final limitedBeritaList = beritaList.take(5).toList();
    // ----------------------------------------------

    // Handle jika list berita (setelah dibatasi) kosong
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

    // Tentukan lebar untuk setiap kartu berita dalam list horizontal
    const double cardWidth = 280.0; // Sesuaikan lebar kartu sesuai keinginan
    // Tentukan tinggi untuk area list horizontal
    // Perkiraan: (Lebar Kartu / Rasio Aspek Gambar) + Padding Teks + Tinggi Teks
    // Contoh: (280 / (16/9)) + 12 + 12 + (20 * 2) + 6 + (14*1)  ~= 158 + 24 + 40 + 6 + 14 ~= 242
    const double horizontalListHeight = 260.0; // Sesuaikan tinggi ini

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Berita Terbaru",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // --- AREA LIST HORIZONTAL ---
        SizedBox(
          height:
              horizontalListHeight, // Beri tinggi tetap untuk list horizontal
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Atur scroll ke horizontal
            itemCount:
                limitedBeritaList.length, // Gunakan list yang sudah dibatasi
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ), // Padding awal/akhir list
            itemBuilder: (context, index) {
              final berita = limitedBeritaList[index];
              // Buat widget untuk setiap item berita
              return Padding(
                // Beri jarak antar kartu di list horizontal
                padding: const EdgeInsets.only(
                  right: 12.0,
                ), // Jarak kanan antar item
                child: SizedBox(
                  // Beri lebar tetap untuk setiap item
                  width: cardWidth,
                  child: Card(
                    elevation: 3.0,
                    margin: EdgeInsets.zero, // Margin diatur oleh Padding luar
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        print("Berita tapped: ${berita.id} - ${berita.title}");
                        // TODO: Navigasi ke detail
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Gambar Thumbnail ---
                          // AspectRatio akan menyesuaikan tinggi gambar berdasarkan lebar kartu
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child:
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
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey[400],
                                            size: 40,
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      // Placeholder jika tidak ada gambar
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                    ),
                          ),

                          // --- Teks (Judul & Tanggal) ---
                          // Expanded diperlukan agar Padding mengisi sisa ruang vertikal
                          // dan teks tidak overflow jika tinggi kartu terbatas
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.start, // Mulai dari atas
                                children: [
                                  Text(
                                    berita.title,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDisplayDate(berita.validFrom),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
        ),
        // --- AKHIR AREA LIST HORIZONTAL ---
      ],
    );
  }
}
