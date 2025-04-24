import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/shu/screens/shu.dart';
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart';
import '../../../page_wrapper.dart';
import 'package:intl/intl.dart';

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

// Widget: Banner
// Widget: Banner (OVO Cash Style)
class BannerWidget extends StatelessWidget {
  // --- TAMBAHKAN PARAMETER CONSTRUCTOR ---
  final bool isLoading; // Status loading dari parent
  final String? error; // Pesan error dari parent (jika ada)
  final num? totalSaldo; // Nilai total saldo (nullable)
  final bool isBalanceVisible; // Status visibilitas dari parent
  final VoidCallback? onToggleVisibility; // Callback untuk tombol visibility
  // Anda mungkin juga ingin menambahkan data Points dari parent jika dinamis
  // final String? points;

  const BannerWidget({
    Key? key,
    this.isLoading = false, // Default tidak loading
    this.error,
    this.totalSaldo,
    this.isBalanceVisible = true, // Default terlihat
    this.onToggleVisibility,
    // this.points,
  }) : super(key: key);
  // --- AKHIR TAMBAHAN PARAMETER ---

  // Formatter Mata Uang
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textThemeLight; // Asumsi light theme

    // --- Logika Tampilan Saldo ---
    String displayBalance;
    Widget balanceWidget;

    if (isLoading) {
      displayBalance = 'Memuat...'; // Teks saat loading
      balanceWidget = Text(
        displayBalance,
        style: textTheme.headlineSmall?.copyWith(
          // Sesuaikan style loading
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (error != null) {
      displayBalance = 'Gagal Memuat'; // Teks saat error
      balanceWidget = Row(
        // Tampilkan ikon error
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.yellow[300], size: 20),
          SizedBox(width: 8),
          Text(
            displayBalance,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.yellow[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (!isBalanceVisible) {
      displayBalance = 'Rp ••••••••'; // Teks saat disembunyikan
      balanceWidget = Text(
        displayBalance,
        style: textTheme.headlineSmall?.copyWith(
          // Gunakan style yang sama dengan saldo asli
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5, // Beri spasi agar titik lebih jelas
        ),
      );
    } else {
      // Format saldo jika visible dan tidak loading/error
      displayBalance = _currencyFormatter.format(totalSaldo ?? 0);
      balanceWidget = Text(
        displayBalance,
        style: textTheme.headlineSmall?.copyWith(
          // Style utama saldo
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // --- Akhir Logika Tampilan Saldo ---

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primaryLight,
          ], // Gradient dari theme
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Tambahkan sedikit shadow (opsional)
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Bagian Atas (Total Saldo & Points) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              12,
            ), // Sesuaikan padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Tabungan Anda', // Ubah label jika perlu
                      style: textTheme.bodyLarge?.copyWith(
                        // Style dari theme
                        color: Colors.white.withOpacity(0.9),
                        // fontWeight: FontWeight.w500, // Sudah di theme?
                      ),
                    ),
                    // Tombol Show/Hide Saldo
                    InkWell(
                      // Buat ikon bisa ditekan
                      onTap: onToggleVisibility, // Panggil callback dari parent
                      child: Icon(
                        isBalanceVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined, // Ganti ikon
                        color: Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // Agar points align bawah
                  children: [
                    // Tampilkan Widget Saldo yang sudah diproses
                    AnimatedSwitcher(
                      // Animasi halus saat ganti teks saldo (opsional)
                      duration: Duration(milliseconds: 300),
                      child:
                          balanceWidget, // Gunakan widget saldo yang sudah dibuat
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),

                    // Points (Biarkan hardcoded atau terima dari parameter)
                    GestureDetector(
                      // Buat Points bisa di-tap (jika ada halaman detail points)
                      onTap: () {
                        // TODO: Navigasi ke halaman detail points jika ada
                        print("Points Tapped");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.2,
                          ), // Background lebih subtle
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_border_purple500_outlined,
                              color: AppColors.accent1Light,
                              size: 16,
                            ), // Ganti ikon?
                            const SizedBox(width: 6),
                            Text(
                              '1.473 Points', // Ganti dengan variabel jika dinamis (misal: points ?? '0 Points')
                              style: textTheme.labelMedium?.copyWith(
                                // Style dari theme
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Action Buttons (Kode Asli Anda - pastikan _buildActionButton ada) ---
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(8, 12, 8, 16), // Sesuaikan padding
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround, // spaceAround lebih baik?
          //     children: [
          //       // Pastikan Anda punya implementasi _buildActionButton
          //       // _buildActionButton(context, Icons.add, 'Top Up'),
          //       // _buildActionButton(context, Icons.swap_horiz, 'Transfer'),
          //       // _buildActionButton(context, Icons.arrow_downward, 'Tarik Tunai'),
          //       // _buildActionButton(context, Icons.history, 'History'),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
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
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
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
class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {
        "title": "Potongan Angsuran",
        "date": "10 September 2023",
        "amount": "Rp. 500.000",
      },
      {
        "title": "Potongan Angsuran",
        "date": "10 Agustus 2023",
        "amount": "Rp. 500.000",
      },
      {
        "title": "Potongan Angsuran",
        "date": "10 Juli 2023",
        "amount": "Rp. 500.000",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...transactions.map((transaction) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.arrow_upward, color: Colors.red),
              title: Text(
                transaction['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(transaction['date']),
              trailing: Text(
                transaction['amount'],
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// Widget: Bottom Navigation Bar
class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        // BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          label: "Transactions",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header dengan background berbeda (gray)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.alternateLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/profile.jpg',
                            ),
                            radius: 16,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Welcome, Alwi Ghozali',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Banner Widget
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BannerWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content area dengan background putih
          SliverToBoxAdapter(
            child: PageWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  CategoriesWidget(),
                  const SizedBox(height: 0),
                  RecentTransactionsWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
