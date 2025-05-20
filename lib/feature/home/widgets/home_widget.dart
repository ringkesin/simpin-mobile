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

class BannerWidget extends StatelessWidget {
  final bool isLoading;
  final String? username;
  final String? nomorAnggota;
  final String? usernameError;
  final String? nomorAnggotaError;
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
    final screenWidth = MediaQuery.of(context).size.width;

    String displayUsername;
    TextStyle usernameStyle =
        textTheme.bodyLarge?.copyWith(
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );

    if (isLoading) {
      displayUsername = 'Memuat Nama...';
      usernameStyle = usernameStyle.copyWith(
        color: Colors.white.withOpacity(0.7),
      );
    } else if (usernameError != null) {
      displayUsername = usernameError!;
      usernameStyle = usernameStyle.copyWith(
        color: AppColors.warningLight,
        fontWeight: FontWeight.bold,
      );
    } else {
      displayUsername =
          username?.isNotEmpty ?? false ? username! : 'Pengguna Terhormat';
    }

    Widget nomorAnggotaWidget;
    final nomorAnggotaBaseStyle =
        textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.3),
              offset: Offset(1, 1),
            ),
          ],
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        );

    if (isLoading) {
      nomorAnggotaWidget = Text(
        'Memuat No. Anggota...',
        style: nomorAnggotaBaseStyle.copyWith(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.normal,
          fontSize: 18,
        ),
      );
    } else if (nomorAnggotaError != null) {
      nomorAnggotaWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.warningLight.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nomorAnggotaError!,
              style:
                  textTheme.bodyMedium?.copyWith(
                    color: AppColors.warningLight.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: AppColors.warningLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      );
    } else if (nomorAnggota == null || nomorAnggota!.isEmpty) {
      nomorAnggotaWidget = Text(
        'No. Anggota Tidak Tersedia',
        style: nomorAnggotaBaseStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white.withOpacity(0.75),
        ),
      );
    } else {
      nomorAnggotaWidget = Text(nomorAnggota!, style: nomorAnggotaBaseStyle);
    }

    final String animatedSwitcherKey =
        isLoading
            ? 'loading_banner'
            : 'data_banner_${nomorAnggotaError ?? nomorAnggota ?? "empty"}';

    // --- PENYESUAIAN ASPECT RATIO ---
    // Nilai yang lebih besar akan membuat banner lebih "pendek" untuk lebar yang sama.
    // Anda mungkin perlu menyesuaikan ini berdasarkan aspek rasio aktual gambar Card.png Anda.
    // Jika Card.png Anda memiliki rasio ~1.58 (seperti kartu kredit),
    // menggunakan nilai yang lebih besar dari itu akan memotong bagian atas/bawah gambar
    // jika fit adalah BoxFit.cover, atau menambahkan letterbox jika fit adalah contain.
    // Mari kita coba nilai yang sedikit lebih besar dari 1.6 untuk mengurangi tinggi.
    const double imageAspectRatio =
        1.85; // Coba nilai ini, atau sesuaikan dengan rasio gambar Anda

    double iconSize = (screenWidth * 0.1).clamp(35.0, 50.0);

    return Card(
      elevation: 6.0,
      margin: EdgeInsets.zero,
      // --- PERUBAHAN WARNA BACKGROUND CARD ---
      color:
          AppColors
              .primaryDark, // Warna hijau tua sebagai fallback atau jika gambar transparan
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: imageAspectRatio,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage(
                'assets/images/Card.png',
              ), // Pastikan path ini benar
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(
                  0.10,
                ), // Sedikit dikurangi opacity overlay
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.055, // Sedikit disesuaikan
              vertical: screenWidth * 0.035, // Sedikit disesuaikan
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayUsername,
                        style: usernameStyle.copyWith(
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(1, 1),
                            ), // Shadow lebih jelas
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      // const SizedBox(height: 2), // Spasi disesuaikan
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        key: ValueKey<String>(animatedSwitcherKey),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: nomorAnggotaWidget,
                        ),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10), // Sedikit dikurangi
                if (onGenerateQr != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(
                        0.25,
                      ), // Sedikit lebih jelas
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white.withOpacity(0.98), // Lebih opaque
                        size: iconSize,
                        semanticLabel: 'Tampilkan QR Code',
                      ),
                      onPressed:
                          (isLoading ||
                                  nomorAnggotaError != null ||
                                  nomorAnggota == null ||
                                  nomorAnggota!.isEmpty)
                              ? null
                              : onGenerateQr,
                      tooltip: 'Tampilkan QR Code No. Anggota',
                      splashRadius:
                          iconSize *
                          0.6, // Splash radius relatif terhadap ukuran ikon
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
// Widget: BeritaListWidget (MODIFIED for responsiveness)
class BeritaListWidget extends StatelessWidget {
  final List<BeritaItem> beritaList;

  const BeritaListWidget({Key? key, required this.beritaList})
    : super(key: key);

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

    // --- Kalkulasi Responsif untuk Kartu Berita ---
    double responsiveCardWidth;
    if (screenWidth < 380) {
      // Layar sangat sempit
      responsiveCardWidth =
          screenWidth * 0.85; // Hampir penuh, mungkin 1 kartu terlihat jelas
    } else if (screenWidth < 600) {
      // Layar sempit (umumnya mobile portrait)
      responsiveCardWidth = screenWidth * 0.75; // Sekitar 1.3 kartu terlihat
    } else if (screenWidth < 900) {
      // Layar medium (tablet portrait / mobile landscape lebar)
      responsiveCardWidth = screenWidth * 0.45; // Sekitar 2 kartu terlihat
    } else {
      // Layar lebar
      responsiveCardWidth = screenWidth * 0.3; // Sekitar 3 kartu terlihat
    }
    // Batasan lebar kartu
    responsiveCardWidth = responsiveCardWidth.clamp(220.0, 320.0);

    // Perkiraan tinggi untuk teks dan padding di dalam kartu
    const double textPaddingAndHeight =
        12.0 + (20.0 * 2) + 6.0 + 14.0 + 12.0; // Total sekitar 84

    // Hitung tinggi gambar berdasarkan rasio aspek 16/9
    final double imageHeight = responsiveCardWidth / (16 / 9);
    // Tinggi total untuk list horizontal
    final double responsiveHorizontalListHeight =
        imageHeight + textPaddingAndHeight + 8; // +8 untuk sedikit margin kartu

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
        SizedBox(
          height: responsiveHorizontalListHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: limitedBeritaList.length,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, index) {
              final berita = limitedBeritaList[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: responsiveCardWidth, // Menggunakan lebar responsif
                  child: Card(
                    elevation: 2.0, // Sedikit dikurangi
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                    ), // Margin vertikal kecil untuk bayangan
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        print("Berita tapped: ${berita.id} - ${berita.title}");
                        // TODO: Navigasi ke detail berita
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                    ),
                          ),
                          Expanded(
                            // Penting agar teks tidak overflow jika kartu lebih tinggi dari konten teks
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .start, // Atau MainAxisAlignment.spaceBetween jika ingin tanggal di bawah
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
      ],
    );
  }
}
