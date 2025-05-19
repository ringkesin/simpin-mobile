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
  final bool isLoading; // Keseluruhan loading state untuk banner
  final String? username;
  final String? nomorAnggota;
  final String? usernameError; // Error spesifik untuk username
  final String? nomorAnggotaError; // Error spesifik untuk nomor anggota
  final VoidCallback? onGenerateQr;

  const BannerWidget({
    Key? key,
    this.isLoading = false,
    this.username,
    this.nomorAnggota,
    this.usernameError,
    this.nomorAnggotaError,
    this.onGenerateQr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    // final ColorScheme colorScheme = theme.colorScheme; // Jika diperlukan

    // --- Logika Tampilan Username ---
    String displayUsername;
    TextStyle usernameStyle =
        textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)) ??
        const TextStyle(color: Colors.white70, fontSize: 16);

    if (isLoading) {
      // Jika banner secara keseluruhan sedang loading
      displayUsername = 'Memuat Nama...';
      usernameStyle = usernameStyle.copyWith(
        color: Colors.white.withOpacity(0.7),
      );
    } else if (usernameError != null) {
      // Jika ada error spesifik untuk username
      displayUsername = usernameError!; // Tampilkan pesan error username
      usernameStyle = usernameStyle.copyWith(color: AppColors.warningLight);
    } else {
      // Jika tidak loading dan tidak ada error username
      displayUsername = username?.isNotEmpty ?? false ? username! : 'Pengguna';
    }

    // --- Logika Tampilan nomorAnggota ---
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
      // Jika banner secara keseluruhan sedang loading
      nomorAnggotaWidget = Text(
        'Memuat No. Anggota...',
        style: nomorAnggotaTextStyle.copyWith(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      );
    } else if (nomorAnggotaError != null) {
      // Jika ada error spesifik untuk nomor anggota
      nomorAnggotaWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.warningLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            // Agar teks error tidak overflow
            child: Text(
              nomorAnggotaError!, // Tampilkan pesan error nomor anggota
              style:
                  textTheme.bodyLarge?.copyWith(
                    color: AppColors.warningLight,
                    fontWeight: FontWeight.w500,
                  ) ??
                  TextStyle(color: AppColors.warningLight, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      );
    } else if (nomorAnggota == null || nomorAnggota!.isEmpty) {
      // Jika tidak ada error, tapi data kosong
      nomorAnggotaWidget = Text(
        'No. Anggota Tidak Tersedia',
        style: nomorAnggotaTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: Colors.white.withOpacity(0.7),
        ),
      );
    } else {
      // Jika tidak loading, tidak ada error, dan data ada
      nomorAnggotaWidget = Text(nomorAnggota!, style: nomorAnggotaTextStyle);
    }

    // Kunci untuk AnimatedSwitcher, agar transisi terjadi saat state relevan berubah
    final String animatedSwitcherKey =
        isLoading
            ? 'loading'
            : '${nomorAnggotaError ?? nomorAnggota ?? "empty"}';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayUsername,
                    style: usernameStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    key: ValueKey<String>(
                      animatedSwitcherKey,
                    ), // Kunci yang diperbarui
                    child: Align(
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
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: Colors.white.withOpacity(0.9),
                size: 50,
              ),
              // Tombol QR dinonaktifkan jika sedang loading, ada error nomor anggota, atau nomor anggota tidak ada
              onPressed:
                  (isLoading ||
                          nomorAnggotaError != null ||
                          nomorAnggota == null ||
                          nomorAnggota!.isEmpty)
                      ? null
                      : onGenerateQr,
              tooltip: 'Tampilkan QR Code No. Anggota',
              splashRadius: 24,
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
      {"icon": Icons.calculate_outlined, "label": "Simulasi Pinjaman"},
      {"icon": Icons.description_outlined, "label": "Pengajuan Pinjaman"},
      {"icon": Icons.info_outline, "label": "Info SHU"},
      {"icon": Icons.person_outline, "label": "Info Profil"},
      {"icon": Icons.savings_outlined, "label": "Info Tabungan"},
      {"icon": Icons.paid_outlined, "label": "Pencairan Tabungan"},
    ];

    // Determine crossAxisCount based on screen width
    int crossAxisCount = screenWidth > 700 ? 4 : 3;
    if (screenWidth < 380 && categories.length > 4) {
      crossAxisCount = 3;
    }

    // Adjust childAspectRatio to give more height to items
    // Smaller value means taller items relative to their width.
    // Let's try even smaller values if 0.9/0.85 was not enough.
    double childAspectRatio = 0.8; // Dikurangi dari 0.9
    if (screenWidth < 420) {
      // Penyesuaian breakpoint untuk layar yang lebih sempit
      childAspectRatio =
          0.75; // Dikurangi dari 0.85, memberi lebih banyak tinggi
    }
    if (screenWidth < 360) {
      // Untuk layar yang sangat sempit
      childAspectRatio = 0.7;
    }

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio:
            childAspectRatio, // Menggunakan nilai yang lebih kecil
        crossAxisSpacing: 12,
        mainAxisSpacing:
            16, // Sedikit ditambah dari 12 untuk ruang vertikal antar baris
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryItem(
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
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SimulasiPinjamanScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormWizardScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShuPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShuPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TabunganPage()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PencairanTabunganScreen()),
        );
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
        // Padding vertikal bisa sedikit dikurangi jika childAspectRatio sangat kecil
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.primaryDark.withOpacity(0.15)
                  : AppColors.primaryLight.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.black12,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24, // Sedikit dikurangi jika ruang sangat terbatas
              backgroundColor:
                  isDarkMode
                      ? AppColors.primaryLight.withOpacity(0.1)
                      : AppColors.primaryDark.withOpacity(0.05),
              child: Icon(
                category['icon'],
                color:
                    isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
                size: 26, // Ukuran ikon sedikit disesuaikan
              ),
            ),
            const SizedBox(
              height: 8,
            ), // Spasi antara ikon dan teks sedikit dikurangi
            Text(
              category['label'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
                fontWeight: FontWeight.w500,
                height:
                    1.2, // Menambah sedikit line-height jika teks 2 baris terlalu rapat
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
